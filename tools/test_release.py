# [ PURITY SEAL ] Prove preservation, not merely success messages.
import importlib.machinery, importlib.util, json, os, subprocess, sys, tempfile, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def load(name,path):
    loader=importlib.machinery.SourceFileLoader(name,str(path)); spec=importlib.util.spec_from_loader(name,loader); m=importlib.util.module_from_spec(spec);loader.exec_module(m);return m
settings=load('settings',ROOT/'bin/ms-settings')
class SettingsTests(unittest.TestCase):
    def test_modifier_order_conflict(self):
        with self.assertRaises(ValueError): settings.validate({'version':1,'bindings':{'SUPER + E':'CTRL + SUPER + E','SUPER + W':'SUPER + CONTROL + E'}})
    def test_defaults_english(self): self.assertEqual(settings.validate({'version':1})['layouts'],['us'])
    def test_old_settings_receive_input_and_appearance_defaults(self):
        data = settings.validate({'version':1,'layouts':['us','ru'],'bindings':{'SUPER + E':'SUPER + ALT + E'}})
        self.assertEqual(data['rounding'],14)
        self.assertEqual(data['repeatRate'],25)
        self.assertEqual(data['bindings'],{'SUPER + E':'SUPER + ALT + E'})
    def test_input_and_appearance_reject_unsafe_values(self):
        for patch in [{'rounding':31},{'gapsIn':-1},{'borderSize':0},{'sensitivity':float('nan')},
                      {'sensitivity':True},{'dimStrength':float('inf')},{'repeatDelay':0},
                      {'repeatRate':True},{'accelProfile':'bad'},{'tapToClick':1},{'layouts':['us','us']}]:
            with self.subTest(patch=patch), self.assertRaises(ValueError):
                settings.validate(dict(version=1,**patch))
    def test_preferences_persist_and_generate_compositor_options(self):
        with tempfile.TemporaryDirectory() as d:
            env=dict(os.environ,HOME=d,XDG_CONFIG_HOME=d+'/config',XDG_STATE_HOME=d+'/state');env.pop('HYPRLAND_INSTANCE_SIGNATURE',None)
            patch=dict(version=1,rounding=8,gapsIn=3,gapsOut=9,borderSize=1,sensitivity=-.25,
                       accelProfile='flat',tapToClick=False,repeatRate=45,repeatDelay=350,lowPower=True)
            result=subprocess.run([sys.executable,str(ROOT/'bin/ms-settings'),'write'],input=json.dumps(patch),text=True,env=env,capture_output=True)
            self.assertEqual(result.returncode,0,result.stdout)
            saved=json.loads((Path(d)/'config/machinespirit/settings.json').read_text())
            for key,value in patch.items(): self.assertEqual(saved[key],value)
            generated=(Path(d)/'config/machinespirit/generated.lua').read_text()
            for value in ['["rounding"]=8','["gaps_in"]=3','["sensitivity"]=-0.25','["tap_to_click"]=false','["repeat_delay"]=350']:
                self.assertIn(value,generated)
            self.assertIn('["shadow"]={["enabled"]=false}',generated)
    def test_reject_injection(self):
        for patch in [{'layouts':['us; touch /tmp/bad']},{'monitors':[{'output':'X','mode':'1;bad'}]},{'bindings':{'SUPER + E':'$(bad)'}},{'version':2}]:
            with self.assertRaises(ValueError): settings.validate(dict(version=1,**{k:v for k,v in patch.items() if k!='version'}) if 'version' not in patch else patch)
    def test_no_blackout(self):
        with self.assertRaises(ValueError): settings.validate({'version':1,'monitors':[{'output':'X','disabled':True}]})
    def test_timeouts(self):
        with self.assertRaises(ValueError): settings.validate({'version':1,'lockSeconds':900,'screenOffSeconds':600})
    def test_invalid_config_not_overwritten(self):
        with tempfile.TemporaryDirectory() as d:
            env=dict(os.environ,HOME=d,XDG_CONFIG_HOME=d+'/config',XDG_STATE_HOME=d+'/state')
            p=Path(d)/'config/machinespirit/settings.json';p.parent.mkdir(parents=True);p.write_text('{broken')
            r=subprocess.run([sys.executable,str(ROOT/'bin/ms-settings'),'generate'],env=env,capture_output=True)
            self.assertNotEqual(r.returncode,0);self.assertEqual(p.read_text(),'{broken')
    def test_settings_roundtrip(self):
        with tempfile.TemporaryDirectory(prefix='ms test ') as d:
            env=dict(os.environ,HOME=d,XDG_CONFIG_HOME=d+'/config',XDG_STATE_HOME=d+'/state');env.pop('HYPRLAND_INSTANCE_SIGNATURE',None)
            payload=dict(settings.DEFAULT,layouts=['us','ru'],primaryOutput='DP-1')
            r=subprocess.run([sys.executable,str(ROOT/'bin/ms-settings'),'write'],input=json.dumps(payload),text=True,env=env,capture_output=True)
            self.assertEqual(r.returncode,0,r.stdout)
            generated=(Path(d)/'config/machinespirit/generated.lua').read_text();self.assertIn('us,ru',generated)
