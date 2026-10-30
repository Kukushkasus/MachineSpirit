# [ PURITY SEAL ] Every generated file remembers what came before.
import contextlib, hashlib, json, os, shutil, tempfile, time
from pathlib import Path

def digest(path):
    if path.is_symlink(): return 'link:'+os.readlink(path)
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None

@contextlib.contextmanager
def transaction(paths, state):
    tx=state/'install'/(time.strftime('%Y%m%d-%H%M%S')+'-theme-'+str(os.getpid()))
    tx.mkdir(parents=True,exist_ok=True)
    manifest={'version':1,'status':'applying','files':[]}
    def save():
        temp=tx/'manifest.tmp'; temp.write_text(json.dumps(manifest,indent=2)); os.replace(temp,tx/'manifest.json')
    for p in dict.fromkeys(paths):
        p=Path(p); original=digest(p); e={'dest':str(p),'backup':None,'installed':original}
        if original is not None:
            e['backup']='backup/'+str(len(manifest['files'])); b=tx/e['backup']; b.parent.mkdir(exist_ok=True)
            if p.is_symlink():
                target=p.resolve(); b.symlink_to(os.readlink(p)); p.unlink(); shutil.copy2(target,p)
            else: shutil.copy2(p,b)
        manifest['files'].append(e)
    save()
    try:
        yield
        for e in manifest['files']: e['installed']=digest(Path(e['dest']))
        manifest['status']='complete'; save()
    except BaseException:
        for e in reversed(manifest['files']):
            p=Path(e['dest'])
            if p.exists() or p.is_symlink(): p.unlink()
            if e['backup']:
                b=tx/e['backup']; p.parent.mkdir(parents=True,exist_ok=True)
                if b.is_symlink(): p.symlink_to(os.readlink(b))
                else: shutil.copy2(b,p)
        manifest['status']='rolled-back'; save(); raise
