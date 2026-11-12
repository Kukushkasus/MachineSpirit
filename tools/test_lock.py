#!/usr/bin/env python3
# [ PURITY SEAL ] A second seal over a held seal is no seal at all.
"""`ms-session lock`: when the shell's lock is used, when hyprlock takes over, and when nothing may be started."""
import json, os, shutil, subprocess, sys, tempfile, unittest
from pathlib import Path
# the tests run installers and ms-cursor: gsettings must not reach the real desktop (dconf over the session bus), nor hyprctl the running Hyprland
os.environ['GSETTINGS_BACKEND'] = 'memory'; os.environ.pop('HYPRLAND_INSTANCE_SIGNATURE', None)
ROOT = Path(__file__).resolve().parents[1]

FAKE_QUICKSHELL = '''#!SYS
import os, sys
fn = sys.argv[-1]; state = os.environ['FAKE_QS_STATE']
if os.environ.get('FAKE_QS_DEAD'): sys.exit(1)
cur = open(state).read() if os.path.exists(state) else 'unlocked'
if fn == 'lock' and not os.environ.get('FAKE_QS_NEVER'): cur = 'secure' if not os.environ.get('FAKE_QS_SLOW') else 'locking'
if fn == 'cancel': cur = 'locking' if os.environ.get('FAKE_QS_STUCK') else 'unlocked'
open(state, 'w').write(cur); open(state + '.log', 'a').write(fn + '\\n')
if fn in ('state', 'cancel'): print(cur)
'''
FAKE_HYPRLOCK = '''#!SYS
import os
open(os.environ['FAKE_QS_STATE'] + '.hyprlock', 'a').write('ran\\n')
'''

class LockCase(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp()); self.addCleanup(shutil.rmtree, self.tmp, True)
        self.bin = self.tmp / 'bin'; self.bin.mkdir(); self.run_dir = self.tmp / 'run'; self.conf = self.tmp / 'conf'
        for name, body in (('quickshell', FAKE_QUICKSHELL), ('hyprlock', FAKE_HYPRLOCK)):
            f = self.bin / name; f.write_text(body.replace('#!SYS', '#!' + sys.executable)); f.chmod(0o755)
        (self.tmp / 'pam').write_text('auth required pam_permit.so\n')
        self.env = dict(os.environ, PATH=str(self.bin) + ':' + os.environ['PATH'], XDG_RUNTIME_DIR=str(self.tmp / 'xdg'), XDG_CONFIG_HOME=str(self.conf),
                        FAKE_QS_STATE=str(self.tmp / 'qs'), MS_PAM_SERVICE=str(self.tmp / 'pam'), MS_LOCK_WAIT='0.5')
        (self.tmp / 'xdg').mkdir(); self.marker = self.tmp / 'xdg' / f'machinespirit-{os.getuid()}' / 'locked'
        for k in ('FAKE_QS_DEAD', 'FAKE_QS_NEVER', 'FAKE_QS_STUCK', 'FAKE_QS_SLOW'): self.env.pop(k, None)

    def lock(self, **env):
        return subprocess.run([sys.executable, str(ROOT / 'bin/ms-session'), 'lock'], env={**self.env, **env}, capture_output=True, text=True, timeout=30)
    def hyprlock_ran(self): return (self.tmp / 'qs.hyprlock').exists()
    def ipc_calls(self):
        log = self.tmp / 'qs.log'; return log.read_text().split() if log.exists() else []
    def set_backend(self, name):
        (self.conf / 'machinespirit').mkdir(parents=True); (self.conf / 'machinespirit/settings.json').write_text(json.dumps({'version': 1, 'lockBackend': name}))


