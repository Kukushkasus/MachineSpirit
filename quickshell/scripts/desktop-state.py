#!/usr/bin/env python3
# [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
"""Private atomic persistence for desktop instruments. JSON travels through stdin."""
import json
import os
from pathlib import Path
import sys
import tempfile

KEYS = {'clock', 'weather', 'resources', 'media', 'notes'}

def validate(data):
    if not isinstance(data, dict) or data.get('version') != 1:
        raise ValueError('Unsupported desktop state')
    if not isinstance(data.get('widgets'), dict):
        raise ValueError('Missing widget layout')
    for key, item in data['widgets'].items():
        if key not in KEYS or not isinstance(item, dict):
            raise ValueError('Invalid widget')
        if not isinstance(item.get('enabled'), bool) or not isinstance(item.get('screen'), str):
            raise ValueError('Invalid widget settings')
        for field in ('x', 'y', 'scale'):
            value = item.get(field)
            if not isinstance(value, (float, int)) or isinstance(value, bool) or not (-100000 < value < 100000):
                raise ValueError('Invalid geometry')
        for field in ('viewportWidth', 'viewportHeight'):
            if field in item and (not isinstance(item[field], (int, float)) or not 0 < item[field] < 100000):
                raise ValueError('Invalid viewport')
        if not 0.8 <= item['scale'] <= 1.4:
            raise ValueError('Invalid scale')
    note = data.get('note')
    if not isinstance(note, dict) or not all(isinstance(note.get(k), str) for k in ('title', 'text')):
        raise ValueError('Invalid note')
    if not isinstance(data.get('seconds'), bool):
        raise ValueError('Invalid clock setting')
    return data

def main():
    path = Path(sys.argv[2])
    if sys.argv[1] == 'read':
        if not path.exists():
            print(json.dumps({'missing': True}))
        else:
            print(json.dumps({'data': validate(json.loads(path.read_text()))}, ensure_ascii=False))
        return
    data = validate(json.loads(sys.stdin.readline()))
    # don't overwrite a broken or unknown file, or one that changed after we read it
    if path.exists():
        validate(json.loads(path.read_text()))
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(prefix='.desktop-', dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.flush()
            os.fsync(f.fileno())
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)
    print(json.dumps({'ok': True}))

if __name__ == '__main__':
    try:
        main()
    except Exception as exc:
        print(json.dumps({'error': str(exc)}))
        sys.exit(1)
