#!/usr/bin/env python3
# [ PURITY SEAL ] Prove the gate on a false root before it is built on the real one.
"""installer/login.py against a disposable fake root: no root rights, no real systemd, no real SDDM."""
import json, os, shutil, subprocess, sys, tempfile, unittest
from pathlib import Path
# the tests run installers and ms-cursor: gsettings must not reach the real desktop (dconf over the session bus), nor hyprctl the running Hyprland
os.environ['GSETTINGS_BACKEND'] = 'memory'; os.environ.pop('HYPRLAND_INSTANCE_SIGNATURE', None)
REPO = Path(__file__).resolve().parents[1]

FAKE_SYSTEMCTL = '''#!/usr/bin/env python3
import json, os, sys
root = os.environ['MS_LOGIN_ROOT']; state = os.environ['FAKE_STATE']
data = json.load(open(state)) if os.path.exists(state) else {}
args = sys.argv[1:]; open(state + '.log', 'a').write(' '.join(args) + '\\n')
link = root + '/etc/systemd/system/display-manager.service'
if args[0] == 'is-enabled':
    print('enabled' if data.get(args[1]) else 'disabled'); sys.exit(0 if data.get(args[1]) else 1)
if args[0] == 'enable':
    if os.environ.get('FAKE_ENABLE_FAILS'): print('boom', file=sys.stderr); sys.exit(1)
    data[args[1]] = True; os.makedirs(os.path.dirname(link), exist_ok=True)
    if not os.path.lexists(link): os.symlink('/usr/lib/systemd/system/' + args[1], link)
if args[0] == 'disable':
    data[args[1]] = False
    if os.path.islink(link): os.unlink(link)
json.dump(data, open(state, 'w'))
'''
FAKE_GREETER = '''#!/usr/bin/env bash
if [ -n "$FAKE_GREETER_FAILS" ]; then echo 'file:///theme/Main.qml:3: module "QtQuick.Nope" is not installed' >&2; exit 1; fi
exec sleep 30
'''

class LoginTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp()); self.addCleanup(shutil.rmtree, self.tmp, True)
        self.fs = self.tmp / 'fs'; self.bin = self.tmp / 'bin'; self.bin.mkdir()
        self.repo = self.tmp / 'repo'
        (self.repo / 'installer').mkdir(parents=True); shutil.copy(REPO / 'installer/login.py', self.repo / 'installer/login.py')
        theme = self.repo / 'assets/sddm/machinespirit'; theme.mkdir(parents=True)
        (theme / 'Main.qml').write_text('import QtQuick\nItem {}\n'); (theme / 'theme.conf').write_text('[General]\n')
        (theme / 'metadata.desktop').write_text('[SddmGreeterTheme]\nName=MachineSpirit\n')
        for rel in ('usr/share/wayland-sessions/hyprland.desktop', 'usr/bin/sddm'):
            f = self.fs / rel; f.parent.mkdir(parents=True, exist_ok=True); f.write_text('')
        (self.fs / 'usr/lib/qt6/qml/QtQuick').mkdir(parents=True)
        for name, body in (('systemctl', FAKE_SYSTEMCTL), ('sddm-greeter-qt6', FAKE_GREETER)):
            f = self.bin / name; f.write_text(body.replace('#!/usr/bin/env python3', '#!' + sys.executable).replace('#!/usr/bin/env bash', '#!/bin/bash').replace('exec sleep 30', 'exec /bin/sleep 30')); f.chmod(0o755)
        self.env = dict(os.environ, MS_LOGIN_ROOT=str(self.fs), FAKE_STATE=str(self.tmp / 'state.json'), PATH=str(self.bin), MS_LOGIN_GREETER_WAIT='0.4')
        self.env.pop('FAKE_GREETER_FAILS', None); self.env.pop('FAKE_ENABLE_FAILS', None)

    def run_login(self, *args, **env):
        return subprocess.run([sys.executable, str(self.repo / 'installer/login.py'), *args], env={**self.env, **env}, capture_output=True, text=True)
    def calls(self):
        log = Path(str(self.tmp / 'state.json') + '.log'); return log.read_text().splitlines() if log.exists() else []
    def conf(self, name='machinespirit.conf'): return self.fs / 'etc/sddm.conf.d' / name
    def make_dm(self, name):
        link = self.fs / 'etc/systemd/system/display-manager.service'; link.parent.mkdir(parents=True, exist_ok=True)
        link.symlink_to(f'/usr/lib/systemd/system/{name}.service')

    def test_no_display_manager_installs_sddm_theme_and_enables_without_starting(self):
        r = self.run_login('install', '--user', 'ada'); self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('Current=machinespirit', self.conf().read_text())
        self.assertTrue((self.fs / 'usr/share/sddm/themes/machinespirit/Main.qml').is_file())
        self.assertIn('enable sddm.service', self.calls())
        self.assertFalse([c for c in self.calls() if c.startswith(('start', 'restart', 'isolate')) or '--now' in c])
        self.assertFalse(self.conf('machinespirit-autologin.conf').exists(), 'autologin must be off by default')
        self.assertIn('Reboot', r.stdout)

    def test_second_install_changes_nothing_and_leaves_no_record(self):
        self.run_login('install', '--user', 'ada'); before = sorted((self.fs / 'var/lib/machinespirit/login').iterdir())
        r = self.run_login('install', '--user', 'ada'); self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('nothing to change', r.stdout)
        self.assertEqual(before, sorted((self.fs / 'var/lib/machinespirit/login').iterdir()))

    def test_an_update_refreshes_our_theme_without_enabling_anything_again(self):
        self.run_login('install', '--user', 'ada'); enables = len([c for c in self.calls() if c.startswith('enable')])
        (self.repo / 'assets/sddm/machinespirit/Main.qml').write_text('import QtQuick\nItem { width: 1 }\n')
        r = self.run_login('install', '--user', 'ada'); self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('width: 1', (self.fs / 'usr/share/sddm/themes/machinespirit/Main.qml').read_text())
        self.assertEqual(enables, len([c for c in self.calls() if c.startswith('enable')]))
        # and a full uninstall still returns the original (absent) state
        self.assertEqual(self.run_login('uninstall').returncode, 0); self.assertFalse((self.fs / 'usr/share/sddm/themes/machinespirit').exists())

    def test_uninstall_puts_everything_back_and_disables_only_what_it_enabled(self):
        self.run_login('install', '--user', 'ada', '--autologin')
        self.assertTrue(self.conf('machinespirit-autologin.conf').exists())
        r = self.run_login('uninstall'); self.assertEqual(r.returncode, 0, r.stderr)
        self.assertFalse(self.conf().exists()); self.assertFalse(self.conf('machinespirit-autologin.conf').exists())
        self.assertFalse((self.fs / 'usr/share/sddm/themes/machinespirit').exists())
        self.assertIn('disable sddm.service', self.calls())

    def test_autologin_needs_the_flag_and_names_the_session(self):
        self.run_login('install', '--user', 'ada', '--autologin')
        text = self.conf('machinespirit-autologin.conf').read_text()
        self.assertIn('User=ada', text); self.assertIn('Session=hyprland.desktop', text)

    def test_existing_autologin_is_not_overridden(self):
        d = self.fs / 'etc/sddm.conf.d'; d.mkdir(parents=True); (d / 'autologin.conf').write_text('[Autologin]\nUser=bob\n')
        r = self.run_login('install', '--user', 'ada', '--autologin'); self.assertEqual(r.returncode, 0, r.stderr)
        self.assertFalse(self.conf('machinespirit-autologin.conf').exists()); self.assertIn('already set for bob', r.stdout)
        self.assertEqual((d / 'autologin.conf').read_text(), '[Autologin]\nUser=bob\n')

    def test_existing_sddm_keeps_its_configuration_and_is_not_touched(self):
        self.make_dm('sddm'); d = self.fs / 'etc/sddm.conf.d'; d.mkdir(parents=True)
        (d / 'kde_settings.conf').write_text('[Theme]\nCurrent=breeze\n'); (d / 'autologin.conf').write_text('[Autologin]\nUser=kuku\n')
        r = self.run_login('install', '--user', 'ada'); self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('already your display manager', r.stdout)
        self.assertEqual(sorted(p.name for p in d.iterdir()), ['autologin.conf', 'kde_settings.conf'])
        self.assertFalse([c for c in self.calls() if c.startswith('enable')]); self.assertFalse((self.fs / 'usr/share/sddm/themes/machinespirit').exists())

    def test_another_display_manager_is_left_alone_and_explained(self):
        for dm in ('gdm', 'lightdm', 'greetd'):
            with self.subTest(dm=dm):
                link = self.fs / 'etc/systemd/system/display-manager.service'; link.unlink(missing_ok=True); self.make_dm(dm)
                r = self.run_login('install', '--user', 'ada', '--autologin'); self.assertEqual(r.returncode, 0, r.stderr)
                self.assertIn(dm, r.stdout); self.assertIn('not the UWSM', r.stdout)
                self.assertFalse((self.fs / 'etc/sddm.conf.d').exists()); self.assertFalse([c for c in self.calls() if c.startswith('enable')])

    def test_display_manager_enabled_without_the_alias_link_is_still_found(self):
        Path(str(self.tmp / 'state.json')).write_text(json.dumps({'lightdm.service': True}))
        r = self.run_login('install', '--user', 'ada'); self.assertEqual(r.returncode, 0, r.stderr); self.assertIn('lightdm', r.stdout)
        self.assertFalse((self.fs / 'etc/sddm.conf.d').exists())

    def test_users_own_theme_is_kept(self):
        d = self.fs / 'etc/sddm.conf.d'; d.mkdir(parents=True); (d / 'kde_settings.conf').write_text('[Theme]\nCurrent=breeze\n')
        r = self.run_login('install', '--user', 'ada'); self.assertEqual(r.returncode, 0, r.stderr)
        self.assertFalse(self.conf().exists()); self.assertIn('breeze', r.stdout); self.assertIn('enable sddm.service', self.calls())

    def test_a_theme_that_does_not_load_is_never_switched_on(self):
        r = self.run_login('install', '--user', 'ada', FAKE_GREETER_FAILS='1'); self.assertEqual(r.returncode, 0, r.stderr)
        self.assertFalse(self.conf().exists()); self.assertFalse((self.fs / 'usr/share/sddm/themes/machinespirit').exists())
        self.assertIn('did not load', r.stdout); self.assertIn('enable sddm.service', self.calls(), 'a working default login is still set up')

    def test_missing_greeter_means_no_theme_not_a_broken_one(self):
        (self.bin / 'sddm-greeter-qt6').unlink()
        r = self.run_login('install', '--user', 'ada'); self.assertEqual(r.returncode, 0, r.stderr)
        self.assertFalse(self.conf().exists())

    def test_blockers_are_reported_with_the_fix_before_anything_is_written(self):
        (self.fs / 'usr/share/wayland-sessions/hyprland.desktop').unlink()
        r = self.run_login('check', '--user', 'ada'); self.assertNotEqual(r.returncode, 0); self.assertIn('pacman -S hyprland', r.stderr)
        (self.fs / 'usr/share/wayland-sessions/hyprland.desktop').write_text('')
        (self.fs / 'usr/bin/sddm').unlink()
        r = self.run_login('check', '--user', 'ada'); self.assertNotEqual(r.returncode, 0); self.assertIn('pacman -S sddm', r.stderr)
        # The same machine before the packages are installed (a clean TTY): the pre-flight check must let the installer go on.
        r = self.run_login('check', '--user', 'ada', '--packages-pending'); self.assertEqual(r.returncode, 0, r.stderr)
        (self.fs / 'usr/bin/sddm').write_text('')
        shutil.rmtree(self.fs / 'usr/lib/qt6/qml/QtQuick')
        r = self.run_login('check', '--user', 'ada'); self.assertNotEqual(r.returncode, 0); self.assertIn('qt6-declarative', r.stderr)
        self.assertFalse((self.fs / 'etc').exists() and any((self.fs / 'etc').rglob('*.conf')))

    def test_a_failed_enable_rolls_every_file_back(self):
        r = self.run_login('install', '--user', 'ada', '--autologin', FAKE_ENABLE_FAILS='1')
        self.assertNotEqual(r.returncode, 0); self.assertIn('enable sddm.service failed', r.stderr)
        self.assertFalse(self.conf().exists()); self.assertFalse(self.conf('machinespirit-autologin.conf').exists())
        self.assertFalse((self.fs / 'usr/share/sddm/themes/machinespirit').exists())

    def test_check_writes_nothing(self):
        r = self.run_login('check', '--user', 'ada', '--autologin'); self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('passwordless autologin', r.stdout); self.assertFalse((self.fs / 'etc').exists()); self.assertFalse((self.fs / 'var').exists())

if __name__ == '__main__': unittest.main()