class LockTests(LockCase):
    def test_the_shells_lock_is_used_and_confirmed_by_state(self):
        r = self.lock(); self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('lock', self.ipc_calls()); self.assertEqual((self.tmp / 'qs').read_text(), 'secure'); self.assertFalse(self.hyprlock_ran())

    def test_a_lock_that_is_already_held_is_left_alone(self):
        (self.tmp / 'qs').write_text('secure')
        r = self.lock(); self.assertEqual(r.returncode, 0); self.assertNotIn('lock', self.ipc_calls()); self.assertFalse(self.hyprlock_ran())

    def test_hyprlock_takes_over_only_when_the_shell_is_not_running_and_nothing_is_held(self):
        r = self.lock(FAKE_QS_DEAD='1'); self.assertEqual(r.returncode, 0, r.stderr); self.assertTrue(self.hyprlock_ran())

    def test_no_second_locker_when_the_shell_died_holding_the_lock(self):
        self.marker.parent.mkdir(parents=True); self.marker.write_text('instance')
        r = self.lock(FAKE_QS_DEAD='1'); self.assertNotEqual(r.returncode, 0)
        self.assertIn('no second locker', r.stderr); self.assertFalse(self.hyprlock_ran())

    def test_an_unconfirmed_request_is_withdrawn_before_hyprlock_is_used(self):
        r = self.lock(FAKE_QS_NEVER='1'); self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('cancel', self.ipc_calls()); self.assertTrue(self.hyprlock_ran())

    def test_an_unconfirmed_request_that_cannot_be_withdrawn_starts_nothing(self):
        r = self.lock(FAKE_QS_NEVER='1', FAKE_QS_STUCK='1'); self.assertNotEqual(r.returncode, 0); self.assertFalse(self.hyprlock_ran())

    def test_without_the_pam_service_the_shells_lock_is_not_attempted(self):
        r = self.lock(MS_PAM_SERVICE=str(self.tmp / 'missing')); self.assertEqual(r.returncode, 0)
        self.assertNotIn('lock', self.ipc_calls()); self.assertTrue(self.hyprlock_ran())

    def test_hyprlock_can_be_chosen_in_settings(self):
        self.set_backend('hyprlock'); r = self.lock(); self.assertEqual(r.returncode, 0)
        self.assertEqual(self.ipc_calls(), []); self.assertTrue(self.hyprlock_ran())

    def test_settings_accept_only_the_two_backends(self):
        import importlib.machinery, importlib.util
        loader = importlib.machinery.SourceFileLoader('mss', str(ROOT / 'bin/ms-settings')); spec = importlib.util.spec_from_loader('mss', loader)
        mod = importlib.util.module_from_spec(spec); sys.path.insert(0, str(ROOT / 'bin')); loader.exec_module(mod)
        self.assertEqual(mod.validate({'version': 1, 'lockBackend': 'hyprlock'})['lockBackend'], 'hyprlock')
        with self.assertRaises(ValueError): mod.validate({'version': 1, 'lockBackend': 'swaylock'})


class HeldLockProtectionTests(LockCase):
    """While the screen is locked nothing may restart the shell or change its files: the request is refused before anything happens."""
    def locked(self, **env):
        return subprocess.run([sys.executable, str(ROOT / 'bin/ms-session'), 'locked'], env={**self.env, **env}, capture_output=True, text=True, timeout=30)
    def test_locked_reports_a_held_lock(self):
        (self.tmp / 'qs').write_text('secure'); self.assertEqual(self.locked().returncode, 0)
    def test_locked_reports_a_free_screen(self):
        self.assertNotEqual(self.locked().returncode, 0)
    def test_a_lock_that_outlived_its_shell_still_counts_as_held(self):
        self.marker.parent.mkdir(parents=True); self.marker.write_text('instance')
        self.assertEqual(self.locked(FAKE_QS_DEAD='1').returncode, 0)
    def test_no_marker_and_no_shell_means_nothing_is_held(self):
        self.assertNotEqual(self.locked(FAKE_QS_DEAD='1').returncode, 0)
    def test_restart_is_refused_while_locked(self):
        (self.tmp / 'qs').write_text('secure')
        r = subprocess.run([sys.executable, str(ROOT / 'bin/ms-session'), 'restart'], env=self.env, capture_output=True, text=True, timeout=30)
        self.assertNotEqual(r.returncode, 0); self.assertIn('Unlock it first', r.stderr)
    def fake_home(self, locked):
        home = self.tmp / 'home'; (home / '.local/bin').mkdir(parents=True)
        h = home / '.local/bin/ms-session'; h.write_text('#!/bin/sh\nexit %d\n' % (0 if locked else 1)); h.chmod(0o755)
        return dict(self.env, HOME=str(home), XDG_CONFIG_HOME=str(home / 'c'), XDG_DATA_HOME=str(home / 'd'), XDG_STATE_HOME=str(home / 's')), home
    def test_the_installer_stops_before_changing_anything_while_locked(self):
        env, home = self.fake_home(True)
        r = subprocess.run([sys.executable, str(ROOT / 'installer/install.py'), '--components', 'shell', '--no-packages', '--no-system', '--yes'], env=env, capture_output=True, text=True, stdin=subprocess.DEVNULL, timeout=60)
        self.assertNotEqual(r.returncode, 0); self.assertIn('Unlock it first', r.stderr)
        self.assertFalse((home / 'c').exists() or (home / 'd').exists() or (home / 's').exists(), 'nothing may be written')
    def test_a_dry_run_is_not_blocked(self):
        env, _ = self.fake_home(True)
        r = subprocess.run([sys.executable, str(ROOT / 'installer/install.py'), '--components', 'shell', '--dry-run'], env=env, capture_output=True, text=True, stdin=subprocess.DEVNULL, timeout=60)
        self.assertEqual(r.returncode, 0, r.stderr)
    def test_ms_update_stops_before_downloading_while_locked(self):
        fake = self.tmp / 'fakebin'; fake.mkdir(); h = fake / 'ms-session'; h.write_text('#!/bin/sh\nexit 0\n'); h.chmod(0o755)
        env = dict(self.env, PATH=str(fake) + ':' + self.env['PATH'], XDG_STATE_HOME=str(self.tmp / 'st'), XDG_CACHE_HOME=str(self.tmp / 'ca'))
        r = subprocess.run([sys.executable, str(ROOT / 'bin/ms-update'), 'install', '--yes'], env=env, capture_output=True, text=True, timeout=60)
        self.assertEqual(r.returncode, 1); self.assertIn('screen is locked', r.stdout); self.assertIn('Nothing was changed', r.stdout)


