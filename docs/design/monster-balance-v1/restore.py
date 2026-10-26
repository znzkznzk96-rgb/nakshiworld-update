from pathlib import Path
import hashlib,json,zipfile,io
root=Path(__file__).resolve().parent
m=json.loads((root/'manifest.json').read_text())
data=b''.join((root/p['name']).read_bytes() for p in m['parts'])
assert len(data)==m['zip_bytes']
assert hashlib.sha256(data).hexdigest()==m['sha256']
with zipfile.ZipFile(io.BytesIO(data)) as z:
    assert z.testzip() is None
    z.extractall(root/'restored')
print('Restored and verified:',root/'restored')
