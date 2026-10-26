#!/usr/bin/env python3
"""Change only UPDATE_BASE in the supplied Godot source project."""
import argparse
from pathlib import Path
import re

BASE = 'https://nakshiworld-update-kr.znzkznzk96.workers.dev/'
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('root', type=Path, help='Path to the actual game/root.gd source')
p.add_argument('--check', action='store_true')
a = p.parse_args()
s = a.root.read_text(encoding='utf-8')
pattern = r'(?m)^(const\s+UPDATE_BASE\s*:?\s*=\s*)"[^"\n]*"'
matches = list(re.finditer(pattern, s))
if len(matches) != 1:
    p.error('Expected exactly one UPDATE_BASE declaration; no file was changed')
updated = re.sub(pattern, lambda m: m[1] + '"' + BASE + '"', s)
if a.check:
    if updated != s:
        raise SystemExit('UPDATE_BASE still needs migration')
    print('UPDATE_BASE is configured for R2')
else:
    a.root.write_text(updated, encoding='utf-8')
    print('Updated UPDATE_BASE; rebuild the bootstrap APK to activate this change')
