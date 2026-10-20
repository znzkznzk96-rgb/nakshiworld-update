#!/usr/bin/env python3
"""Publish an existing, verified Godot PCK to R2; version.json is uploaded last."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile

PUBLIC_BASE = 'https://nakshiworld-update-kr.znzkznzk96.workers.dev/'
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('patch', type=Path)
p.add_argument('code', type=int)
p.add_argument('name')
p.add_argument('--dry-run', action='store_true')
a = p.parse_args()
if a.code <= 57:
    p.error('A new patch must have code > 57; 0.57 is the current verified release')
if not a.patch.is_file() or a.patch.stat().st_size < 100:
    p.error('Patch is missing or too small')
with a.patch.open('rb') as f:
    if f.read(4) != b'GDPC':
        p.error('Not a Godot PCK file')
    f.seek(0)
    sha = hashlib.file_digest(f, 'sha256').hexdigest()
size = a.patch.stat().st_size
manifest = {'code': a.code, 'name': a.name, 'sha256': sha, 'size': size}
archive = f'releases/{a.code}/{sha}/patch.pck'
plan = {'bucket': 'nakshiworld-updates', 'archive': archive,
        'manifest': manifest, 'public_manifest': PUBLIC_BASE + 'version.json'}
print(json.dumps(plan, ensure_ascii=False, indent=2))
if a.dry_run:
    raise SystemExit(0)
account = os.environ.get('R2_ACCOUNT_ID', '')
if not account or not account.isalnum():
    p.error('Set R2_ACCOUNT_ID locally')
for key in ('AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY'):
    if not os.environ.get(key):
        p.error(f'Set {key} locally; never commit credentials')
endpoint = f'https://{account}.r2.cloudflarestorage.com'
base_cmd = ['aws', '--endpoint-url', endpoint, '--region', 'auto']
def run(*args):
    return subprocess.run(base_cmd + list(args), check=True, capture_output=True)
with tempfile.TemporaryDirectory(prefix='nakshi-r2-') as d:
    current = Path(d) / 'current.json'
    # Require an existing remote manifest to be readable, or an explicit empty-bucket
    # bootstrap. Network/authentication failures must never be treated as absence.
    result = subprocess.run(base_cmd + ['s3api', 'head-object', '--bucket',
        'nakshiworld-updates', '--key', 'version.json'], capture_output=True)
    if result.returncode == 0:
        run('s3', 'cp', 's3://nakshiworld-updates/version.json', str(current))
        old = json.loads(current.read_text())
        if int(old['code']) >= a.code:
            p.error('Remote version is equal or newer; refusing rollback')
        run('s3', 'cp', str(current),
            f's3://nakshiworld-updates/releases/{old["code"]}/version.json')
    elif b'(404)' not in result.stderr and b'Not Found' not in result.stderr:
        raise SystemExit('Cannot check remote manifest; upload cancelled')
    meta = f'sha256={sha}'
    for key in (archive, 'patch.pck'):
        run('s3', 'cp', str(a.patch), 's3://nakshiworld-updates/' + key,
            '--metadata', meta, '--content-type', 'application/octet-stream',
            '--cache-control', 'no-store')
    head = json.loads(run('s3api', 'head-object', '--bucket',
        'nakshiworld-updates', '--key', 'patch.pck').stdout)
    if head['ContentLength'] != size or head.get('Metadata', {}).get('sha256') != sha:
        raise SystemExit('Remote patch metadata mismatch; manifest was not published')
    out = Path(d) / 'version.json'
    out.write_text(json.dumps(manifest, separators=(',', ':')))
    run('s3', 'cp', str(out), 's3://nakshiworld-updates/version.json',
        '--content-type', 'application/json', '--cache-control', 'no-store')
print('Published. Test the actual Android updater before announcing the release.')