class TransactionTests(unittest.TestCase):
    def test_theme_rollback(self):
        managed=load('managed',ROOT/'tools/managed.py')
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'original';p.write_text('user data');new=Path(d)/'new'
            with self.assertRaises(RuntimeError):
                with managed.transaction([p,new],Path(d)/'state'):
                    p.write_text('bad');new.write_text('new');raise RuntimeError('simulated failure')
            self.assertEqual(p.read_text(),'user data');self.assertFalse(new.exists())
    def test_installer_restore_symlink(self):
        installer=load('installer',ROOT/'installer/install.py')
        with tempfile.TemporaryDirectory() as d:
            d=Path(d);target=d/'target';target.write_text('untouched');dst=d/'link';dst.symlink_to('target')
            tx=d/'tx';tx.mkdir();installer.copy_file(dst,tx/'original')
            source=d/'source';source.write_text('installed');installer.copy_file(source,dst)
            (tx/'manifest.json').write_text(json.dumps({'files':[{'dest':str(dst),'backup':'original','installed':installer.fingerprint(dst)}]}))
            installer.restore(tx);self.assertTrue(dst.is_symlink());self.assertEqual(target.read_text(),'untouched')
    def test_restore_preserves_user_edits(self):
        installer=load('installer2',ROOT/'installer/install.py')
        with tempfile.TemporaryDirectory() as d:
            d=Path(d);dst=d/'file';dst.write_text('user edit');tx=d/'tx';tx.mkdir()
            (tx/'manifest.json').write_text(json.dumps({'files':[{'dest':str(dst),'backup':None,'installed':'otherhash'}]}))
            installer.restore(tx);self.assertEqual(dst.read_text(),'user edit')
    def test_restore_continues_after_a_failed_file_and_reports_it(self):
        installer=load('installer3',ROOT/'installer/install.py')
        with tempfile.TemporaryDirectory() as d:
            d=Path(d);tx=d/'tx';tx.mkdir();good=d/'good';good.write_text('installed');bad=d/'bad';bad.write_text('installed')
            entries=[{'dest':str(good),'backup':None,'installed':installer.fingerprint(good)},
                     {'dest':str(bad),'backup':'backup/missing','installed':installer.fingerprint(bad)}]
            (tx/'manifest.json').write_text(json.dumps({'files':entries}))
            failed=installer.restore(tx)
            self.assertEqual(failed,[bad]);self.assertFalse(good.exists())
class ReleaseConsistencyTests(unittest.TestCase):
    def test_version_matches_changelog_and_banner(self):
        version=(ROOT/'VERSION').read_text().strip()
        self.assertRegex(version,r'^\d+\.\d+\.\d+$',version)
        self.assertRegex((ROOT/'CHANGELOG.md').read_text().split('## ',2)[1],'^'+version.replace('.',r'\.')+r'\b')
        self.assertIn(version,(ROOT/'docs/media/banner.svg').read_text())
        for readme in ('README.md','README.ru.md'): self.assertNotIn('beta',(ROOT/readme).read_text().lower().split('\n',12)[7])
    def test_package_list_matches_components(self):
        wanted={p for c in json.loads((ROOT/'installer/components.json').read_text()).values() for p in c['packages']}
        listed={l.strip() for l in (ROOT/'packages.txt').read_text().splitlines() if l.strip() and not l.startswith('#')}
        self.assertEqual(listed,wanted)
