# [ PURITY SEAL ] An update must verify before it installs, and ask before it changes anything.
import hashlib, importlib.machinery, importlib.util, io, json, os, shutil, subprocess, sys, tarfile, tempfile, unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'bin'))
loader = importlib.machinery.SourceFileLoader('ms_update', str(ROOT / 'bin/ms-update'))
spec = importlib.util.spec_from_loader('ms_update', loader); update = importlib.util.module_from_spec(spec); loader.exec_module(update)

def tar_with(path, members):
    with tarfile.open(path, 'w:gz') as t:
        for name, data in members.items():
            info = tarfile.TarInfo(name); info.size = len(data); t.addfile(info, io.BytesIO(data))

class VersionTests(unittest.TestCase):
    def test_ordering(self):
        self.assertTrue(update.newer('0.1.1', '0.1.0')); self.assertTrue(update.newer('1.0.0', '0.9.9'))
        self.assertFalse(update.newer('0.1.0', '0.1.0')); self.assertFalse(update.newer('0.0.9', '0.1.0'))
    def test_release_beats_its_own_prerelease(self):
        self.assertTrue(update.newer('0.1.0', '0.1.0-beta.1')); self.assertFalse(update.newer('0.1.0-beta.2', '0.1.0'))
    def test_rejects_garbage_tags(self):
        for bad in ('latest', '1.2', '1.2.3; rm -rf /', ''):
            with self.assertRaises(ValueError): update.vkey(bad)

class ArchiveTests(unittest.TestCase):
    def test_checksum_good_bad_and_missing(self):
        with tempfile.TemporaryDirectory() as d:
            d = Path(d); a = d / 'MachineSpirit-1.0.0.tar.gz'; a.write_bytes(b'payload'); sums = d / 'SHA256SUMS'
            sums.write_text(hashlib.sha256(b'payload').hexdigest() + '  ' + a.name + '\n'); update.verify(a, sums)
            sums.write_text('0' * 64 + '  ' + a.name + '\n')
            with self.assertRaisesRegex(ValueError, 'Checksum mismatch'): update.verify(a, sums)
            sums.write_text(hashlib.sha256(b'payload').hexdigest() + '  other.tar.gz\n')
            with self.assertRaisesRegex(ValueError, 'not listed'): update.verify(a, sums)
    def test_extract_refuses_traversal_and_foreign_layout(self):
        with tempfile.TemporaryDirectory() as d:
            d = Path(d)
            for name in ('MachineSpirit/../evil', '/abs/evil', 'Other/file'):
                a = d / 'bad.tar.gz'; tar_with(a, {name: b'x'})
                with self.assertRaisesRegex(ValueError, 'unexpected layout'): update.extract(a, d / 'out')
            self.assertFalse((d / 'evil').exists())
    def test_extract_good_layout(self):
        with tempfile.TemporaryDirectory() as d:
            d = Path(d); a = d / 'ok.tar.gz'; tar_with(a, {'MachineSpirit/VERSION': b'1.0.0\n'})
            self.assertEqual((update.extract(a, d / 'out') / 'VERSION').read_text(), '1.0.0\n')
    def test_download_refuses_other_hosts(self):
        for url in ('https://example.com/a.tar.gz', 'http://github.com/a', 'https://github.com.evil.example/a'):
            with self.assertRaises(ValueError): update.download(url, Path('/nonexistent/out'))

