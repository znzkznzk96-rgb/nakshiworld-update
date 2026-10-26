from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json,zipfile,hashlib,io,shutil
p=Path(__file__).resolve().parent;b=p.parent;out=p/'bundle';out.mkdir(exist_ok=True)
units=[('perch','코발트 퍼치 창병','물+물','attack',2),('eel','황금 전기뱀장어 석궁병','전기+전기','attack',4),('puffer','에메랄드 복어 방패병','독+독','defense',2),('crucian','황금 붕어 방패병','빛+빛','defense',2),('angler','등불을 든 심해 아귀','어둠+어둠','support',2),('flying','청금 날치 검객','물+전기','attack',1),('loach','청록 미꾸라지 의무병','물+독','support',1),('healer','푸른 부채꼬리 물빛 치유사','물+빛','support',1),('flounder','남빛 넙치 방패병','물+어둠','defense',1),('pharmacist','초록 약병 든 메기 약사','전기+독','support',1),('carp','호박빛 잉어 망치병','전기+빛','attack',1),('catfish','보랏빛 금빛 메기 방패병','전기+어둠','defense',1),('herbalist','에메랄드 약초지기 물고기','독+빛','support',1),('rogue','독빛 쌍단검 물고기 병사','독+어둠','attack',1),('crescent','보랏빛 초승달 방패 수호어','빛+어둠','defense',1)]
manifest=[];allframes=[]
for slug,name,combo,role,version in units:
 dst=out/slug;dst.mkdir(exist_ok=True)
 if slug=='eel':
  z=zipfile.ZipFile(b/'eel-motion-v4/eel-ranged-clean.zip');fs=sorted(n for n in z.namelist() if n.startswith('frame-') and n.endswith('.png'));frames=[Image.open(io.BytesIO(z.read(n))).convert('RGBA') for n in fs];(dst/'bolt.png').write_bytes(z.read('bolt.png'));(dst/'preview.gif').write_bytes(z.read('shot-preview.gif'));qa={'status':'existing_eel_motion_v4_preserved'}
 else:
  src=b/f'{slug}-motion-v{version}';qa=json.loads((src/'QA.json').read_text());assert qa['status']=='internal_review_pass_user_signoff_pending',slug
  fs=sorted(src.glob('frame-*.png'))[:qa['frames']];frames=[Image.open(f).convert('RGBA') for f in fs];shutil.copyfile(src/'preview.gif',dst/'preview.gif')
 w,h=frames[0].size;assert all(im.size==(w,h) for im in frames);sheet=Image.new('RGBA',(w*len(frames),h));hashes={}
 for i,im in enumerate(frames):
  f=dst/f'frame-{i:02d}.png';im.save(f);sheet.alpha_composite(im,(i*w,0));hashes[f.name]=hashlib.sha256(f.read_bytes()).hexdigest()
 frames[0].save(dst/'base.png');sheet.save(dst/'spritesheet.png');(dst/'QA.json').write_text(json.dumps(qa,ensure_ascii=False,indent=2)+'\n')
 item={'id':slug,'name':name,'soul_combination':combo,'role':role,'source_version':version,'frame_size':[w,h],'frame_count':len(frames),'unique_frames':len(set(hashes.values())),'pixel_filter':'nearest','animation_scope':'one representative action; idle/move/hurt not newly drawn','game_integrated':False,'user_final_approval':False,'hashes':hashes};manifest.append(item);allframes.append(frames)
(out/'MANIFEST.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
(out/'README.txt').write_text('낚시월드 B안 병사15종 모션검토본\n기본자세/대표액션1개/개별PNG/가로시트/개별GIF. 석궁은 eel-motion-v4 그대로, 별도화살포함. 내부검수와 사용자최종승인·게임연동·배포는 별개.\n창병/복어/붕어/아귀는 기존생성프레임 국소정리 또는 정상프레임회수재사용. 유료재생성없음. 나머지는 최초생성결과. 최종목록/프레임수/중복여부는MANIFEST.\n이동/대기/피격/퇴장 엔진연출과 실제전투연결은 미구현. 기존세이브/버전/공개게임미변경.\n')
font=ImageFont.load_default(size=17);render=[]
for t in range(30):
 canvas=Image.new('RGB',(960,1440),(28,36,49));d=ImageDraw.Draw(canvas)
 for i,((slug,name,combo,role,v),seq) in enumerate(zip(units,allframes)):
  idx=min(int(t/30*len(seq)),len(seq)-1);im=seq[idx];z=im.resize((im.width*2,im.height*2),Image.Resampling.NEAREST);x=i%3*320;y=i//3*288;canvas.paste(z,(x+(320-z.width)//2,y+26),z);d.text((x+12,y+4),slug.upper()+' / '+role,fill=(205,225,235),font=font)
 if 0.25 <= t/30 <= 0.65:
  bolt=Image.open(out/'eel/bolt.png').convert('RGBA').resize((48,14),Image.Resampling.NEAREST)
  bx=320+216+int((t/30-0.25)/0.4*54)
  canvas.paste(bolt,(bx,182),bolt)
 render.append(canvas)
render[0].save(p/'all-15.gif',save_all=True,append_images=render[1:],duration=50,loop=0);render[0].save(p/'all-15.png')
with zipfile.ZipFile(p/'NAKSHIWORLD_SOLDIERS_15_MOTION_REVIEW.zip','w',zipfile.ZIP_DEFLATED) as z:
 for f in sorted(out.rglob('*')):
  if f.is_file():z.write(f,str(f.relative_to(out)))
 z.write(p/'all-15.gif','all-15.gif');z.write(p/'all-15.png','all-15.png')
print('15 units packaged',sum(len(x) for x in allframes),'timeline frames')
