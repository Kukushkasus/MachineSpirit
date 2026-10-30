#!/usr/bin/env python3
# [ PURITY SEAL ] Write data as data, never as a shell command.
import json, os, sys, tempfile
from pathlib import Path
p=Path(sys.argv[1]); value=json.load(sys.stdin)
p.parent.mkdir(parents=True,exist_ok=True)
fd,tmp=tempfile.mkstemp(dir=p.parent)
try:
    with os.fdopen(fd,'w') as f: json.dump(value,f);f.flush();os.fsync(f.fileno())
    os.replace(tmp,p)
finally:
    if os.path.exists(tmp): os.unlink(tmp)
