#!/usr/bin/env python3
# [ PURITY SEAL ] Never take the gate from the one who already holds it.
"""Graphical login for MachineSpirit: SDDM, its own theme and, only when asked, autologin.

check     read-only: decide what would happen and stop on anything that cannot be done safely
install   run as root (sudo): write the files, keep a backup of every one, enable sddm.service
restore   put one recorded change back; uninstall puts every recorded change back, newest first

Rules: an existing display manager is never replaced or reconfigured; a theme or an autologin that someone else
chose is never overridden; the theme is switched on only after the greeter has loaded it; sddm.service is enabled
but never started, so the running session is left alone.
"""
import configparser, json, os, re, shutil, subprocess, sys, time
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
FS = Path(os.environ.get('MS_LOGIN_ROOT', '/'))   # a fake root, for tests only
def at(path): return FS / str(path).lstrip('/')
BACKUP = at('/var/lib/machinespirit/login')
CONF_DIR = at('/etc/sddm.conf.d')
OURS = ('machinespirit.conf', 'machinespirit-autologin.conf')
THEME, THEME_SRC = 'machinespirit', ROOT / 'assets/sddm/machinespirit'
THEME_DST = at('/usr/share/sddm/themes/machinespirit')
SESSION = 'hyprland.desktop'
KNOWN_DMS = ('sddm', 'gdm', 'lightdm', 'greetd', 'ly', 'lxdm', 'plasmalogin', 'cosmic-greeter')
QML_NEEDED = ('QtQuick',)   # the theme imports plain QtQuick only (qt6-declarative)
ERROR_MARKERS = re.compile(r'is not installed|is not a type|Failed to load|failed to load|ReferenceError|TypeError|Cannot assign|Unable to assign|Syntax ?Error|No such file', re.I)

def systemctl(*args):
    try: return subprocess.run(['systemctl', *args], capture_output=True, text=True)
    except FileNotFoundError: return subprocess.CompletedProcess(args, 127, '', 'systemctl was not found')

def display_manager():
    """Name of the display manager that starts at boot, or None."""
    link = at('/etc/systemd/system/display-manager.service')
    if link.is_symlink(): return Path(os.readlink(link)).name.removesuffix('.service')
    for name in KNOWN_DMS:
        if systemctl('is-enabled', name + '.service').stdout.strip() == 'enabled': return name
    return None

def sddm_settings():
    """(section, key) -> (value, file) over the user's SDDM configuration; ours is left out."""
    files = [at('/etc/sddm.conf')] + sorted(CONF_DIR.glob('*.conf')) if CONF_DIR.is_dir() else [at('/etc/sddm.conf')]
    found = {}
    for f in files:
        if not f.is_file() or f.name in OURS: continue
        cp = configparser.ConfigParser(strict=False, interpolation=None); cp.optionxform = str
        try: cp.read_string(f.read_text())
        except (configparser.Error, OSError, UnicodeDecodeError): continue
        for section in cp.sections():
            for key, value in cp.items(section): found[(section, key)] = (value.strip(), str(f))
    return found

