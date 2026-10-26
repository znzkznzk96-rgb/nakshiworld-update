from pathlib import Path
import base64,hashlib,json,zipfile
p=Path(__file__).resolve().parent;m=json.loads((p/'ARCHIVE.json').read_text());parts=sorted((p/'archive').glob('review.zip.b64.part*'));assert len(parts)==m['parts'];raw=base64.b64decode(''.join(f.read_text() for f in parts));assert len(raw)==m['bytes'] and hashlib.sha256(raw).hexdigest()==m['sha256'];target=p/'NAKSHIWORLD_VILLAGE_EXPLORATION_REVIEW.zip';target.write_bytes(raw)
with zipfile.ZipFile(target) as z:
 assert z.testzip() is None
 z.extractall(p)
print(target)
