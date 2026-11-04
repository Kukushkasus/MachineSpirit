#!/usr/bin/env python3
# [ PURITY SEAL ] Ship source and evidence, never the user's secrets.
import hashlib, tarfile
from pathlib import Path
root=Path(__file__).resolve().parents[1]
version=(root/'VERSION').read_text().strip()
out=root/'.dist';out.mkdir(exist_ok=True)
archive=out/f'MachineSpirit-{version}.tar.gz'
def clean(info):
    parts=Path(info.name).parts
    if any(p in {'.git','.dist','__pycache__'} for p in parts): return None
    if info.name.endswith(('.pyc','.log','.qcow2','.iso')) or Path(info.name).name.startswith('.env') or Path(info.name).name in {'keys.conf','local.lua','credentials','proxy-secret.json','gost.json'}: return None
    info.uid=info.gid=0;info.uname=info.gname='';return info
with tarfile.open(archive,'w:gz') as tar:tar.add(root,arcname='MachineSpirit',filter=clean)
sha=hashlib.sha256(archive.read_bytes()).hexdigest()
(out/'SHA256SUMS').write_text(sha+'  '+archive.name+'\n')
print(archive);print(sha)