class SettingsRecoveryTests(unittest.TestCase):
    def env(self,d): return dict(os.environ,HOME=d,XDG_CONFIG_HOME=d+'/config',XDG_STATE_HOME=d+'/state',HYPRLAND_INSTANCE_SIGNATURE='')
    def test_corrupt_settings_error_explains_recovery_and_keeps_file(self):
        with tempfile.TemporaryDirectory() as d:
            f=Path(d)/'config/machinespirit/settings.json';f.parent.mkdir(parents=True);f.write_text('{broken')
            r=subprocess.run([sys.executable,str(ROOT/'bin/ms-settings'),'read'],env=self.env(d),capture_output=True,text=True)
            self.assertNotEqual(r.returncode,0);self.assertIn('rename or delete it',json.loads(r.stdout)['error']);self.assertEqual(f.read_text(),'{broken')
    def test_stale_watchdog_does_not_revert_newer_preview(self):
        with tempfile.TemporaryDirectory() as d:
            env=self.env(d);state=Path(d)/'state/machinespirit/install'
            pending=Path(d)/'state/machinespirit/settings-preview.json'
            run=lambda *a:subprocess.run([sys.executable,'-c','import sys,importlib.machinery as m,importlib.util as u;l=m.SourceFileLoader("s",sys.argv[1]);s=u.spec_from_loader("s",l);x=u.module_from_spec(s);l.exec_module(x);x.rollback(sys.argv[2])',str(ROOT/'bin/ms-settings'),*a],env=env,capture_output=True,text=True)
            old=settings.copy.deepcopy(settings.DEFAULT);old['rounding']=3
            pending.parent.mkdir(parents=True);pending.write_text(json.dumps({'old':old,'id':'new'}))
            self.assertEqual(run('stale').returncode,0);self.assertTrue(pending.exists())
            self.assertEqual(run('new').returncode,0);self.assertFalse(pending.exists())
class InstallerArgumentTests(unittest.TestCase):
    def test_full_install_skips_boot_without_explicit_consent(self):
        with tempfile.TemporaryDirectory() as d:
            fs=Path(d)/'fs'   # the login component looks at the machine's SDDM and sessions: give it a disposable one
            for rel in ('usr/share/wayland-sessions/hyprland.desktop','usr/bin/sddm'): (fs/rel).parent.mkdir(parents=True,exist_ok=True);(fs/rel).write_text('')
            (fs/'usr/lib/qt6/qml/QtQuick').mkdir(parents=True)
            env=dict(os.environ,HOME=d,XDG_CONFIG_HOME=d+'/c',XDG_DATA_HOME=d+'/d',XDG_STATE_HOME=d+'/s',MS_LOGIN_ROOT=str(fs))
            r=subprocess.run([sys.executable,str(ROOT/'installer/install.py'),'--full','--yes','--dry-run'],env=env,capture_output=True,text=True,stdin=subprocess.DEVNULL)
            self.assertEqual(r.returncode,0,r.stderr);self.assertIn('Boot theme skipped',r.stdout);self.assertIn('login',r.stdout.split('Components:')[1].split('\n')[0])
            self.assertNotIn('boot',[c.strip() for c in r.stdout.split('Components:')[1].split('\n')[0].split(',')])
class UpdateKeepsBootTests(unittest.TestCase):
    def test_a_plain_update_does_not_pull_the_boot_theme_back_in(self):
        """The login component adds a display manager, which the boot check refuses; an update must not touch boot anyway."""
        with tempfile.TemporaryDirectory() as d:
            (Path(d)/'s/machinespirit').mkdir(parents=True); (Path(d)/'s/machinespirit/install').mkdir(parents=True)
            (Path(d)/'s/machinespirit/install/components.json').write_text(json.dumps(['shell','boot']))
            env=dict(os.environ,HOME=d,XDG_CONFIG_HOME=d+'/c',XDG_DATA_HOME=d+'/d',XDG_STATE_HOME=d+'/s')
            r=subprocess.run([sys.executable,str(ROOT/'installer/install.py'),'update','--dry-run','--yes'],env=env,capture_output=True,text=True,stdin=subprocess.DEVNULL)
            self.assertEqual(r.returncode,0,r.stderr);self.assertIn('not touched by an update',r.stdout)
            self.assertNotIn('boot',r.stdout.split('Components:')[1].split('\n')[0])