class Supervisor(unittest.TestCase):
    """`ms-session start` belongs to one Hyprland: when that compositor is gone (logout) it ends with it."""
    def test_the_supervisor_ends_with_its_compositor(self):
        tmp = Path(tempfile.mkdtemp()); self.addCleanup(shutil.rmtree, tmp, True)
        fake = tmp / 'bin'; fake.mkdir()
        for name, body in (('quickshell', 'echo $$ > "$FAKE_PIDS/shell"; exec sleep 60'), ('ms-privacy', 'echo $$ > "$FAKE_PIDS/privacy"; exec sleep 60'), ('ms-settings', 'exit 0')):
            f = fake / name; f.write_text('#!/bin/sh\n' + body + '\n'); f.chmod(0o755)
        sock = tmp / 'xdg/hypr/sig/.socket.sock'; sock.parent.mkdir(parents=True); sock.write_text('')
        env = dict(os.environ, PATH=str(fake) + ':' + os.environ['PATH'], HOME=str(tmp), XDG_RUNTIME_DIR=str(tmp / 'xdg'),
                   XDG_CONFIG_HOME=str(tmp / 'c'), XDG_STATE_HOME=str(tmp / 's'), HYPRLAND_INSTANCE_SIGNATURE='sig', FAKE_PIDS=str(tmp))
        sup = subprocess.Popen([sys.executable, str(ROOT / 'bin/ms-session'), 'start'], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.addCleanup(lambda: sup.poll() is None and sup.kill())
        for _ in range(50):
            if (tmp / 'shell').exists(): break
            subprocess.run(['sleep', '0.1'])
        subprocess.run(['sleep', '1.5'])
        self.assertIsNone(sup.poll(), 'the supervisor keeps running while its compositor is there')
        shell = int((tmp / 'shell').read_text())
        sock.unlink()                     # Hyprland exits: its control socket goes
        self.assertEqual(sup.wait(timeout=10), 0)
        subprocess.run(['sleep', '0.3'])
        with self.assertRaises(ProcessLookupError): os.kill(shell, 0)   # the shell went with it


    @unittest.skipUnless(shutil.which('setpriv'), 'needs setpriv (util-linux)')
    def test_the_privacy_daemon_dies_with_a_killed_supervisor(self):
        # at logout the supervisor may be killed outright; the daemon needs no display and must not live on
        tmp = Path(tempfile.mkdtemp()); self.addCleanup(shutil.rmtree, tmp, True)
        fake = tmp / 'bin'; fake.mkdir()
        for name, body in (('quickshell', 'echo $$ > "$FAKE_PIDS/shell"; exec sleep 60'), ('ms-privacy', 'echo $$ > "$FAKE_PIDS/privacy"; exec sleep 60'), ('ms-settings', 'exit 0')):
            f = fake / name; f.write_text('#!/bin/sh\n' + body + '\n'); f.chmod(0o755)
        env = dict(os.environ, PATH=str(fake) + ':' + os.environ['PATH'], HOME=str(tmp), XDG_RUNTIME_DIR=str(tmp / 'xdg'),
                   XDG_CONFIG_HOME=str(tmp / 'c'), XDG_STATE_HOME=str(tmp / 's'), FAKE_PIDS=str(tmp))
        env.pop('HYPRLAND_INSTANCE_SIGNATURE', None); (tmp / 'xdg').mkdir()
        sup = subprocess.Popen([sys.executable, str(ROOT / 'bin/ms-session'), 'start'], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for _ in range(50):
            if (tmp / 'privacy').exists(): break
            subprocess.run(['sleep', '0.1'])
        daemon = int((tmp / 'privacy').read_text())
        sup.kill(); sup.wait()
        subprocess.run(['sleep', '0.5'])
        with self.assertRaises(ProcessLookupError): os.kill(daemon, 0)
        try: os.kill(int((tmp / 'shell').read_text()), 9)   # the fake shell, left behind as the real one is by a lost display
        except (OSError, ValueError): pass

if __name__ == '__main__': unittest.main()