def plan(user, autologin, pending=False):
    """Decide before anything is written. Raises ValueError with the fix for anything that blocks a safe install.
    pending: the packages are still to be installed, so SDDM and the Qt modules cannot be required yet."""
    session = at('/usr/share/wayland-sessions') / SESSION
    if not session.is_file(): raise ValueError(f'The Hyprland session file {session} is missing. Install the hyprland package (sudo pacman -S hyprland) and run the installer again.')
    dm = display_manager(); settings = sddm_settings(); notes = []; result = {'dm': dm, 'notes': notes, 'theme': False, 'autologin': False, 'enable': False}
    if dm and dm != 'sddm':
        notes.append(f'{dm} is your display manager. It is left as it is, and SDDM is not installed next to it. At its login screen choose the Hyprland session (not the UWSM one).')
        if autologin: notes.append('Autologin was not changed: it belongs to your display manager.')
        result['mode'] = 'foreign'; return result
    ours = bool(history()) or (CONF_DIR / OURS[0]).is_file()   # SDDM that MachineSpirit set up earlier: keep its theme current
    if dm == 'sddm' and not ours:
        result['mode'] = 'keep'
        notes.append('SDDM is already your display manager. Its configuration and theme are left as they are. At the login screen choose the Hyprland session (not the UWSM one).')
    else:
        result['mode'] = 'update' if dm == 'sddm' else 'install'
        if not pending and not at('/usr/bin/sddm').exists(): raise ValueError('SDDM is not installed. Run the installer without --no-packages, or install it with: sudo pacman -S sddm')
        result['enable'] = True
        if not THEME_SRC.is_dir(): notes.append('The MachineSpirit login theme is not part of this copy; the default SDDM theme will be used.')
        elif ('Theme', 'Current') in settings and settings[('Theme', 'Current')][0] not in ('', THEME):
            notes.append(f"Your SDDM theme ({settings[('Theme', 'Current')][0]}, set in {settings[('Theme', 'Current')][1]}) is kept.")
        else: result['theme'] = True
    if autologin:
        existing = settings.get(('Autologin', 'User'))
        if existing and existing[0]: notes.append(f'Autologin is already set for {existing[0]} in {existing[1]}; it was not changed.')
        elif not user: raise ValueError('Autologin needs the name of the user (--user).')
        else: result['autologin'] = True
    return result

def modules_present():
    qml = at('/usr/lib/qt6/qml')
    missing = [m for m in QML_NEEDED if not (qml / m).is_dir()]
    if missing: raise ValueError('The login theme needs Qt Quick modules that are missing: ' + ', '.join(missing) + '. Install qt6-declarative.')

def greeter_loads(src):
    """Load the theme in the SDDM greeter's test mode without a screen. A theme that does not load is never switched on."""
    exe = shutil.which('sddm-greeter-qt6')
    if not exe: return False, 'sddm-greeter-qt6 was not found'
    import tempfile
    with tempfile.TemporaryFile('w+') as out:
        proc = subprocess.Popen([exe, '--test-mode', '--theme', str(src)], stdout=out, stderr=out, env=dict(os.environ, QT_QPA_PLATFORM='offscreen'), start_new_session=True)
        try: proc.wait(timeout=float(os.environ.get('MS_LOGIN_GREETER_WAIT', '5')))
        except subprocess.TimeoutExpired:
            proc.kill(); proc.wait(); alive = True
        else: alive = False
        out.seek(0); text = out.read()
    if alive and not ERROR_MARKERS.search(text): return True, ''
    return False, (text.strip().splitlines() or ['the greeter exited at once'])[-1][:300]

def check(user, autologin, pending=False):
    result = plan(user, autologin, pending)
    for note in result['notes']: print('Login:', note)
    if result['mode'] == 'update': print('Login: the MachineSpirit login setup is kept up to date.')
    if result['mode'] == 'install':
        print('Login: no display manager found. SDDM will be enabled' + (' with the MachineSpirit theme.' if result['theme'] else '.') + ' It is not started now; sign in through it after the next boot.')
        if result['theme'] and not pending: modules_present()
    if result['autologin']: print(f'Login: passwordless autologin will be enabled for {user}.')
    return result