class LifecycleTests(unittest.TestCase):
    """Files that disappear from a release, empty updates and interrupted installations, in a disposable HOME."""
    @classmethod
    def setUpClass(cls):
        import shutil
        cls.tmp = tempfile.TemporaryDirectory(prefix='ms life ')
        base = Path(cls.tmp.name)
        def tree(name, extra):
            dst = base / name / 'MachineSpirit'
            shutil.copytree(ROOT, dst, ignore=shutil.ignore_patterns('.git', '.dist', '__pycache__', '*.pyc', 'wallpapers-local'))
            for rel, text in extra.items(): (dst / rel).parent.mkdir(parents=True, exist_ok=True); (dst / rel).write_text(text)
            return dst
        cls.old = tree('old', {'quickshell/common/GoneType.qml': 'import QtQuick\nItem{}\n', 'quickshell/common/KeptType.qml': 'import QtQuick\nItem{}\n',
                               'quickshell/common/ModType.qml': 'import QtQuick\nItem{}\n', 'kitty/gone.conf': 'font_size 11\n'})
        cls.new = tree('new', {'quickshell/common/UsesKept.qml': 'import QtQuick\nItem { KeptType {} }\n'})
    @classmethod
    def tearDownClass(cls): cls.tmp.cleanup()
    def home(self):
        d = tempfile.mkdtemp(dir=self.tmp.name)
        self.env = dict(os.environ, HOME=d, XDG_CONFIG_HOME=d + '/c', XDG_DATA_HOME=d + '/d', XDG_STATE_HOME=d + '/s', PATH='/usr/bin:/bin'); self.env.pop('HYPRLAND_INSTANCE_SIGNATURE', None)
        self.d = Path(d); self.state = self.d / 's/machinespirit/install'; return self.d
    def run_install(self, tree, *args):
        return subprocess.run(['bash', str(tree / 'install.sh'), *args, '--no-packages', '--no-system', '--yes'], env=self.env, capture_output=True, text=True, stdin=subprocess.DEVNULL)
    def records(self): return sorted(p.name for p in self.state.iterdir() if p.is_dir()) if self.state.exists() else []

    def test_update_without_changes_leaves_no_new_record(self):
        self.home(); self.assertEqual(self.run_install(self.new, '--components', 'shell').returncode, 0)
        before = self.records(); r = self.run_install(self.new, 'update', '--components', 'shell')
        self.assertEqual(r.returncode, 0, r.stderr); self.assertIn('Already up to date', r.stdout); self.assertEqual(self.records(), before)
    def test_unchanged_theme_transaction_leaves_no_record(self):
        managed = load('managed_t', ROOT / 'tools/managed.py'); d = Path(tempfile.mkdtemp(dir=self.tmp.name)); f = d / 'f'; f.write_text('same')
        with managed.transaction([f], d / 'state'): pass
        self.assertEqual([p for p in (d / 'state/install').iterdir()], [])
        with managed.transaction([f], d / 'state'): f.write_text('changed')
        self.assertEqual(len(list((d / 'state/install').iterdir())), 1)

    def test_stale_files_removed_only_with_proof(self):
        d = self.home(); config = d / 'c/quickshell/machinespirit/common'; kitty = d / 'c/kitty/gone.conf'
        r = self.run_install(self.old, '--components', 'shell,terminal'); self.assertEqual(r.returncode, 0, r.stderr)
        for name in ('GoneType', 'KeptType', 'ModType'): self.assertTrue((config / f'{name}.qml').is_file())
        (config / 'ModType.qml').write_text('// my edit\n')
        r = self.run_install(self.new, 'update', '--components', 'shell'); self.assertEqual(r.returncode, 0, r.stderr)
        self.assertFalse((config / 'GoneType.qml').exists(), 'unchanged, owned, unreferenced: removed')
        self.assertIn('Removed file no longer part of MachineSpirit', r.stdout)
        self.assertTrue((config / 'KeptType.qml').exists()); self.assertIn('still referenced', r.stdout)
        self.assertEqual((config / 'ModType.qml').read_text(), '// my edit\n'); self.assertIn('Kept stale file you modified', r.stdout)
        self.assertTrue(kitty.exists(), 'a component that was not selected must not be touched')
        r = self.run_install(self.new, 'update', '--components', 'shell,terminal'); self.assertEqual(r.returncode, 0, r.stderr)
        self.assertFalse(kitty.exists())
    def test_stale_removal_survives_uninstall_restore_and_reinstall(self):
        d = self.home(); config = d / 'c/quickshell/machinespirit/common'
        self.assertEqual(self.run_install(self.old, '--components', 'shell').returncode, 0)
        self.assertEqual(self.run_install(self.new, 'update', '--components', 'shell').returncode, 0); self.assertFalse((config / 'GoneType.qml').exists())
        r = subprocess.run(['bash', str(self.new / 'install.sh'), 'uninstall', '--no-system', '--yes'], env=self.env, capture_output=True, text=True, stdin=subprocess.DEVNULL)
        self.assertEqual(r.returncode, 0, r.stderr); self.assertFalse((config / 'GoneType.qml').exists(), 'uninstall must not bring a removed file back')
        r = self.run_install(self.new, '--components', 'shell'); self.assertEqual(r.returncode, 0, r.stderr); self.assertTrue((config / 'UsesKept.qml').exists())
    def test_files_outside_the_records_are_never_removed(self):
        d = self.home(); self.assertEqual(self.run_install(self.new, '--components', 'shell').returncode, 0)
        mine = d / 'c/quickshell/machinespirit/common/MyOwn.qml'; mine.write_text('// not from MachineSpirit\n')
        self.assertEqual(self.run_install(self.new, 'update', '--components', 'shell').returncode, 0); self.assertTrue(mine.exists())

    def interrupted(self, pid, started, name_pid=None, files=True):
        """Write the record an installation killed half-way leaves behind, plus the file it had already replaced."""
        target = self.d / 'c/half.txt'; target.parent.mkdir(parents=True, exist_ok=True); target.write_text('NEW from the crashed run')
        tx = self.state / f'20200101-000000-{name_pid or pid}'; (tx / 'backup').mkdir(parents=True); (tx / 'backup/0').write_text('ORIGINAL')
        manifest = {'version': 1, 'status': 'applying', 'files': [{'dest': str(target), 'backup': 'backup/0', 'installed': load('inst_fp', ROOT / 'installer/install.py').fingerprint(target), 'component': 'shell'}]}
        if pid is not None: manifest['pid'] = pid; manifest['started'] = started
        (tx / 'manifest.json').write_text(json.dumps(manifest)); return tx, target
    def status(self, tx): return json.loads((tx / 'manifest.json').read_text())['status']
    def test_dead_writer_is_recovered_and_originals_return(self):
        self.home(); self.assertEqual(self.run_install(self.new, '--components', 'shell').returncode, 0)
        p = subprocess.Popen(['true']); p.wait(); tx, target = self.interrupted(p.pid, 1)
        r = self.run_install(self.new, 'update', '--components', 'shell'); self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('Recovering', r.stdout); self.assertEqual(target.read_text(), 'ORIGINAL'); self.assertEqual(self.status(tx), 'rolled-back')
    def test_live_writer_is_left_alone(self):
        self.home(); self.assertEqual(self.run_install(self.new, '--components', 'shell').returncode, 0)
        me = os.getpid(); tx, target = self.interrupted(me, installer_start(me))
        r = self.run_install(self.new, 'update', '--components', 'shell'); self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('alone', r.stdout); self.assertEqual(target.read_text(), 'NEW from the crashed run'); self.assertEqual(self.status(tx), 'applying')
    def test_reused_pid_counts_as_dead_but_unknown_owner_is_kept(self):
        self.home(); self.assertEqual(self.run_install(self.new, '--components', 'shell').returncode, 0)
        tx, target = self.interrupted(os.getpid(), 1)   # same pid, different start time: that process is not the writer
        self.assertEqual(self.run_install(self.new, 'update', '--components', 'shell').returncode, 0); self.assertEqual(target.read_text(), 'ORIGINAL')
        self.home(); self.assertEqual(self.run_install(self.new, '--components', 'shell').returncode, 0)
        tx, target = self.interrupted(None, None, name_pid='not-a-pid')   # owner cannot be determined at all
        self.assertEqual(self.run_install(self.new, 'update', '--components', 'shell').returncode, 0); self.assertEqual(target.read_text(), 'NEW from the crashed run'); self.assertEqual(self.status(tx), 'applying')
    def test_doctor_tells_active_from_interrupted(self):
        self.home(); self.assertEqual(self.run_install(self.new, '--components', 'shell').returncode, 0)
        me = os.getpid(); self.interrupted(me, installer_start(me))
        r = subprocess.run([sys.executable, str(self.new / 'installer/install.py'), 'doctor'], env=self.env, capture_output=True, text=True)
        self.assertIn('still running', r.stdout)
    def test_explicit_restore_closes_an_unfinished_record(self):
        self.home(); self.assertEqual(self.run_install(self.new, '--components', 'shell').returncode, 0)
        me = os.getpid(); tx, target = self.interrupted(me, installer_start(me))
        r = subprocess.run(['bash', str(self.new / 'install.sh'), 'restore', tx.name], env=self.env, capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr); self.assertEqual(target.read_text(), 'ORIGINAL'); self.assertEqual(self.status(tx), 'rolled-back')