class CommandTests(unittest.TestCase):
    def env(self, d, **extra):
        e = dict(os.environ, HOME=d, XDG_CONFIG_HOME=d + '/c', XDG_DATA_HOME=d + '/d', XDG_STATE_HOME=d + '/s', XDG_CACHE_HOME=d + '/k', PATH='/usr/bin:/bin', MS_UPDATE_NO_RESTART='1')
        e.pop('HYPRLAND_INSTANCE_SIGNATURE', None); e.update(extra); return e
    def run_cmd(self, d, *args, **kw):
        return subprocess.run([sys.executable, str(ROOT / 'bin/ms-update'), *args], env=self.env(d), capture_output=True, text=True, stdin=subprocess.DEVNULL, **kw)
    def test_no_system_update_commands_exist(self):
        with tempfile.TemporaryDirectory() as d:
            for cmd in ('system-count', 'run-system'): self.assertNotEqual(self.run_cmd(d, cmd).returncode, 0)
    def test_status_makes_no_request_and_reports_blocked_until_setup(self):
        with tempfile.TemporaryDirectory() as d:
            r = self.run_cmd(d, 'status'); self.assertEqual(r.returncode, 0, r.stderr)
            data = json.loads(r.stdout); self.assertFalse(data['allowed']); self.assertEqual(data['latest'], '')
    def test_check_refused_in_local_mode_without_touching_the_network(self):
        with tempfile.TemporaryDirectory() as d:
            (Path(d) / 's/machinespirit').mkdir(parents=True); (Path(d) / 's/machinespirit/onboarding.json').write_text('{"version":1}')
            (Path(d) / 'c/machinespirit').mkdir(parents=True); (Path(d) / 'c/machinespirit/settings.json').write_text(json.dumps({'version': 1, 'privacy': {'mode': 'local', 'updates': 'off'}}))
            r = self.run_cmd(d, 'check'); self.assertEqual(r.returncode, 1); self.assertIn('turned off', json.loads(r.stdout)['error'])
            r = self.run_cmd(d, 'install', '--dry-run'); self.assertEqual(r.returncode, 1); self.assertIn('turned off', r.stderr)
    def test_old_settings_without_updates_default_to_on_request(self):
        import ms_privacy
        self.assertEqual(ms_privacy.validate({'mode': 'normal'})['updates'], 'manual')
        with self.assertRaises(ValueError): ms_privacy.validate({'updates': 'sometimes'})

def build_release(d, version=None):
    """Archive made by the real release builder from a copy of the working tree (optionally with another VERSION)."""
    src = Path(d) / 'tree'
    shutil.copytree(ROOT, src, ignore=shutil.ignore_patterns('.git', '.dist', '__pycache__', '*.pyc'))
    if version: (src / 'VERSION').write_text(version + '\n')
    spec = importlib.util.spec_from_file_location('release_builder', src / 'tools/build-release.py'); builder = importlib.util.module_from_spec(spec); spec.loader.exec_module(builder)
    archive, _ = builder.build(src, Path(d) / 'out'); return archive, Path(d) / 'out/SHA256SUMS'

class FullUpdateTests(unittest.TestCase):
    def test_update_from_local_archive_installs_new_version_and_keeps_backups(self):
        with tempfile.TemporaryDirectory(prefix='ms upd ') as d:
            d = Path(d); env = dict(CommandTests().env(str(d)))
            subprocess.run(['bash', str(ROOT / 'install.sh'), '--components', 'shell', '--no-packages', '--no-system', '--yes'], env=env, check=True, capture_output=True)
            version_file = d / 'd/machinespirit/VERSION'; old = version_file.read_text().strip(); self.assertEqual(old, (ROOT / 'VERSION').read_text().strip())
            archive, sums = build_release(d, '9.9.9')   # the real packaging, not a copy of the whole tree
            cmd = [sys.executable, str(ROOT / 'bin/ms-update'), 'install', '--from-file', str(archive), '--no-packages', '--no-system']
            dry = subprocess.run(cmd + ['--dry-run'], env=env, capture_output=True, text=True, stdin=subprocess.DEVNULL)
            self.assertEqual(dry.returncode, 0, dry.stderr + dry.stdout); self.assertIn('Checksum matches', dry.stdout); self.assertIn('integrity only', dry.stdout); self.assertEqual(version_file.read_text().strip(), old)
            declined = subprocess.run(cmd, env=env, capture_output=True, text=True, input='n\n')
            self.assertEqual(declined.returncode, 0); self.assertIn('Nothing was changed', declined.stdout); self.assertEqual(version_file.read_text().strip(), old)
            done = subprocess.run(cmd + ['--yes'], env=env, capture_output=True, text=True, stdin=subprocess.DEVNULL)
            self.assertEqual(done.returncode, 0, done.stderr + done.stdout); self.assertEqual(version_file.read_text().strip(), '9.9.9')
            again = subprocess.run(cmd + ['--yes'], env=env, capture_output=True, text=True, stdin=subprocess.DEVNULL)
            self.assertIn('already have this version', again.stdout)
            sums.write_text('0' * 64 + '  ' + archive.name + '\n')
            bad = subprocess.run(cmd + ['--yes', '--force'], env=env, capture_output=True, text=True, stdin=subprocess.DEVNULL)
            self.assertNotEqual(bad.returncode, 0); self.assertIn('Checksum mismatch', bad.stderr)
