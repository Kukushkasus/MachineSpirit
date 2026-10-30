#!/usr/bin/env python3
"""MachineSpirit transactional user-file installer."""
# [ PURITY SEAL ] No original shall be lost in the forge.
import argparse, fcntl, hashlib, json, os, shutil, subprocess, sys, tempfile, time
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
HOME = Path.home()
CONF = Path(os.environ.get('XDG_CONFIG_HOME', HOME / '.config'))
DATA = Path(os.environ.get('XDG_DATA_HOME', HOME / '.local/share'))
STATE = Path(os.environ.get('XDG_STATE_HOME', HOME / '.local/state')) / 'machinespirit/install'
BIN = HOME / '.local/bin'
COMPONENTS = ['shell', 'hyprland', 'terminal', 'apps', 'lock', 'wallpapers', 'boot']
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

def mappings(selected):
    pairs = []
    def tree(src, dst):
        for p in sorted((ROOT / src).rglob('*')):
            if p.is_file() and '__pycache__' not in p.parts and p.suffix != '.pyc': pairs.append((p, dst / p.relative_to(ROOT / src)))
    if 'shell' in selected:
        tree('quickshell', CONF / 'quickshell/machinespirit')
        tree('assets/fonts', DATA / 'fonts/machinespirit')
        tree('matugen', DATA / 'machinespirit/matugen')
        tree('tools', DATA / 'machinespirit/tools')
        tree('bin', BIN)
        for n in ('ms-theme', 'ms-walls'): pairs.append((ROOT / 'scripts' / n, BIN / n))
        pairs.append((ROOT / 'config/settings.json', CONF / 'machinespirit/settings.json'))
    if 'hyprland' in selected: tree('hypr', CONF / 'hypr')
    if 'terminal' in selected:
        tree('kitty', CONF / 'kitty'); tree('fastfetch', CONF / 'fastfetch')
        pairs.append((ROOT / 'fish/machinespirit.fish', CONF / 'fish/conf.d/machinespirit.fish'))
        pairs.append((ROOT / 'fish/machinespirit.fish', CONF / 'fish/machinespirit.fish'))
    if 'lock' in selected:
        tree('hyprlock', CONF / 'hypr'); tree('hypridle', CONF / 'hypr')
    if 'wallpapers' in selected: tree('assets/wallpapers', DATA / 'machinespirit/wallpapers')
    tree('installer', DATA / 'machinespirit/installer')
    return pairs

