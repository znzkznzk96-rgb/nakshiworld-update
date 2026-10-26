import pathlib,json,hashlib,zipfile,collections,sys
from PIL import Image
repo,game,baseline=map(pathlib.Path,sys.argv[1:])
sha=lambda b:hashlib.sha256(b).hexdigest()
assets=list((game/'art/expedition').glob('*.png'))
assert len(assets)==151
refs=json.loads((game/'art/expedition/approved/SOURCES.json').read_text())
for name,spec in refs.items():assert sha((game/'art/expedition/approved'/name).read_bytes())==spec['sha256']
deleted=json.loads((repo/'automation/deleted-game-files.json').read_text())
missing=[];changed=[];unchanged=0
with zipfile.ZipFile(baseline) as z:
 for name in z.namelist():
  rel=pathlib.PurePosixPath(name).relative_to('game')
  if rel.suffix.lower() not in ['.png','.jpg','.jpeg','.svg','.webp','.wav','.ogg','.mp3','.ttf','.otf']:continue
  p=game/rel
  if not p.exists():missing.append(str(rel))
  elif sha(p.read_bytes())!=sha(z.read(name)):changed.append(str(rel))
  else:unchanged+=1
assert all(n in deleted for n in missing)
alpha=[]
for i in range(1,19):
 im=Image.open(game/f'art/expedition/normal{i:02}_4.png').convert('RGBA');a=im.getchannel('A');w,h=im.size
 edge=[a.getpixel((x,y)) for x in range(w) for y in [0,h-1]]+[a.getpixel((x,y)) for y in range(h) for x in [0,w-1]]
 alpha.append({'id':i,'transparent_border':max(edge)==0,'bbox':a.getbbox()})
assert all(v['transparent_border'] for v in alpha)
c=json.loads((game/'addons/expedition/catalog.json').read_text())
assert len(c['soldiers'])==15 and len(c['enemies'])==22 and len(c['rounds'])==10
assert len({tuple(sorted(u['elements'])) for u in c['soldiers']})==15
for u in c['soldiers']:
 im=Image.open(game/('art/expedition/'+u['id']+'.png'));w,h=u['frame_size']
 assert im.size==(w*u['frame_count'],h)
 for star in ['1','2','3']:assert all(u['stars'][star][k]>0 for k in ['hp','atk','def'])
for r,ids in enumerate(c['rounds'],1):
 assert len(ids)==3
 boss=[str(x) for x in ids if str(x).endswith('R')]
 assert boss==([str(r)+'R'] if r in [3,5,7,10] else [])
 assert max(collections.Counter(x for x in ids if not str(x).endswith('R')).values())<=2
normal_ids={str(x) for ids in c['rounds'] for x in ids if not str(x).endswith('R')}
result={'audited_commit':'0f931337efab1f5e29e8499204ab88ed1186135b','runtime_pngs':len(assets),'original_reference_images_verified':len(refs),'baseline_media_unchanged':unchanged,'baseline_media_changed':changed,'baseline_media_removed':missing,'normal_hit_alpha':alpha,'soldiers':len(c['soldiers']),'normal_enemies':18,'bosses':4,'rounds':c['rounds'],'normal_ids_used':sorted(normal_ids),'catalog_rules':c['rules'],'scope_note':'Transparent borders and exact approved hashes verified; does not replace visual QA of every frame.'}
print(json.dumps(result,ensure_ascii=False,indent=2))
