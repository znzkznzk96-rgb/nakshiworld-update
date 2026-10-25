from pathlib import Path
import json,base64
p=Path(__file__).resolve().parent;b=p.parent/'soldiers-15-review/bundle';units=json.loads((b/'MANIFEST.json').read_text())
uri=lambda raw,mime:'data:'+mime+';base64,'+base64.b64encode(raw).decode()
for u in units:
 u['frames']=[uri((b/u['id']/f'frame-{i:02}.png').read_bytes(),'image/png') for i in range(u['frame_count'])];u['base']=uri((b/u['id']/'base.png').read_bytes(),'image/png')
core=(p/'core.js').read_text().replace('/* ASSET_DATA */','const UNITS='+json.dumps(units,ensure_ascii=False)+';const BOLT='+json.dumps(uri((b/'eel/bolt.png').read_bytes(),'image/png'))+';')
s=(p/'template.html').read_text().replace('/* CORE */',core).replace('/* V2 */',(p/'v2.js').read_text())
for f in (p/'assets').iterdir():
 if f.suffix in ['.png','.jpg']:s=s.replace('ASSET:'+f.name,uri(f.read_bytes(),'image/jpeg' if f.suffix=='.jpg' else 'image/png'))
s=s.replace('/* FONT */','@font-face{font-family:GameUI;src:url('+uri((p/'assets/neodgm-subset.ttf').read_bytes(),'font/ttf')+')}')
(p/'NAKSHIWORLD_VILLAGE_EXPLORATION.html').write_text(s)
print('HTML bytes',len(s.encode()))