def tar_entries(path, entries):
    """entries: name -> bytes, or (TarInfo type, mode, bytes/linkname) for special members."""
    with tarfile.open(path, 'w:gz') as t:
        for name, spec in entries.items():
            info = tarfile.TarInfo(name)
            if isinstance(spec, tuple):
                kind, mode, extra = spec; info.type = kind; info.mode = mode
                if kind in (tarfile.SYMTYPE, tarfile.LNKTYPE): info.linkname = extra; t.addfile(info)
                elif kind == tarfile.REGTYPE: info.size = len(extra); t.addfile(info, io.BytesIO(extra))
                else: t.addfile(info)
            else: info.size = len(spec); t.addfile(info, io.BytesIO(spec))

class HardenedExtractionTests(unittest.TestCase):
    def reject(self, entries, d):
        a = Path(d) / 'bad.tar.gz'; tar_entries(a, entries)
        with self.assertRaisesRegex(ValueError, 'unexpected|larger'): update.extract(a, Path(d) / 'out')
        self.assertFalse((Path(d) / 'out/MachineSpirit').exists() and any((Path(d) / 'out/MachineSpirit').rglob('*')), 'nothing may be unpacked from a rejected archive')
    def test_rejects_symlink_hardlink_fifo_and_device(self):
        with tempfile.TemporaryDirectory() as d:
            self.reject({'MachineSpirit/VERSION': b'1\n', 'MachineSpirit/link': (tarfile.SYMTYPE, 0o777, '/etc/passwd')}, d)
            self.reject({'MachineSpirit/VERSION': b'1\n', 'MachineSpirit/hard': (tarfile.LNKTYPE, 0o644, 'MachineSpirit/VERSION')}, d)
            self.reject({'MachineSpirit/pipe': (tarfile.FIFOTYPE, 0o644, b'')}, d)
            self.reject({'MachineSpirit/dev': (tarfile.CHRTYPE, 0o644, b'')}, d)
    def test_rejects_duplicates_odd_names_and_too_many_entries(self):
        with tempfile.TemporaryDirectory() as d:
            a = Path(d) / 'dup.tar.gz'
            with tarfile.open(a, 'w:gz') as t:
                for _ in range(2):
                    info = tarfile.TarInfo('MachineSpirit/VERSION'); info.size = 2; t.addfile(info, io.BytesIO(b'1\n'))
            with self.assertRaisesRegex(ValueError, 'unexpected'): update.extract(a, Path(d) / 'o1')
            for name in ('MachineSpirit//x', 'MachineSpirit/./x', 'MachineSpirit/a\\b', 'MachineSpirit/' + 'x' * 600):
                self.reject({name: b'x'}, d)
            old = update.MAX_MEMBERS; update.MAX_MEMBERS = 3
            try: self.reject({f'MachineSpirit/f{i}': b'x' for i in range(5)}, d)
            finally: update.MAX_MEMBERS = old
    def test_size_limits(self):
        with tempfile.TemporaryDirectory() as d:
            old = update.MAX_TOTAL, update.MAX_FILE
            try:
                update.MAX_TOTAL = 10; self.reject({'MachineSpirit/a': b'x' * 6, 'MachineSpirit/b': b'x' * 6}, d)
                update.MAX_TOTAL, update.MAX_FILE = old[0], 4; self.reject({'MachineSpirit/a': b'x' * 6}, d)
            finally: update.MAX_TOTAL, update.MAX_FILE = old
    def test_special_mode_bits_are_dropped(self):
        with tempfile.TemporaryDirectory() as d:
            a = Path(d) / 'ok.tar.gz'
            tar_entries(a, {'MachineSpirit/run': (tarfile.REGTYPE, 0o6777, b'#!/bin/sh\n'), 'MachineSpirit/doc': (tarfile.REGTYPE, 0o666, b'x')})
            root = update.extract(a, Path(d) / 'out')
            self.assertEqual((root / 'run').stat().st_mode & 0o7777, 0o755); self.assertEqual((root / 'doc').stat().st_mode & 0o7777, 0o644)