def install(user, autologin):
    if os.geteuid() != 0 and 'MS_LOGIN_ROOT' not in os.environ: raise ValueError('The login component needs sudo')
    result = plan(user, autologin)
    for note in result['notes']: print('Login:', note)
    files = {}
    if result['mode'] != 'foreign':
        if result['theme']:
            modules_present(); loads, why = greeter_loads(THEME_SRC)
            if loads: files[str(CONF_DIR / OURS[0])] = ('[Theme]\nCurrent=' + THEME + '\n', 'Written by MachineSpirit. Delete this file, or run ./install.sh uninstall, to return to the SDDM default.')
            else:
                result['theme'] = False; print(f'Login: the MachineSpirit theme did not load in the greeter ({why}); the default SDDM theme stays.')
        if result['autologin']: files[str(CONF_DIR / OURS[1])] = (f'[Autologin]\nUser={user}\nSession={SESSION}\n', 'Written by MachineSpirit (--with-autologin). Delete this file to ask for a password again.')
    wanted = {}   # path -> bytes
    for name, (text, comment) in files.items(): wanted[name] = ('# ' + comment + '\n' + text).encode()
    if result['theme']:
        for src in sorted(THEME_SRC.rglob('*')):
            if src.is_file(): wanted[str(THEME_DST / src.relative_to(THEME_SRC))] = src.read_bytes()
    changes = {name: data for name, data in wanted.items() if not Path(name).is_file() or Path(name).read_bytes() != data}
    enable = result['enable'] and systemctl('is-enabled', 'sddm.service').stdout.strip() != 'enabled'
    if not changes and not enable:
        print('Login: nothing to change.'); return
    BACKUP.mkdir(parents=True, mode=0o700, exist_ok=True)
    tx = BACKUP / (time.strftime('%Y%m%d-%H%M%S') + '-' + str(os.getpid())); tx.mkdir(mode=0o700)
    record = {'files': {}, 'enabled': False}
    def save(): (tx / 'record.json').write_text(json.dumps(record, indent=2))
    save()
    try:
        for index, (name, data) in enumerate(sorted(changes.items())):
            path = Path(name)
            if path.exists() or path.is_symlink():
                if path.is_symlink() or not path.is_file(): raise ValueError(f'Expected a regular file at {path}; it was left alone.')
                shutil.copy2(path, tx / str(index)); record['files'][name] = str(index)
            else: record['files'][name] = None
            save(); path.parent.mkdir(parents=True, exist_ok=True); path.write_bytes(data)
        if enable:
            record['enabled'] = True; save()
            r = systemctl('enable', 'sddm.service')
            if r.returncode: raise ValueError('systemctl enable sddm.service failed: ' + (r.stderr.strip() or r.stdout.strip()))
    except BaseException:
        undo(tx); raise
    (tx / 'complete').write_text('1')
    print('Login: backup', tx.name)
    if result['mode'] == 'install': print('Login: SDDM is enabled. Reboot, then sign in with the Hyprland session.')

def undo(tx):
    """Put one recorded change back: the saved original returns, a file we created is removed."""
    record = json.loads((tx / 'record.json').read_text()); kept = []
    for name, original in record['files'].items():
        path = Path(name)
        if original is None:
            path.unlink(missing_ok=True)
            for parent in path.parents:
                if parent in (CONF_DIR, at('/usr/share/sddm/themes'), FS): break
                try: parent.rmdir()
                except OSError: break
        else: shutil.copy2(tx / original, path)
    if record['enabled']:
        r = systemctl('disable', 'sddm.service')
        if r.returncode: kept.append('sddm.service could not be disabled: run sudo systemctl disable sddm.service')
    for line in kept: print('Login:', line, file=sys.stderr)
    (tx / 'complete').unlink(missing_ok=True); (tx / 'undone').write_text('1')
    return not kept

def history():
    return sorted((t for t in BACKUP.glob('*') if (t / 'complete').exists() and not (t / 'undone').exists()), reverse=True) if BACKUP.is_dir() else []

def main():
    args = sys.argv[1:]
    if not args: raise ValueError('Use check, install, restore ID or uninstall')
    cmd, rest = args[0], args[1:]
    user = rest[rest.index('--user') + 1] if '--user' in rest else None
    autologin = '--autologin' in rest
    if cmd == 'check': check(user, autologin, '--packages-pending' in rest)
    elif cmd == 'install': install(user, autologin)
    elif cmd in ('restore', 'uninstall'):
        if os.geteuid() != 0 and 'MS_LOGIN_ROOT' not in os.environ: raise ValueError('The login component needs sudo')
        if cmd == 'restore':
            if len(rest) != 1 or Path(rest[0]).name != rest[0] or not (BACKUP / rest[0] / 'record.json').is_file(): raise ValueError('Supply a login backup ID from /var/lib/machinespirit/login')
            if not undo(BACKUP / rest[0]): sys.exit(1)
        else:
            ok = all([undo(tx) for tx in history()])
            if not ok: sys.exit(1)
        if 'MS_LOGIN_ROOT' not in os.environ: systemctl('daemon-reload')
    else: raise ValueError('Use check, install, restore ID or uninstall')

if __name__ == '__main__':
    try: main()
    except (ValueError, OSError, subprocess.CalledProcessError) as e: sys.exit(str(e))
