from pathlib import Path
import base64,hashlib,json,zipfile
p=Path(__file__).resolve().parent
v=json.loads((p/'VERIFICATION.json').read_text())
parts=sorted((p/'archive').glob('review.zip.b64.part*'))
assert len(parts)==v['archive_parts']
b=base64.b64decode(''.join(x.read_text() for x in parts),validate=True)
assert hashlib.sha256(b).hexdigest()==v['zip_sha256']
out=p/'NAKSHIWORLD_SOLDIERS_15_MOTION_REVIEW.zip';out.write_bytes(b)
assert zipfile.ZipFile(out).testzip() is None
print(out)
