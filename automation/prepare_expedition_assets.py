"""Materialize approved pixel assets from their verified repository backups.

No generation or pixel edits: source files are copied byte-for-byte. The resulting
PNG files are included in the full source release and imported into the PCK.
"""
import base64,hashlib,io,json,pathlib,sys,zipfile
repo=pathlib.Path(__file__).resolve().parents[1]
target=pathlib.Path(sys.argv[1])/'art/expedition'
target.mkdir(parents=True,exist_ok=True)
archive=repo/'docs/design/monster-balance-v1'
m=json.loads((archive/'manifest.json').read_text())
raw=b''.join((archive/p['name']).read_bytes() for p in m['parts'])
assert hashlib.sha256(raw).hexdigest()==m['sha256']
with zipfile.ZipFile(io.BytesIO(raw)) as z:
    assert z.testzip() is None
    for i in range(1,19):
        for j in range(7):
            (target/f'normal{i:02}_{j}.png').write_bytes(z.read(f'normal18_final/keyposes/{i:02}/{j}.png'))
    for key in ['3R','5R','7R','10R']:
        (target/f'boss{key}.png').write_bytes(z.read(f'boss_motion_v2/assets/{key}/sheet.png'))
archive=repo/'docs/design/backrooms-reservoir/soldiers-15-review'
raw=base64.b64decode(b''.join(p.read_bytes() for p in sorted((archive/'archive').glob('review.zip.b64.part*'))))
manifest=json.loads((archive/'MANIFEST.json').read_text())
with zipfile.ZipFile(io.BytesIO(raw)) as z:
    assert z.testzip() is None
    for u in manifest:
        # Validate individual source frames against the approved manifest as well.
        for name,digest in u['hashes'].items():
            assert hashlib.sha256(z.read(u['id']+'/'+name)).hexdigest()==digest
        (target/(u['id']+'.png')).write_bytes(z.read(u['id']+'/spritesheet.png'))
    (target/'bolt.png').write_bytes(z.read('eel/bolt.png'))
for element in ['water','electric','poison','light','dark']:
    (target/(element+'.png')).write_bytes((repo/'docs/design/backrooms-reservoir/art-v3'/(element+'.png')).read_bytes())
print('APPROVED_EXPEDITION_ASSETS verified and restored')