class ChecksumFileTests(unittest.TestCase):
    def check(self, body, content=b'payload'):
        with tempfile.TemporaryDirectory() as d:
            a = Path(d) / 'MachineSpirit-1.0.0.tar.gz'; a.write_bytes(content); s = Path(d) / 'SHA256SUMS'
            s.write_text(body.replace('{h}', hashlib.sha256(content).hexdigest()).replace('{n}', a.name)); update.verify(a, s)
    def test_accepts_star_prefix_uppercase_and_identical_duplicates(self):
        self.check('{h}  {n}\n'); self.check('{h} *{n}\n'); self.check('{h}  {n}\n{h}  {n}\n')
        with tempfile.TemporaryDirectory() as d:
            a = Path(d) / 'MachineSpirit-1.0.0.tar.gz'; a.write_bytes(b'p'); s = Path(d) / 'S'; s.write_text(hashlib.sha256(b'p').hexdigest().upper() + '  ' + a.name + '\n'); update.verify(a, s)
    def test_rejects_empty_conflicting_and_malformed(self):
        for body, pattern in (('', 'not listed'), ('\n\n', 'not listed'), ('{h}  {n}\n' + '1' * 64 + '  {n}\n', 'different values'),
                              ('zz' * 32 + '  {n}\n', 'invalid SHA-256'), ('abc  {n}\n', 'invalid SHA-256')):
            with self.subTest(body=body[:20]), self.assertRaisesRegex(ValueError, pattern): self.check(body)

class UntrustedTextTests(unittest.TestCase):
    def test_terminal_controls_are_removed(self):
        text = 'ok\x1b]0;evil title\x07\x1b[2K\x1b[1Aline\r\nnext\ttab\x9b'
        out = update.clean(text); self.assertNotIn('\x1b', out); self.assertNotIn('\x07', out); self.assertNotIn('\r', out); self.assertIn('\n', out); self.assertIn('\t', out)
    def test_changelog_only_for_the_matching_version_and_sanitised(self):
        with tempfile.TemporaryDirectory() as d:
            (Path(d) / 'CHANGELOG.md').write_text('# Changelog\n\n## 2.0.0 - today\n\n- fix\x1b[2K\n\n## 1.0.0\n- old\n')
            self.assertIn('fix', update.changelog_top(Path(d), '2.0.0')); self.assertNotIn('\x1b', update.changelog_top(Path(d), '2.0.0'))
            self.assertEqual(update.changelog_top(Path(d), '3.0.0'), '')

class MalformedReleaseTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(); d = Path(self.tmp.name)
        self.saved = (update.CACHE_FILE, update.DATA, update.allowed, update.fetch, update.INSTALL_STATE)
        update.CACHE_FILE, update.DATA, update.INSTALL_STATE = d / 'update.json', d / 'data', d / 'install'
        update.allowed = lambda *a, **k: True
    def tearDown(self):
        update.CACHE_FILE, update.DATA, update.allowed, update.fetch, update.INSTALL_STATE = self.saved; self.tmp.cleanup()
    def test_unexpected_json_shapes_give_a_clean_error_not_a_crash(self):
        for body in ('[]', '"text"', '{"tag_name": "latest"}', '{"tag_name": "1.2.3", "assets": "x"}', '{"tag_name": "1.2.3", "assets": [1, null, {"name": 5}]}'):
            update.fetch = lambda *a, _b=body, **k: _b
            with self.subTest(body=body):
                try: update.check()
                except ValueError: pass   # a clean refusal is fine; a traceback is not
        self.assertIsInstance(update.cache(), dict)
    def test_damaged_cache_does_not_break_status(self):
        for body in ('[]', '{"latest": "not-a-version"}', '{"checked": "yesterday", "latest": 7}'):
            update.CACHE_FILE.write_text(body); s = update.status(); self.assertFalse(s['newer']); self.assertIsInstance(s['checked'], (int, float))
    def test_hostile_assets_are_dropped(self):
        update.fetch = lambda *a, **k: json.dumps({'tag_name': 'v1.2.3', 'body': 'x\x1b[2Ky', 'assets': [
            {'name': 'MachineSpirit-1.2.3.tar.gz', 'browser_download_url': 'https://github.com/o/r/releases/download/v1.2.3/MachineSpirit-1.2.3.tar.gz'},
            {'name': 'evil', 'browser_download_url': 'https://evil.example/x'}, {'name': 'http', 'browser_download_url': 'http://github.com/x'}]})
        update.check(); c = update.cache(); self.assertEqual(list(c['assets']), ['MachineSpirit-1.2.3.tar.gz']); self.assertNotIn('\x1b', c['notes'])

