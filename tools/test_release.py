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
if __name__=='__main__': unittest.main()