def restore(tx, guarded=True):
    manifest = json.loads((tx / 'manifest.json').read_text())
    for e in reversed(manifest['files']):
        dst = Path(e['dest']); current = fingerprint(dst)
        if guarded and current != e.get('installed'):
            print(f'Preserved changed file: {dst}'); continue
        original = tx / e['backup'] if e.get('backup') else None
        if original: copy_file(original, dst)
        elif dst.exists() or dst.is_symlink(): dst.unlink()
    print(f'Restored {tx.name}')

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('operation', nargs='?', default='install', choices=['install','update','doctor','uninstall','restore'])
    p.add_argument('backup', nargs='?')
    p.add_argument('--full', action='store_true'); p.add_argument('--components')
    p.add_argument('--dry-run', action='store_true'); p.add_argument('--no-packages', action='store_true')
    p.add_argument('--yes', action='store_true'); p.add_argument('--with-aur', action='store_true')
    a = p.parse_args()
    if any(not path.is_absolute() for path in [HOME,CONF,DATA,STATE]): p.error('HOME and XDG paths must be absolute')
    if os.geteuid() == 0: p.error('Run as your normal desktop user, not root.')
    if a.operation == 'doctor':
        failures = []
        selected_file=STATE/'components.json'
        selected=json.loads(selected_file.read_text()) if selected_file.exists() else ['shell']
        commands={'shell':['quickshell','python3','matugen','grim','slurp','wpctl','playerctl'], 'hyprland':['Hyprland'], 'terminal':['kitty','fish','fastfetch'], 'apps':['dolphin','firefox','btop'], 'lock':['hyprlock','hypridle'], 'boot':['plymouth'], 'wallpapers':[]}
        for tool in sorted({tool for c in selected for tool in commands[c]}):
            found = shutil.which(tool); print(f'{tool}: {found or "MISSING"}')
            if not found: failures.append(tool)
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
                restore(STATE / a.backup)
            else:
                for tx in sorted(STATE.glob('*/manifest.json'), reverse=True):
                    if json.loads(tx.read_text()).get('status') == 'complete': restore(tx.parent)
        return 0
    previous = STATE / 'components.json'
    previous_text = previous.read_text() if previous.exists() else None
    if a.full and a.components: p.error('Choose --full or --components, not both')
    selected = COMPONENTS[:] if a.full else (a.components.split(',') if a.components else None)
    if selected is None and previous.exists(): selected = json.loads(previous.read_text())
    if selected is None:
        if a.yes or not sys.stdin.isatty(): p.error('Choose --full or --components shell,hyprland,...')
        answer = input('Components: ' + ', '.join(COMPONENTS) + '\nEnter full or a comma-separated selection [shell,hyprland,lock,wallpapers]: ').strip()
        selected = COMPONENTS[:] if answer == 'full' else (answer or 'shell,hyprland,lock,wallpapers').split(',')
    selected = [c.strip() for c in selected]
    if not selected or any(c not in COMPONENTS for c in selected): p.error('Unknown component')
    selected = sorted(set(selected) | {'shell'})
    pairs = mappings(selected)
    packages = sorted(set(' '.join(PACKAGES[c] for c in selected).split()))
    print('Components:', ', '.join(selected)); print('Packages:', ' '.join(packages))
    for _, dst in pairs: print('File:', dst)
    # Never traverse a redirected parent silently.
    for _, dst in pairs:
        for parent in dst.parents:
            if parent == HOME.parent: break
            if parent.is_symlink(): raise ValueError(f'Symlink parent requires manual installation: {parent}')
        fingerprint(dst)
    if 'boot' in selected:
        subprocess.run([sys.executable, str(ROOT / 'installer/boot.py'), 'check'], check=True)
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
        tx = STATE / (time.strftime('%Y%m%d-%H%M%S') + '-' + str(os.getpid())); tx.mkdir()
        manifest = {'version':1, 'components':selected, 'files':[], 'status':'applying'}
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
                entry = {'dest':str(dst), 'backup':None, 'installed':fingerprint(src)}
                if old is not None:
                    entry['backup'] = 'backup/' + str(len(manifest['files']))
                    copy_file(dst, tx / entry['backup'])
                manifest['files'].append(entry); save(); copy_file(src, dst)
            atomic(previous, json.dumps(selected)); manifest['status'] = 'complete'; save()
        except BaseException:
            restore(tx, guarded=False); manifest['status']='rolled-back'; save(); raise
    try:
        sys.path.insert(0, str(ROOT / 'tools'))
        from managed import transaction
        with transaction([CONF / 'machinespirit/generated.lua', CONF / 'machinespirit/hypridle.conf'], STATE.parent):
            subprocess.run([str(BIN / 'ms-settings'), 'generate'], check=True)
        if 'wallpapers' in selected and not (STATE.parent / 'theme.json').exists():
            subprocess.run([str(BIN / 'ms-theme'), 'apply', str(DATA / 'machinespirit/wallpapers/forge.png')], check=True)
        if shutil.which('fc-cache'): subprocess.run(['fc-cache', '-f', str(DATA / 'fonts/machinespirit')], check=True)
        if 'boot' in selected: subprocess.run(['sudo', sys.executable, str(ROOT / 'installer/boot.py'), 'install'], check=True)
    except BaseException:
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
    print('Installed. Backup ID:', tx.name, '\nSelect the MachineSpirit Hyprland configuration on your next login.')
    return 0
if __name__ == '__main__':
    try: sys.exit(main())
    except (OSError, ValueError, subprocess.CalledProcessError) as e: print('Installation failed:', e, file=sys.stderr); sys.exit(1)
