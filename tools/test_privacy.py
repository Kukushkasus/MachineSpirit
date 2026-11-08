# SPDX-License-Identifier: GPL-3.0-only
import copy,importlib.machinery,importlib.util,json,os,sys,tempfile,unittest
from pathlib import Path
from unittest.mock import patch,MagicMock
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'bin'))
import ms_privacy as privacy
loader=importlib.machinery.SourceFileLoader('browser_policy',str(ROOT/'privacy/ms-browser-policy'))
spec=importlib.util.spec_from_loader(loader.name,loader);browser=importlib.util.module_from_spec(spec);loader.exec_module(browser)

class PrivacyTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.root=Path(self.temp.name)
        for name in ('CONF','STATE','CACHE'):
            p=patch.object(privacy,name,self.root/name);p.start();self.addCleanup(p.stop)
    def configure(self,**values):
        p=copy.deepcopy(privacy.DEFAULT);p.update(values)
        privacy.atomic(privacy.CONF/'settings.json',json.dumps({'privacy':p}))
        return p
    def finish(self):privacy.atomic(privacy.STATE/'onboarding.json','{"version":1}')
    def test_first_launch_blocks_every_feature(self):
        self.configure()
        for feature in privacy.FEATURES:self.assertFalse(privacy.allowed(feature,True))
        with patch.object(privacy.subprocess,'Popen') as popen:
            with self.assertRaises(ValueError):privacy.fetch('weather','https://wttr.in')
            popen.assert_not_called()
    def test_modes_and_manual_requests(self):
        self.configure(publicIp='manual');self.finish()
        self.assertFalse(privacy.allowed('publicIp'));self.assertTrue(privacy.allowed('publicIp',True))
        self.configure(mode='local')
        for f in privacy.FEATURES:self.assertFalse(privacy.allowed(f,True))
        self.assertFalse(privacy.allowed('proxyTest',True))
    def test_invalid_proxy_and_permissions(self):
        for p in [{'weather':'yes'},{'proxy':{'host':'host/path'}},{'proxy':{'port':True}},{'proxy':{'enabled':True}},{'city':'a\nb'}]:
            with self.subTest(p=p),self.assertRaises(ValueError):privacy.validate(p)
    def test_proxy_password_not_in_settings(self):
        p=self.configure();self.assertNotIn('password',p['proxy'])
    def test_reject_remote_file_and_cleartext(self):
        self.configure();self.finish()
        for url in ['file:///etc/passwd','http://example.org','https://user:secret@example.org']:
            with self.assertRaises(ValueError):privacy.fetch('remoteArt',url,image=True)
    def test_proxy_failure_never_retries_direct(self):
        self.configure(proxy={**privacy.DEFAULT['proxy'],'enabled':True,'shell':True,'host':'127.0.0.1'});self.finish()
        proc=MagicMock();proc.poll.return_value=7;proc.returncode=7
        with patch.object(privacy.subprocess,'Popen',return_value=proc) as popen:
            with self.assertRaisesRegex(ValueError,'Proxy'):privacy.fetch('weather','https://wttr.in')
            self.assertEqual(popen.call_count,1)
            sent=proc.stdin.write.call_args.args[0].decode();self.assertIn('127.0.0.1:17879',sent)
            self.assertEqual(json.loads(sent.split('noproxy = ')[1].splitlines()[0]),'')
    def test_settings_change_cancels_active_transfer(self):
        self.configure();self.finish();proc=MagicMock();proc.poll.side_effect=[None,0];proc.returncode=0
        with patch.object(privacy.subprocess,'Popen',return_value=proc),patch.object(privacy.time,'sleep',side_effect=lambda _:self.configure(mode='local')):
            with self.assertRaisesRegex(ValueError,'cancelled'):privacy.fetch('weather','https://wttr.in')
            proc.terminate.assert_called_once()

