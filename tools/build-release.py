#!/usr/bin/env python3
# [ PURITY SEAL ] Ship what the installer needs, never what happens to lie nearby.
"""Build .dist/MachineSpirit-<VERSION>.tar.gz and .dist/SHA256SUMS from an explicit list of installable paths.

Only the files named here can enter the archive, so a stray file in the working tree (notes, a private wallpaper,
a key file) cannot leak into a release. It needs no Git checkout. If the installer starts using a new path, add it
below; tools/test_release.py compares this list with what the installer installs and fails when one is missing.
"""
import hashlib, sys, tarfile
from pathlib import Path

TOP = ('CHANGELOG.md', 'LICENSE', 'README.md', 'README.ru.md', 'THIRD-PARTY.md', 'VERSION', 'install.sh', 'packages.txt')
FILES = ('scripts/ms-theme', 'scripts/ms-walls', 'tools/managed.py', 'tools/make_emblem.py', 'tools/make_cursors.py', 'docs/media/banner.svg', 'docs/media/seal.svg')
# directory -> suffixes that may be shipped from it ('' means a file without a suffix, such as the bin/ms-* scripts)
DIRS = {
    'bin': {'', '.py'}, 'config': {'.json'}, 'fastfetch': {'.jsonc', '.png'}, 'fish': {'.fish'}, 'hypr': {'.lua'},
    'hypridle': {'.conf'}, 'hyprlock': {'.conf'}, 'installer': {'.py', '.json'}, 'kitty': {'.conf'},
    'matugen': {'', '.json', '.jsonc', '.toml', '.fish', '.css', '.lua', '.conf'},
    'privacy': {'', '.py', '.policy'}, 'quickshell': {'.qml', '.svg', '.png', '.jpg', '.conf', '.py', '.json'}, 'quickshell/assets/fonts': {'.ttf', '.txt'},
    'assets/fonts': {'.ttf', '.txt'}, 'assets/plymouth': {'.plymouth', '.script'}, 'assets/sddm': {'.qml', '.conf', '.desktop', '.png', '.ttf', '.txt'}, 'assets/wallpapers': {'.png'}, 'docs': {'.md'},
}
# safety net inside the allowed dirs: no runtime state, credentials or private images in a release
SKIP_PARTS = {'__pycache__', 'wallpapers-local'}
SKIP_SUFFIXES = {'.pyc', '.log', '.qcow2', '.iso'}
SKIP_NAMES = {'keys.conf', 'local.lua', 'credentials', 'proxy-secret.json', 'gost.json'}

def files(root):
    """Relative paths that belong in the release, sorted for a reproducible archive."""
    root = Path(root); found = set()
    for rel in TOP + FILES:
        if not (root / rel).is_file(): raise SystemExit(f'Release list names a missing file: {rel}')
        found.add(rel)
    for directory, suffixes in DIRS.items():
        base = root / directory
        if not base.is_dir(): raise SystemExit(f'Release list names a missing directory: {directory}')
        for p in base.rglob('*'):
            rel = p.relative_to(root)
            if not p.is_file() or SKIP_PARTS & set(rel.parts) or p.name.startswith('.') or p.name in SKIP_NAMES or p.suffix in SKIP_SUFFIXES or p.suffix not in suffixes: continue
            if p.is_symlink(): raise SystemExit(f'Refusing a symbolic link in the release: {rel}')
            found.add(rel.as_posix())
    return sorted(found)

def build(root=None, out=None):
    root = Path(root or Path(__file__).resolve().parents[1]); version = (root / 'VERSION').read_text().strip()
    out = Path(out or root / '.dist'); out.mkdir(exist_ok=True)
    archive = out / f'MachineSpirit-{version}.tar.gz'
    def normal(info): info.uid = info.gid = 0; info.uname = info.gname = ''; return info
    with tarfile.open(archive, 'w:gz') as tar:
        for rel in files(root): tar.add(root / rel, arcname=f'MachineSpirit/{rel}', filter=normal, recursive=False)
    sha = hashlib.sha256(archive.read_bytes()).hexdigest()
    (out / 'SHA256SUMS').write_text(sha + '  ' + archive.name + '\n')
    return archive, sha

if __name__ == '__main__':
    import sys
    # an output folder may be given; the default .dist also holds reference archives used by the tests
    archive, sha = build(out=sys.argv[1] if len(sys.argv) > 1 else None); print(archive); print(sha)
