#!/usr/bin/env python3
"""Regenerate embedded launchers and PKGBUILD checksums from source files."""
import hashlib
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
names = ('cloudpath-arch', 'cloudpath-arch-ns', 'cloudpath-arch-mount-run')
installer = (root / 'install.sh').read_text()
for name in names:
    pattern = rf'(cat > "\$script_dir/{name}" <<\x27SCRIPT\x27\n).*?(\nSCRIPT\n)'
    installer, count = re.subn(pattern, lambda m: m[1] + (root / name).read_text().rstrip('\n') + m[2], installer, flags=re.S)
    assert count == 1, name
pkgbuild = (root / 'PKGBUILD').read_text()
checksums = 'sha256sums=(\n' + ''.join(f"  '{hashlib.sha256((root / name).read_bytes()).hexdigest()}'\n" for name in names) + ')'
pkgbuild, count = re.subn(r'sha256sums=\(.*?\)', lambda _: checksums, pkgbuild, flags=re.S)
assert count == 1
for name, content in [('install.sh', installer), ('PKGBUILD', pkgbuild)]:
    if '--check' in sys.argv:
        if (root / name).read_text() != content:
            sys.exit(f'{name} is stale; run python3 tools/sync-installer.py')
    else:
        (root / name).write_text(content)