class BrowserTests(unittest.TestCase):
    def test_fixed_policy_whitelist(self):
        with self.assertRaises(ValueError):browser.policies('firefox',{'shell':'touch /tmp/no'})
        d=browser.policies('firefox',{'telemetry':True,'crashes':True})['policies']
        self.assertTrue(d['DisableTelemetry']);self.assertNotIn('DisableAppUpdate',d)
    def test_proxy_has_no_direct_fallback(self):
        d=browser.policies('firefox',{'proxy':True})['policies']
        self.assertFalse(d['Preferences']['network.proxy.failover_direct']['Value'])
        d=browser.policies('chrome',{'proxy':True});self.assertEqual(d['ProxySettings']['ProxyMode'],'fixed_servers');self.assertFalse(d['QuicAllowed'])
    def test_restore_preserves_existing_policy(self):
        with tempfile.TemporaryDirectory() as tmp:
            base=Path(tmp);p=base/'policies.json';old={'policies':{'Homepage':{'URL':'https://example.org'}}};p.write_text(json.dumps(old))
            with patch.object(browser,'STATE',base/'state'),patch.object(browser,'target',return_value=p),patch.object(browser,'secure'),patch.object(browser.os,'geteuid',return_value=0):
                browser.apply('firefox',{'telemetry':True});self.assertTrue(browser.read(p)['policies']['DisableTelemetry'])
                browser.apply('firefox',{});self.assertEqual(browser.read(p),old)
    def test_conflict_and_external_edit_preserved(self):
        with tempfile.TemporaryDirectory() as tmp:
            base=Path(tmp);p=base/'policies.json';p.write_text('{"policies":{"DisableTelemetry":false}}')
            with patch.object(browser,'STATE',base/'state'),patch.object(browser,'target',return_value=p),patch.object(browser,'secure'),patch.object(browser.os,'geteuid',return_value=0):
                with self.assertRaisesRegex(ValueError,'conflict'):browser.apply('firefox',{'telemetry':True})
                p.write_text('{}');browser.apply('firefox',{'telemetry':True})
                p.write_text('{"policies":{"DisableTelemetry":false}}')
                with self.assertRaisesRegex(ValueError,'External'):browser.apply('firefox',{})
                self.assertFalse(browser.read(p)['policies']['DisableTelemetry'])
    def test_batch_validates_every_item_before_writing(self):
        request={'changes':[{'browser':'firefox','flags':{'telemetry':True}}, {'browser':'chrome','flags':{'arbitrary':True}}]}
        with patch.object(browser,'apply') as apply:
            with self.assertRaises(ValueError):browser.batch(request,True)
            apply.assert_not_called()
        with self.assertRaises(ValueError):browser.batch({'changes':[{'browser':'firefox'},{'browser':'firefox'}]})

    def test_batch_reports_partial_failure(self):
        request={'changes':[{'browser':'firefox','flags':{'telemetry':True}}, {'browser':'chrome','flags':{'telemetry':True}}]}
        self.assertEqual(set(browser.batch(request)['policies']),{'firefox','chrome'})
        with patch.object(browser.os,'geteuid',return_value=0), patch.object(browser,'apply',side_effect=[{'browser':'firefox'},ValueError('Existing policy conflict')]) as apply:
            result=browser.batch(request,True)
            self.assertEqual(apply.call_count,2)
            self.assertEqual(result['results'],[{'browser':'firefox'}])
            self.assertIn('chrome: Existing policy conflict',result['error'])

    def test_changed_browser_path_does_not_restore_into_another_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            base=Path(tmp);first=base/'old/policies.json';second=base/'new/policies.json'
            second.parent.mkdir();second.write_text('{"policies":{"Homepage":{"URL":"https://example.org"}}}')
            original=second.read_bytes()
            with patch.object(browser,'STATE',base/'state'),patch.object(browser,'secure'),patch.object(browser.os,'geteuid',return_value=0):
                with patch.object(browser,'target',return_value=first):browser.apply('firefox',{'telemetry':True})
                record=(base/'state/firefox.json').read_bytes()
                with patch.object(browser,'target',return_value=second):
                    with self.assertRaisesRegex(ValueError,'location changed'):browser.apply('firefox',{})
                self.assertEqual(second.read_bytes(),original)
                self.assertEqual((base/'state/firefox.json').read_bytes(),record)
                with patch.object(browser,'target',return_value=first):browser.apply('firefox',{})
                self.assertEqual(browser.read(first),{})

    def test_symlinks_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)/'policies.json';p.symlink_to('/etc/passwd')
            with self.assertRaises(ValueError):browser.secure(p)
if __name__=='__main__':unittest.main()

class ThumbnailTests(unittest.TestCase):
    def setUp(self):
        import importlib.machinery, importlib.util
        loader = importlib.machinery.SourceFileLoader('ms_walls_t', str(ROOT / 'scripts/ms-walls')); spec = importlib.util.spec_from_loader('ms_walls_t', loader)
        self.walls = importlib.util.module_from_spec(spec); loader.exec_module(self.walls)
    def run_with(self, fetch, count=12):
        self.walls.privacy.fetch, saved = fetch, self.walls.privacy.fetch
        try:
            items = [{'local': False, 'thumb': f'https://example.com/{i}.jpg'} for i in range(count)] + [{'local': True, 'thumb': '/home/x/local.png'}]
            return self.walls.remote_result({'items': items})['items']
        finally: self.walls.privacy.fetch = saved
    def test_order_failures_and_local_items(self):
        import threading, time
        def fetch(feature, url, manual=False, image=False, **k):
            time.sleep(0.02)
            if url.endswith('/3.jpg'): raise ValueError('Request cancelled')
            return 'file://' + url.rsplit('/', 1)[1]
        items = self.run_with(fetch)
        self.assertEqual([i['thumb'] for i in items[:3]], ['file://0.jpg', 'file://1.jpg', 'file://2.jpg'])
        self.assertEqual(items[3]['thumb'], ''); self.assertEqual(items[11]['thumb'], 'file://11.jpg'); self.assertEqual(items[12]['thumb'], '/home/x/local.png')
    def test_loads_in_parallel_but_never_more_than_four_at_once(self):
        import threading, time
        lock = threading.Lock(); now = peak = 0
        def fetch(*a, **k):
            nonlocal now, peak
            with lock: now += 1; peak = max(peak, now)
            time.sleep(0.05)
            with lock: now -= 1
            return 'file://x'
        start = time.monotonic(); self.run_with(fetch, 12); elapsed = time.monotonic() - start
        self.assertGreater(peak, 1); self.assertLessEqual(peak, 4); self.assertLess(elapsed, 12 * 0.05 * 0.7, 'twelve 50 ms loads must overlap')
    def test_curl_dies_with_its_parent_without_preexec_fn(self):
        import ms_privacy
        src = Path(ms_privacy.__file__).read_text(); self.assertIn("setpriv','--pdeathsig','TERM'", src)