class VersionAgreementTests(unittest.TestCase):
    """The release tag, the archive name and the VERSION inside must all agree, or nothing is installed."""
    def make(self, d, name_version, inner_version):
        n = 0
        while (Path(d) / f'pkg{n}').exists(): n += 1
        src = Path(d) / f'pkg{n}' / 'MachineSpirit'; src.mkdir(parents=True)
        (src / 'VERSION').write_text(inner_version + '\n'); (src / 'install.sh').write_text('#!/bin/sh\nexit 0\n'); (src / 'CHANGELOG.md').write_text(f'## {inner_version}\n- x\n')
        archive = Path(d) / f'MachineSpirit-{name_version}.tar.gz'
        with tarfile.open(archive, 'w:gz') as t: t.add(src, arcname='MachineSpirit')
        sums = Path(d) / 'SHA256SUMS'; sums.write_text(hashlib.sha256(archive.read_bytes()).hexdigest() + '  ' + archive.name + '\n'); return archive
    def run_install(self, d, archive, installed=None, **extra):
        env = CommandTests().env(d)
        if installed: (Path(d) / 'd/machinespirit').mkdir(parents=True, exist_ok=True); (Path(d) / 'd/machinespirit/VERSION').write_text(installed + '\n')
        cmd = [sys.executable, str(ROOT / 'bin/ms-update'), 'install', '--from-file', str(archive), '--no-packages', '--no-system', *extra.get('args', [])]
        return subprocess.run(cmd, env=env, capture_output=True, text=True, stdin=subprocess.DEVNULL)
    def test_name_and_inner_version_disagree(self):
        with tempfile.TemporaryDirectory() as d:
            r = self.run_install(d, self.make(d, '2.0.0', '3.0.0'), '1.0.0', args=['--yes'])
            self.assertNotEqual(r.returncode, 0); self.assertIn('disagree', r.stderr)
    def test_tag_and_inner_version_disagree_on_the_network_path(self):
        saved = (update.CACHE_FILE, update.DATA, update.allowed, update.download, update.INSTALL_STATE)
        with tempfile.TemporaryDirectory() as d:
            archive = self.make(d, '2.0.0', '2.0.1')   # name says 2.0.0, content says 2.0.1: the name check fires first
            update.CACHE_FILE, update.DATA, update.INSTALL_STATE = Path(d) / 'u.json', Path(d) / 'data', Path(d) / 'i'
            update.allowed = lambda *a, **k: True
            update.CACHE_FILE.write_text(json.dumps({'latest': '2.0.0', 'assets': {'MachineSpirit-2.0.0.tar.gz': 'https://github.com/x/a', 'SHA256SUMS': 'https://github.com/x/s'}}))
            update.download = lambda url, dest: shutil.copy(archive if url.endswith('/a') else Path(d) / 'SHA256SUMS', dest)
            ns = type('N', (), dict(from_file=None, sums=None, yes=True, dry_run=False, force=False, no_packages=True, no_system=True))()
            try:
                with self.assertRaisesRegex(ValueError, 'disagree'): update.install(ns)
                good = self.make(d, '2.0.0', '2.0.0'); (Path(d) / 'MachineSpirit-2.0.0.tar.gz').write_bytes(good.read_bytes())
                update.CACHE_FILE.write_text(json.dumps({'latest': '2.0.9', 'assets': {'MachineSpirit-2.0.9.tar.gz': 'https://github.com/x/a', 'SHA256SUMS': 'https://github.com/x/s'}}))
                a29 = Path(d) / 'MachineSpirit-2.0.9.tar.gz'; shutil.copy(good, a29)
                (Path(d) / 'SHA256SUMS').write_text(hashlib.sha256(a29.read_bytes()).hexdigest() + '  ' + a29.name + '\n')
                update.download = lambda url, dest: shutil.copy(a29 if url.endswith('/a') else Path(d) / 'SHA256SUMS', dest)
                with self.assertRaisesRegex(ValueError, 'disagree|tagged'): update.install(ns)   # tag 2.0.9, archive named 2.0.9 but VERSION 2.0.0
            finally: update.CACHE_FILE, update.DATA, update.allowed, update.download, update.INSTALL_STATE = saved
    def test_downgrade_needs_force_and_an_explicit_answer(self):
        with tempfile.TemporaryDirectory() as d:
            archive = self.make(d, '1.0.0', '1.0.0')
            r = self.run_install(d, archive, '2.0.0'); self.assertIn('already have', r.stdout)
            r = self.run_install(d, archive, '2.0.0', args=['--force', '--yes']); self.assertIn('DOWNGRADE', r.stdout); self.assertIn('Nothing was changed', r.stdout)
            self.assertEqual((Path(d) / 'd/machinespirit/VERSION').read_text().strip(), '2.0.0')
    def test_real_sized_release_passes_the_extraction_limits(self):
        with tempfile.TemporaryDirectory() as d:
            d = Path(d); archive, _ = build_release(d)
            root = update.extract(archive, d / 'unpacked'); self.assertTrue((root / 'install.sh').is_file()); self.assertTrue((root / 'bin/ms-update').is_file())
            n = sum(1 for _ in root.rglob('*')); self.assertLess(n, update.MAX_MEMBERS // 5, 'a real release must sit far below the limit')

class BootRecordTests(unittest.TestCase):
    def test_update_keeps_boot_recorded_without_touching_it(self):
        with tempfile.TemporaryDirectory() as d:
            env = CommandTests().env(d); state = Path(d) / 's/machinespirit/install'
            subprocess.run(['bash', str(ROOT / 'install.sh'), '--components', 'shell', '--no-packages', '--no-system', '--yes'], env=env, check=True, capture_output=True)
            (state / 'components.json').write_text('["boot", "shell"]')   # as left by an earlier full installation
            subprocess.run(['bash', str(ROOT / 'install.sh'), 'update', '--components', 'shell', '--no-packages', '--no-system', '--yes'], env=env, check=True, capture_output=True)
            self.assertEqual(json.loads((state / 'components.json').read_text()), ['boot', 'shell'])
if __name__ == '__main__': unittest.main()
