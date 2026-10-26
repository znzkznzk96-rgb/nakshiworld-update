from pathlib import Path
import json,base64
root=Path(__file__).resolve().parent
bundle=root.parent/'soldiers-15-review/bundle'
data=json.loads((bundle/'MANIFEST.json').read_text())
for u in data:
 u['frames']=['data:image/png;base64,'+base64.b64encode((bundle/u['id']/f'frame-{i:02}.png').read_bytes()).decode() for i in range(u['frame_count'])]
 u['base']='data:image/png;base64,'+base64.b64encode((bundle/u['id']/'base.png').read_bytes()).decode()
bolt='data:image/png;base64,'+base64.b64encode((bundle/'eel/bolt.png').read_bytes()).decode()
s=(root/'template.html').read_text().replace('/* ASSET_DATA */','const UNITS='+json.dumps(data,ensure_ascii=False)+';const BOLT='+json.dumps(bolt)+';')
s=s.replace('/* FONT */', '@font-face{font-family:Galmuri;src:url(data:font/ttf;base64,'+(root/'font.b64').read_text()+')}')
(root/'NAKSHIWORLD_EXPLORATION.html').write_text(s)
print('Built offline exploration review',len(s.encode()),'bytes; 15 units')