class DaemonLifecycleTests(unittest.TestCase):
    """The privacy daemon with a stand-in for gost: it must not leave the proxy behind when it is killed."""
    def setUp(self):
        import tempfile, stat
        self.tmp = tempfile.TemporaryDirectory(); d = Path(self.tmp.name); self.d = d
        (d / 'bin').mkdir(); fake = d / 'bin/gost'
        fake.write_text('#!/usr/bin/env python3\nimport time\ntime.sleep(300)\n'); fake.chmod(fake.stat().st_mode | stat.S_IXUSR)   # keeps its arguments visible in /proc like the real gost
        (d / 'c/machinespirit').mkdir(parents=True); (d / 'r').mkdir(mode=0o700)
        (d / 'c/machinespirit/settings.json').write_text(json.dumps({'version': 1, 'privacy': {'proxy': {'enabled': True, 'scheme': 'socks5', 'host': '127.0.0.1', 'port': 1, 'username': '', 'shell': False}}}))
        self.env = dict(os.environ, HOME=str(d), XDG_CONFIG_HOME=str(d / 'c'), XDG_STATE_HOME=str(d / 's'), XDG_RUNTIME_DIR=str(d / 'r'), PATH=f'{d}/bin:/usr/bin:/bin', FAKE_GOST_LOG=str(d / 'gost.log'))
    def tearDown(self):
        import subprocess
        subprocess.run(['pkill', '-f', f'{self.d}/'], capture_output=True)
        self.tmp.cleanup()
    def gost_pids(self):
        mine = []
        for entry in Path('/proc').iterdir():
            if not entry.name.isdigit(): continue
            try:
                if str(self.d / 'bin/gost').encode() in (entry / 'cmdline').read_bytes() and not (entry / 'stat').read_text().rsplit(')', 1)[1].split()[0] == 'Z': mine.append(int(entry.name))
            except OSError: pass
        return mine
    def wait_for(self, cond, seconds=8):
        import time
        end = time.monotonic() + seconds
        while time.monotonic() < end:
            if cond(): return True
            time.sleep(.1)
        return cond()
    def test_gost_dies_with_a_killed_daemon_and_stale_ones_are_reaped(self):
        import subprocess, signal
        if not shutil_which('setpriv'): self.skipTest('setpriv is not available')
        daemon = subprocess.Popen([sys.executable, str(ROOT / 'bin/ms-privacy'), 'daemon'], env=self.env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.assertTrue(self.wait_for(lambda: len(self.gost_pids()) == 1), 'gost should start once the proxy is enabled')
        gost = self.gost_pids()[0]
        daemon.kill(); daemon.wait()
        self.assertTrue(self.wait_for(lambda: not Path(f'/proc/{gost}').exists()), 'gost must die with the daemon (SIGKILL included)')
    def test_leftover_gost_from_an_older_daemon_is_stopped_on_start(self):
        import subprocess
        # an orphan that still uses the daemon's runtime config, as after a crash on a system without setpriv
        cfg = self.d / 'r/machinespirit-privacy'; cfg.mkdir(mode=0o700, exist_ok=True)
        orphan = subprocess.Popen([str(self.d / 'bin/gost'), '-C', str(cfg / 'gost.json')], env=self.env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.assertTrue(self.wait_for(lambda: Path(f'/proc/{orphan.pid}/cmdline').exists()))
        daemon = subprocess.Popen([sys.executable, str(ROOT / 'bin/ms-privacy'), 'daemon'], env=self.env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        try: self.assertTrue(self.wait_for(lambda: orphan.poll() is not None), 'the stale gost must be stopped so the new one can bind')
        finally: daemon.kill(); daemon.wait()

def shutil_which(name):
    import shutil
    return shutil.which(name)
