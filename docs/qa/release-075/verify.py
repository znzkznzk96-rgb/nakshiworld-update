import urllib.request,json,hashlib,zipfile,pathlib
out=pathlib.Path(__file__).parent
repo='https://api.github.com/repos/znzkznzk96-rgb/nakshiworld-update'
def get(url):
 with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'GodotEngine/4.4.1.stable.official (Linux)','Cache-Control':'no-cache'}),timeout=45) as r:return r.read()
r=json.loads(get(repo+'/releases/tags/v0.75'));assert not r['draft']
report={'version':'0.75','source_commit':'20911202cbb3ac8beca3706df3ec5c71a0fe46bb','assets':{}}
for name in ['version.json','patch.pck','game-source.zip']:
 a=next(a for a in r['assets'] if a['name']==name);b=get(a['browser_download_url']);assert len(b)==a['size'];(out/name).write_bytes(b);report['assets'][name]={'size':len(b),'sha256':hashlib.sha256(b).hexdigest()};print('DOWNLOADED',name,len(b),flush=True)
v=json.loads((out/'version.json').read_text());assert v['code']==75 and v['source_commit']==report['source_commit'];assert v['sha256']==report['assets']['patch.pck']['sha256'];assert v['size']==report['assets']['patch.pck']['size']
with zipfile.ZipFile(out/'game-source.zip') as z:
 assert z.testzip() is None
 for f in ['main.gd','addons/reservoir/personal_dex.gd','addons/reservoir/region_shop.gd','addons/reservoir/commerce.gd','addons/reservoir/enhancement.gd','addons/reservoir/audio_feedback.gd','sfx/village/village.ogg']:assert z.read('game/'+f)==pathlib.Path('project',f).read_bytes(),f
base='https://nakshiworld-update-kr.znzkznzk96.workers.dev'
live=json.loads(get(base+'/version.json'));assert live==v
p=get(base+'/patch.pck?v=75.0');assert len(p)==v['size'] and hashlib.sha256(p).hexdigest()==v['sha256'];assert p[:4]==b'GDPC'
report.update(manifest=v,live_download_verified=True,full_source_verified=True,phone_confirmed=False)
(out/'VERIFICATION.json').write_text(json.dumps(report,indent=2)+'\n');print('RELEASE_075_VERIFIED',flush=True)
