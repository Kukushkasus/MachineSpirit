#!/usr/bin/env python3
"""MachineSpirit transactional user-file installer."""
# [ PURITY SEAL ] No original shall be lost in the forge.
import argparse, fcntl, hashlib, json, os, re, shutil, subprocess, sys, tempfile, time
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
HOME = Path.home()
CONF = Path(os.environ.get('XDG_CONFIG_HOME', HOME / '.config'))
DATA = Path(os.environ.get('XDG_DATA_HOME', HOME / '.local/share'))
STATE = Path(os.environ.get('XDG_STATE_HOME', HOME / '.local/state')) / 'machinespirit/install'
BIN = HOME / '.local/bin'
USER = os.environ.get('USER') or Path.home().name
HELPER = Path('/usr/local/libexec/ms-browser-policy')
COMPONENTS = ['shell', 'hyprland', 'terminal', 'apps', 'lock', 'wallpapers', 'login', 'boot']
MANIFEST = json.loads((Path(__file__).parent / 'components.json').read_text())
PACKAGES = {name:' '.join(item['packages']) for name,item in MANIFEST.items()}

def atomic(path, data, mode=0o600):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as f:
            f.write(data); f.flush(); os.fsync(f.fileno())
        os.chmod(tmp, mode); os.replace(tmp, path)
    finally:
        if os.path.exists(tmp): os.unlink(tmp)

def fingerprint(p):
    if p.is_symlink(): return 'link:' + os.readlink(p)
    if p.is_file(): return hashlib.sha256(p.read_bytes()).hexdigest()
    if p.exists(): raise ValueError(f'Expected a file, found directory: {p}')
    return None

def copy_file(src, dst):
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.is_symlink(): dst.unlink()
    if src.is_symlink():
        if dst.exists(): dst.unlink()
        dst.symlink_to(os.readlink(src)); return
    fd, tmp = tempfile.mkstemp(dir=dst.parent); os.close(fd)
    try:
        shutil.copy2(src, tmp); os.replace(tmp, dst)
    finally:
        if os.path.exists(tmp): os.unlink(tmp)

OWNER = {}   # destination path -> component that installs it (filled by mappings())

def mappings(selected):
    pairs = []
    def add(component, src, dst):
        pairs.append((src, dst)); OWNER[str(dst)] = component
    def tree(component, src, dst, only=None):
        for p in sorted((ROOT / src).rglob('*')):
            if p.is_file() and '__pycache__' not in p.parts and p.suffix != '.pyc' and (only is None or p.suffix in only): add(component, p, dst / p.relative_to(ROOT / src))
    if 'shell' in selected:
        tree('shell', 'quickshell', CONF / 'quickshell/machinespirit')
        tree('shell', 'assets/fonts', DATA / 'fonts/machinespirit')
        tree('shell', 'matugen', DATA / 'machinespirit/matugen')
        for n in ('managed.py', 'make_emblem.py', 'make_cursors.py'): add('shell', ROOT / 'tools' / n, DATA / 'machinespirit/tools' / n)   # the only tools ms-theme and ms-cursor use; the rest are for developers
        tree('shell', 'privacy', DATA / 'machinespirit/privacy')
        tree('shell', 'bin', BIN)
        for n in ('ms-theme', 'ms-walls'): add('shell', ROOT / 'scripts' / n, BIN / n)
        add('shell', ROOT / 'config/settings.json', CONF / 'machinespirit/settings.json')
        add('shell', ROOT / 'VERSION', DATA / 'machinespirit/VERSION')
    if 'hyprland' in selected: tree('hyprland', 'hypr', CONF / 'hypr')
    if 'terminal' in selected:
        tree('terminal', 'kitty', CONF / 'kitty'); tree('terminal', 'fastfetch', CONF / 'fastfetch')
        add('terminal', ROOT / 'fish/machinespirit.fish', CONF / 'fish/conf.d/machinespirit.fish')
        add('terminal', ROOT / 'fish/machinespirit.fish', CONF / 'fish/machinespirit.fish')
    if 'lock' in selected:
        tree('lock', 'hyprlock', CONF / 'hypr'); tree('lock', 'hypridle', CONF / 'hypr')
    # PNG only: the SVG sources beside them would show up in the wallpaper archive as duplicates of the same three images.
    if 'wallpapers' in selected: tree('wallpapers', 'assets/wallpapers', DATA / 'machinespirit/wallpapers', only=('.png',))
    tree('shell', 'installer', DATA / 'machinespirit/installer')
    return pairs