def installer_start(pid):
    return int(Path(f'/proc/{pid}/stat').read_text().rsplit(')', 1)[1].split()[19])
class ReleaseArchiveTests(unittest.TestCase):
    def test_private_and_generated_files_stay_out_of_the_archive(self):
        import shutil, tarfile
        with tempfile.TemporaryDirectory() as d:
            repo = Path(d) / 'repo'
            shutil.copytree(ROOT, repo, ignore=shutil.ignore_patterns('.git', '.dist', '__pycache__', '*.pyc'))
            (repo / 'wallpapers-local').mkdir(exist_ok=True); (repo / 'wallpapers-local/private.png').write_bytes(b'x')
            (repo / 'hypr/local.lua').write_text('-- mine\n'); (repo / 'bin/keys.conf').write_text('secret=1\n'); (repo / 'bin/__pycache__').mkdir(exist_ok=True); (repo / 'bin/__pycache__/x.pyc').write_bytes(b'x')
            r = subprocess.run([sys.executable, str(repo / 'tools/build-release.py')], capture_output=True, text=True); self.assertEqual(r.returncode, 0, r.stderr)
            archive = next((repo / '.dist').glob('MachineSpirit-*.tar.gz'))
            with tarfile.open(archive) as t: names = t.getnames()
            for banned in ('wallpapers-local', 'local.lua', 'keys.conf', '__pycache__', '.pyc'): self.assertFalse([n for n in names if banned in n], banned)
            self.assertIn('MachineSpirit/install.sh', names); self.assertIn('MachineSpirit/bin/ms-update', names)
    def test_only_listed_paths_enter_the_archive(self):
        import shutil, tarfile
        with tempfile.TemporaryDirectory() as d:
            repo = Path(d) / 'repo'; shutil.copytree(ROOT, repo, ignore=shutil.ignore_patterns('.git', '.dist', '__pycache__', '*.pyc'))
            strays = ['scratch-private.txt', 'quickshell/scratch-private.txt', 'bin/scratch-private.txt', 'docs/scratch-private.txt', 'assets/wallpapers/scratch.jpg', 'quickshell/modules/notes.md']
            for rel in strays: (repo / rel).write_text('private\n')
            (repo / 'unlisted-dir').mkdir(); (repo / 'unlisted-dir/file.py').write_text('x = 1\n')
            archive, _ = load('rb', repo / 'tools/build-release.py').build(repo, Path(d) / 'out')
            with tarfile.open(archive) as t: names = t.getnames()
            for rel in strays + ['unlisted-dir/file.py']: self.assertNotIn('MachineSpirit/' + rel, names, rel)
            for banned in ('docs/media/showcase.gif', 'docs/media/showcase.mp4', 'docs/media/themes.gif', 'docs/media/factions/', 'docs/media/desktop.png', 'docs/media/settings.png', '.github/', 'CONTRIBUTING.md', 'tools/test_release.py', 'assets/emblem.svg', 'wallpapers/forge.svg'):
                self.assertFalse([n for n in names if banned in n], banned)
            self.assertLess(archive.stat().st_size, 50 * 1024**2, 'the release stays within its budget (50 MiB, hard limit 60) and carries no README media')
    def test_archive_covers_everything_the_installer_installs(self):
        import shutil, tarfile
        with tempfile.TemporaryDirectory() as d:
            repo = Path(d) / 'repo'; shutil.copytree(ROOT, repo, ignore=shutil.ignore_patterns('.git', '.dist', '__pycache__', '*.pyc'))
            archive, _ = load('rb2', repo / 'tools/build-release.py').build(repo, Path(d) / 'out')
            with tarfile.open(archive) as t: names = set(t.getnames())
            installer = load('inst_cov', repo / 'installer/install.py')
            wanted = {p.relative_to(repo).as_posix() for src, _ in installer.mappings(installer.COMPONENTS) for p in [src]}
            wanted |= {p.relative_to(repo).as_posix() for p in (repo / 'assets/plymouth').iterdir()} | {p.relative_to(repo).as_posix() for p in (repo / 'assets/sddm').rglob('*') if p.is_file()} | {'install.sh', 'installer/boot.py', 'installer/login.py', 'privacy/install.py', 'packages.txt', 'VERSION', 'LICENSE'}
            missing = sorted(w for w in wanted if 'MachineSpirit/' + w not in names)
            self.assertEqual(missing, [], 'add these paths to the list in tools/build-release.py')
    def test_clean_install_from_the_archive_alone(self):
        """Nothing may depend on files that only exist in the working repository."""
        import shutil, tarfile
        with tempfile.TemporaryDirectory(prefix='ms arch ') as d:
            d = Path(d); repo = d / 'repo'
            shutil.copytree(ROOT, repo, ignore=shutil.ignore_patterns('.git', '.dist', '__pycache__', '*.pyc'))
            subprocess.run([sys.executable, str(repo / 'tools/build-release.py')], check=True, capture_output=True)
            archive = shutil.move(str(next((repo / '.dist').glob('MachineSpirit-*.tar.gz'))), d / 'release.tar.gz'); shutil.rmtree(repo)   # the working tree is gone
            out = d / 'extracted'; out.mkdir()
            with tarfile.open(archive) as t: t.extractall(out, filter='data')
            env = dict(os.environ, HOME=str(d / 'h'), XDG_CONFIG_HOME=str(d / 'c'), XDG_DATA_HOME=str(d / 'd'), XDG_STATE_HOME=str(d / 's'), PATH='/usr/bin:/bin'); env.pop('HYPRLAND_INSTANCE_SIGNATURE', None)
            (d / 'h').mkdir()
            r = subprocess.run(['bash', str(out / 'MachineSpirit/install.sh'), '--components', 'shell,hyprland,terminal,apps,lock,wallpapers', '--no-packages', '--no-system', '--yes'],
                               env=env, capture_output=True, text=True, stdin=subprocess.DEVNULL)
            self.assertEqual(r.returncode, 0, r.stdout[-400:] + r.stderr)
            self.assertTrue((d / 'c/quickshell/machinespirit/shell.qml').is_file()); self.assertTrue((d / 'd/machinespirit/wallpapers/forge.png').is_file())
            self.assertEqual((d / 'd/machinespirit/VERSION').read_text().strip(), (ROOT / 'VERSION').read_text().strip())
            self.assertEqual(sorted(p.name for p in (d / 'd/machinespirit/tools').iterdir() if p.name != '__pycache__'), ['make_emblem.py', 'managed.py'])
            self.assertEqual(sorted(p.name for p in (d / 'd/machinespirit/wallpapers').iterdir() if not p.name.startswith('active-')), ['cogitator.png', 'forge.png', 'quiet.png'])   # no SVG sources, no duplicates in the archive
            doc = subprocess.run([sys.executable, str(out / 'MachineSpirit/installer/install.py'), 'doctor'], env=env, capture_output=True, text=True)
            self.assertNotIn('did not finish', doc.stdout); self.assertNotIn('not valid JSON', doc.stdout)
if __name__=='__main__': unittest.main()
