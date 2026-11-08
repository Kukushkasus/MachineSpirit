#!/usr/bin/env python3
# [ PURITY SEAL ] The manual follows the registered controls.
import json, os, re, sys
from pathlib import Path
path=Path(sys.argv[1]) if len(sys.argv)>1 else Path(os.environ.get('XDG_CONFIG_HOME',Path.home()/'.config'))/'machinespirit/bindings.json'
rows=json.loads(path.read_text())
print('# Keybinding reference\n\nGenerated from the same registration catalog as the Super+/ manual. See [settings](SETTINGS.md) for overrides.\n\n| Shortcut | Action |\n|---|---|')
for row in sorted(rows,key=lambda r:r['description']):
    key=row['keys'].replace('code:61','/')
    key=re.sub(r'code:(1[0-9])',lambda m:str((int(m[1])-9)%10),key)
    print('| '+(key or 'Disabled').replace('|',r'\|')+' | '+row['description'].replace('|',r'\|')+' |')
print('\nSuper alone also opens the command console. Escape closes overlays. Remap registered actions in Settings → Shortcuts; an empty replacement disables an action. Additional user Lua binds appear in the live manual when they have descriptions.')