def clean_bytecode():
    # Python writes these next to the installed helpers at runtime; uninstall should not leave them behind.
    for folder, pattern in ((BIN / '__pycache__', 'ms_privacy*.pyc'), (DATA / 'machinespirit/tools/__pycache__', 'managed*.pyc')):
        for f in folder.glob(pattern): f.unlink(missing_ok=True)
        try: folder.rmdir()
        except OSError: pass

def mark(tx, status):
    # A restored transaction must stop counting as installed, or a later install would
    # treat the files it removed as user deletions and skip them.
    record = tx / 'manifest.json'
    data = json.loads(record.read_text())
    if data.get('status') == 'complete': data['status'] = status
    elif data.get('status') == 'applying': data['status'] = 'rolled-back'   # restoring an unfinished record closes it
    else: return
    atomic(record, json.dumps(data, indent=2))

def proc_start(pid):
    """Start time of a process in clock ticks since boot, or None when it does not exist."""
    try: return int(Path(f'/proc/{pid}/stat').read_text().rsplit(')', 1)[1].split()[19])
    except (OSError, ValueError, IndexError): return None

def owner_state(tx, manifest):
    """'dead' only when the process that wrote an unfinished record is provably gone; otherwise 'alive' or 'unknown'.
    An active installation must never be rolled back from under itself."""
    pid = manifest.get('pid')
    if pid is None:
        m = re.search(r'-(\d+)$', tx.name)   # records written before pids were stored end with the pid
        pid = int(m[1]) if m else None
    if pid is None: return 'unknown'
    now = proc_start(pid)
    if now is None: return 'dead'
    if manifest.get('started') is not None: return 'alive' if now == manifest['started'] else 'dead'   # same pid, different process: reused
    try: cmd = Path(f'/proc/{pid}/cmdline').read_bytes()
    except OSError: return 'unknown'
    return 'alive' if (b'install.py' in cmd or b'ms-theme' in cmd) else 'unknown'

def theme_busy():
    """True while ms-theme holds its lock (a theme change is being recorded right now)."""
    lock_path = STATE.parent / 'theme.lock'
    if not lock_path.exists(): return False
    with lock_path.open('w') as f:
        try: fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError: return True
        return False

def recover_interrupted(current=None):
    """Roll back records still marked `applying` whose writer is provably gone (crash, power loss, kill -9).
    Called while holding the installation lock, so no other installation can be in progress."""
    for record_path in sorted(STATE.glob('*/manifest.json')):
        tx = record_path.parent
        if current is not None and tx.name == current.name: continue
        try: manifest = json.loads(record_path.read_text())
        except ValueError: continue
        if manifest.get('status') != 'applying': continue
        owner = owner_state(tx, manifest)
        if owner != 'dead' or ('-theme-' in tx.name and theme_busy()):
            print(f'Left unfinished record {tx.name} alone (writer: {owner}). If it is stale, run: ./install.sh restore {tx.name}'); continue
        print(f'Recovering {tx.name}: the installation that wrote it was interrupted.')
        if restore(tx, guarded=False): continue   # could not put everything back: keep it `applying` so the report stays honest
        mark(tx, 'rolled-back')

def restore(tx, guarded=True):
    """Put every recorded file back. One failure must not stop the rest; returns the files that could not be restored."""
    manifest = json.loads((tx / 'manifest.json').read_text())
    failed = []
    for e in reversed(manifest['files']):
        dst = Path(e['dest'])
        try:
            current = fingerprint(dst)
            if guarded and current != e.get('installed'):
                print(f'Preserved changed file: {dst}'); continue
            original = tx / e['backup'] if e.get('backup') else None
            if original: copy_file(original, dst)
            elif dst.exists() or dst.is_symlink(): dst.unlink()
        except OSError as error:
            failed.append(dst); print(f'Could not restore {dst}: {error.strerror or error}', file=sys.stderr)
    if failed: print(f'{len(failed)} file(s) from {tx.name} were not restored. Fix the cause (for example free disk space) and run: ./install.sh restore {tx.name}', file=sys.stderr)
    else: print(f'Restored {tx.name}')
    return failed

