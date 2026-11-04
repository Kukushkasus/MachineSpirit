#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
import os,shutil
from pathlib import Path
if os.geteuid()!=0:raise SystemExit('Administrator permissions required')
root=Path(__file__).resolve().parent
for source,dest in [('ms-browser-policy','/usr/local/libexec/ms-browser-policy'),('org.machinespirit.browser.policy','/usr/share/polkit-1/actions/org.machinespirit.browser.policy')]:
    p=Path(dest);p.parent.mkdir(parents=True,exist_ok=True)
    if p.is_symlink():raise SystemExit('Refusing symlink destination')
    shutil.copyfile(root/source,p);os.chown(p,0,0);os.chmod(p,0o755 if source=='ms-browser-policy' else 0o644)