def referenced(name, root, skip):
    """True when a file name still appears in the sources of the release being installed (a QML type, a script, an asset)."""
    stem = name.rsplit('.', 1)[0] if name.endswith(('.qml', '.js')) else name
    needles = {name, stem} if len(stem) > 2 else {name}
    for p in root.rglob('*'):
        if not p.is_file() or p == skip or any(x in p.parts for x in ('.git', '.dist', '__pycache__', 'docs')) or p.suffix == '.md' or p.name.startswith('test_'): continue   # docs and tests are not runtime users of a file
        try:
            if p.stat().st_size > 2 * 1024**2: continue
            text = p.read_text(errors='ignore')
        except OSError: continue
        if any(n in text for n in needles): return True
    return False

def remove_stale(tx, manifest, pairs, selected, save):
    """Remove files an older MachineSpirit installed that this version no longer ships.
    Only with proof: recorded by a complete transaction with its component, that component is being installed now,
    not in the new file list, unchanged since install, not a link, and not referenced by the new sources.
    In any doubt the file stays and a warning says why."""
    new = {str(dst) for _, dst in pairs}; owned = {}
    for record_path in sorted(STATE.glob('*/manifest.json')):
        try: record = json.loads(record_path.read_text())
        except ValueError: continue
        if record.get('status') != 'complete' or record_path.parent.name == tx.name: continue
        for e in record.get('files', []):
            if e.get('component'): owned[e['dest']] = (e['component'], e.get('installed'))
    for dest, (component, installed) in sorted(owned.items()):
        if dest in new or component not in selected: continue
        dst = Path(dest)
        if installed is None or not dst.exists() and not dst.is_symlink(): continue   # already gone, or an earlier removal record
        if dst.is_symlink() or fingerprint(dst) != installed:
            print('Kept stale file you modified:', dst); continue
        if referenced(dst.name, ROOT, None):
            print('Kept stale file that is still referenced:', dst); continue
        entry = {'dest': dest, 'backup': 'backup/' + str(len(manifest['files'])), 'installed': None, 'component': component}
        copy_file(dst, tx / entry['backup']); manifest['files'].append(entry); save(); dst.unlink()
        print('Removed file no longer part of MachineSpirit:', dst)
        for parent in dst.parents:   # tidy folders this left empty, never above the component's own tree
            if parent in (CONF / 'quickshell/machinespirit', DATA / 'machinespirit', DATA / 'fonts/machinespirit', CONF / 'kitty', CONF / 'fastfetch', CONF / 'hypr', BIN, CONF) or HOME == parent: break
            try: parent.rmdir()
            except OSError: break

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('operation', nargs='?', default='install', choices=['install','update','doctor','uninstall','restore'])
    p.add_argument('backup', nargs='?')
    p.add_argument('--full', action='store_true'); p.add_argument('--components')
    p.add_argument('--dry-run', action='store_true'); p.add_argument('--no-packages', action='store_true')
    p.add_argument('--no-system',action='store_true',help='Skip privileged privacy helper installation/removal (for isolated tests)')
    p.add_argument('--yes', action='store_true'); p.add_argument('--with-aur', action='store_true')
    p.add_argument('--with-boot', action='store_true', help='Allow --full to change GRUB/Plymouth (otherwise asked, or skipped with --yes)')
    p.add_argument('--with-autologin', action='store_true', help='With the login component: sign in without a password (off by default)')
    a = p.parse_args()
    if any(not path.is_absolute() for path in [HOME,CONF,DATA,STATE]): p.error('HOME and XDG paths must be absolute')
    if os.geteuid() == 0: p.error('Run as your normal desktop user, not root.')
    if a.operation != 'doctor' and not a.dry_run:
        helper = BIN / 'ms-session'
        # Changing the shell's files while the screen is locked could leave the lock without its screen: stop before anything changes.
        if helper.exists() and subprocess.run([str(helper), 'locked'], capture_output=True).returncode == 0:
            raise ValueError('The screen is locked. Unlock it first: changing or restarting the shell now could leave the lock without its screen. Nothing was changed.')
    if a.operation == 'doctor':
        failures = []
        selected_file=STATE/'components.json'
        selected=json.loads(selected_file.read_text()) if selected_file.exists() else ['shell']
        commands={'shell':['quickshell','python3','matugen','grim','slurp','wpctl','playerctl'], 'hyprland':['Hyprland'], 'terminal':['kitty','fish','fastfetch'], 'apps':['dolphin','firefox','btop'], 'lock':['hyprlock','hypridle'], 'boot':['plymouth'], 'login':[], 'wallpapers':[]}
        for tool in sorted({tool for c in selected for tool in commands[c]}):
            found = shutil.which(tool); print(f'{tool}: {found or "MISSING"}')
            if not found: failures.append(tool)
        optional={'shell':{'gost':'private proxy','ddcutil':'monitor brightness','brightnessctl':'laptop brightness','cava':'audio spectrum'}}
        for tool, purpose in sorted({i for c in selected for i in optional.get(c,{}).items()}):
            if not shutil.which(tool): print(f'{tool}: not installed (optional, needed for {purpose}). Install the package of the same name.')
        if 'login' in selected:
            r = subprocess.run([sys.executable, str(ROOT / 'installer/login.py'), 'check', '--user', USER], capture_output=True, text=True)
            print((r.stdout.strip() or r.stderr.strip() or 'Login: no report'))
            if r.returncode: failures.append('login')
        for tool in ('quickshell','Hyprland'):
            if shutil.which(tool):
                try: out = subprocess.run([tool,'--version'],capture_output=True,text=True,timeout=5).stdout.strip()
                except (OSError,subprocess.SubprocessError): out = ''
                print(f'{tool} version:', out.splitlines()[0] if out else f'{tool} is installed, but its version could not be determined.')
        for record in sorted(STATE.glob('*/manifest.json')):
            try: status = json.loads(record.read_text()).get('status')
            except ValueError: status = 'unreadable'
            if status == 'applying':
                owner = owner_state(record.parent, json.loads(record.read_text()))
                if owner == 'alive': print(f'Install record {record.parent.name} belongs to an installation that is still running.')
                else:
                    print(f'Install record {record.parent.name} is unfinished (writer: {owner}). Run ./install.sh install again to recover it, or ./install.sh restore {record.parent.name}.'); failures.append(record.parent.name)
            elif status == 'unreadable':
                print(f'Install record {record.parent.name} cannot be read. Keep it for manual recovery; it blocks nothing.'); failures.append(record.parent.name)
        settings_file = CONF / 'machinespirit/settings.json'
        if settings_file.exists():
            try: json.loads(settings_file.read_text())
            except ValueError:
                print(f'{settings_file} is not valid JSON. Move it aside to restore the defaults.'); failures.append('settings.json')
        print('Configuration:', CONF, '\nInstall records:', STATE)
        return bool(failures)
    if a.operation in ('restore','uninstall'):
        if a.dry_run:
            print('Would restore', a.backup or 'all recorded transactions', 'preserving changed files'); return 0
        STATE.mkdir(parents=True, exist_ok=True)
        with (STATE / 'lock').open('w') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            if a.operation == 'restore':
                if not a.backup or Path(a.backup).name != a.backup: p.error('Supply a backup ID from the install records.')
                if restore(STATE / a.backup): return 1
                mark(STATE / a.backup, 'restored')
            else:
                incomplete = False
                # the generated cursor themes are not install records: put the original pointer back and remove them
                if (BIN / 'ms-cursor').is_file(): subprocess.run([sys.executable, str(BIN / 'ms-cursor'), 'uninstall'])
                if HELPER.exists() and not a.no_system: subprocess.run(['sudo',str(HELPER),'uninstall'],check=True)
                if not a.no_system and Path('/var/lib/machinespirit/login').is_dir(): subprocess.run(['sudo',sys.executable,str(ROOT/'installer/login.py'),'uninstall'],check=True)
                for tx in sorted(STATE.glob('*/manifest.json'), reverse=True):
                    if json.loads(tx.read_text()).get('status') != 'complete': continue
                    if restore(tx.parent): incomplete = True
                    else: mark(tx.parent, 'uninstalled')
                if incomplete: return 1
                clean_bytecode()
        return 0
    previous = STATE / 'components.json'
    previous_text = previous.read_text() if previous.exists() else None
    if a.full and a.components: p.error('Choose --full or --components, not both')
    selected = COMPONENTS[:] if a.full else (a.components.split(',') if a.components else None)
    if selected is None and previous.exists(): selected = json.loads(previous.read_text())
    if a.operation == 'update' and selected and 'boot' in selected and not a.components:
        selected = [c for c in selected if c != 'boot']; print('The boot theme is not touched by an update. Refresh it with --components boot.')
    answer_full = False
    if selected is None:
        if a.yes or not sys.stdin.isatty(): p.error('Choose --full or --components shell,hyprland,...')
        answer = input('Components: ' + ', '.join(COMPONENTS) + '\nEnter full or a comma-separated selection [shell,hyprland,lock,wallpapers]: ').strip()
        answer_full = answer == 'full'
        selected = COMPONENTS[:] if answer == 'full' else (answer or 'shell,hyprland,lock,wallpapers').split(',')
    selected = [c.strip() for c in selected]
    if (a.full or answer_full) and 'boot' in selected and not a.with_boot:
        if a.yes or a.dry_run or not sys.stdin.isatty() or input('Full install includes the boot theme: it edits GRUB, mkinitcpio and Plymouth and rebuilds initramfs. Include it? [y/N] ').lower() != 'y':
            selected.remove('boot'); print('Boot theme skipped. Add it later with --components boot, or pass --with-boot.')
    if not selected or any(c not in COMPONENTS for c in selected): p.error('Unknown component')
    if a.no_system and 'login' in selected:
        if not (a.full or answer_full): p.error('--no-system cannot install the login component')
        selected.remove('login'); print('Login component skipped (--no-system).')
    if 'login' in selected and (a.full or answer_full) and not (a.with_autologin or a.yes or a.dry_run) and sys.stdin.isatty():
        a.with_autologin = input('Sign in automatically, without a password? Anyone who can switch this computer on gets your session. [y/N] ').lower() == 'y'
    selected = sorted(set(selected) | {'shell'})
    if a.no_system and 'boot' in selected: p.error('--no-system cannot install boot components')
    pairs = mappings(selected)
    packages = sorted(set(' '.join(PACKAGES[c] for c in selected).split()))
    print('Components:', ', '.join(selected)); print('Packages:', ' '.join(packages))
    for _, dst in pairs: print('File:', dst)
    # don't silently follow a redirected parent
    for _, dst in pairs:
        for parent in dst.parents:
            if parent == HOME.parent: break
            if parent.is_symlink(): raise ValueError(f'Symlink parent requires manual installation: {parent}')
        fingerprint(dst)
    if 'shell' in selected and not a.no_system: print('System privacy helper: /usr/local/libexec/ms-browser-policy (Polkit authorization)')
    if 'boot' in selected:
        subprocess.run([sys.executable, str(ROOT / 'installer/boot.py'), 'check'], check=True)
    if 'login' in selected:
        subprocess.run([sys.executable, str(ROOT / 'installer/login.py'), 'check', '--user', USER, *(['--autologin'] if a.with_autologin else []), *([] if a.no_packages else ['--packages-pending'])], check=True)
    if shutil.which('Hyprland'):
        version = subprocess.run(['Hyprland','--version'],capture_output=True,text=True).stdout
        import re
        match = re.search(r'(?:v)?(0)\.(\d+)\.(\d+)',version)
        if match and int(match[2]) < 55: raise ValueError('Hyprland 0.55+ Lua API is required; tested with 0.57.0')
    if a.dry_run: return 0
    if not a.yes and input('Install these components with backups? [y/N] ').lower() != 'y': return 0
    if shutil.disk_usage(HOME).free < 200 * 1024**2: raise ValueError('Less than 200 MiB free')
    if not a.no_packages:
        if not shutil.which('pacman'): raise ValueError('Package installation supports Arch/CachyOS only')
        subprocess.run(['sudo','pacman','-S','--needed', *(['--noconfirm'] if a.yes else []), *packages], check=True)
        if a.with_aur:
            helper = shutil.which('paru') or shutil.which('yay')
            if not helper: raise ValueError('--with-aur needs an existing paru or yay')
            subprocess.run([helper,'-S','--needed','darkly-bin'], check=True)
    STATE.mkdir(parents=True, exist_ok=True)
    with (STATE / 'lock').open('w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        recover_interrupted()
        tx = STATE / (time.strftime('%Y%m%d-%H%M%S') + '-' + str(os.getpid())); tx.mkdir()
        changed = True
        manifest = {'version':1, 'components':selected, 'files':[], 'status':'applying', 'pid':os.getpid(), 'started':proc_start(os.getpid())}
        def save(): atomic(tx / 'manifest.json', json.dumps(manifest, indent=2))
        save()
        known = {}
        for previous_manifest in sorted(STATE.glob('*/manifest.json')):
            record = json.loads(previous_manifest.read_text())
            if record.get('status') == 'complete':
                for e in record['files']: known[e['dest']] = e.get('installed')
        try:
            for src, dst in pairs:
                if dst == CONF / 'machinespirit/settings.json' and dst.exists(): continue
                old = fingerprint(dst)
                if old == fingerprint(src): continue
                if str(dst) in known and old != known[str(dst)]:
                    print('Preserved user modification:', dst); continue
                entry = {'dest':str(dst), 'backup':None, 'installed':fingerprint(src), 'component':OWNER.get(str(dst))}
                if old is not None:
                    entry['backup'] = 'backup/' + str(len(manifest['files']))
                    copy_file(dst, tx / entry['backup'])
                manifest['files'].append(entry); save(); copy_file(src, dst)
            remove_stale(tx, manifest, pairs, selected, save)
            # The boot theme stays recorded as installed even when this run did not touch it (as `ms-update` never does).
            try: had_boot = 'boot' in json.loads(previous_text or '[]')
            except ValueError: had_boot = False
            atomic(previous, json.dumps(sorted(set(selected) | ({'boot'} if had_boot else set()))))
            if manifest['files']: manifest['status'] = 'complete'; save()
            else: shutil.rmtree(tx); changed = False   # nothing was written: leave no empty record behind
        except BaseException:
            restore(tx, guarded=False); manifest['status']='rolled-back'; save(); raise
    helper_added = False
    try:
        sys.path.insert(0, str(ROOT / 'tools'))
        from managed import transaction
        with transaction([CONF / 'machinespirit/generated.lua', CONF / 'machinespirit/hypridle.conf'], STATE.parent):
            subprocess.run([str(BIN / 'ms-settings'), 'generate'], check=True)
        if 'wallpapers' in selected and not (STATE.parent / 'theme.json').exists():
            # the default theme's own wallpaper when the shell brought it, the classic forge otherwise
            temple = CONF / 'quickshell/machinespirit/themes/mechanicus/wallpapers/temple.jpg'
            subprocess.run([str(BIN / 'ms-theme'), 'apply', str(temple if temple.is_file() else DATA / 'machinespirit/wallpapers/forge.png')], check=True)
        if 'shell' in selected and (BIN / 'ms-cursor').is_file() and subprocess.run([sys.executable, str(BIN / 'ms-cursor'), 'apply']).returncode:
            print('Warning: the cursor themes could not be set up; see `ms-cursor status`.', file=sys.stderr)   # cosmetic, never a reason to undo an install
        if shutil.which('fc-cache') and subprocess.run(['fc-cache', '-f', str(DATA / 'fonts/machinespirit')]).returncode:
            print('Warning: fc-cache failed; the new fonts may appear after the next login.', file=sys.stderr)   # cosmetic, never a reason to undo an install
        if 'shell' in selected and not a.no_system:
            helper_added = not HELPER.exists()
            subprocess.run(['sudo',sys.executable,str(ROOT/'privacy/install.py')],check=True)
        if 'boot' in selected: subprocess.run(['sudo', sys.executable, str(ROOT / 'installer/boot.py'), 'install'], check=True)
        # After boot, whose own check refuses a system that already has a display manager.
        if 'login' in selected: subprocess.run(['sudo', sys.executable, str(ROOT / 'installer/login.py'), 'install', '--user', USER, *(['--autologin'] if a.with_autologin else [])], check=True)
    except BaseException:
        # A helper installed by this run must not outlive the user files that were rolled back.
        if helper_added and HELPER.exists():
            if subprocess.run(['sudo', str(HELPER), 'uninstall']).returncode: print('Could not remove', HELPER, '- run: sudo', HELPER, 'uninstall', file=sys.stderr)
        for record_path in sorted(STATE.glob('*/manifest.json'), reverse=True):
            if record_path.parent.name < tx.name: continue
            record = json.loads(record_path.read_text())
            if record.get('status') == 'complete':
                restore(record_path.parent, guarded=False)
                record['status'] = 'rolled-back'
                atomic(record_path, json.dumps(record, indent=2))
        if previous_text is None: previous.unlink(missing_ok=True)
        else: atomic(previous, previous_text)
        raise
    if not changed: print('Already up to date: no files needed changing.')
    else:
        running = bool(os.environ.get('HYPRLAND_INSTANCE_SIGNATURE'))
        after = ('The running session was left alone: apply the new shell with ms-session restart, or reboot and sign in with the Hyprland session.' if running
                 else 'Reboot, then sign in with the Hyprland session.') if 'login' in selected else 'Select the MachineSpirit Hyprland configuration on your next login.'
        print('Installed. Backup ID:', tx.name, '\n' + after)
    return 0
if __name__ == '__main__':
    try: sys.exit(main())
    except (OSError, ValueError, subprocess.CalledProcessError) as e: print('Installation failed:', e, file=sys.stderr); sys.exit(1)
