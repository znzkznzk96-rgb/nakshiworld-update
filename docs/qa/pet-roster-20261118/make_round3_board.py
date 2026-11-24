from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
import json,hashlib,urllib.request
p=Path(__file__).parent;entries=[('보석햄스터','hamster3'),('불꽃병아리','chick3'),('꼬마멧돼지','boar3')]
f=ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc',23);sm=ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',15)
im=Image.new('RGB',(640,845),'#1b2a37');d=ImageDraw.Draw(im);d.text((20,12),'새 시안  /  왼쪽 A · 오른쪽 B',font=f,fill='#fff0cc');reviews=[];records=[]
for i,(name,key) in enumerate(entries):
 y=65+i*260;d.text((20,y),name,font=f,fill='white')
 for j,v in enumerate('AB'):
  n=key+'-'+v;s=Image.open(p/(n+'.png')).convert('RGBA');bb=s.getbbox();assert bb[0]>0 and bb[1]>0 and bb[2]<96 and bb[3]<96
  x=25+j*320;lg=s.resize((192,192),Image.Resampling.NEAREST);im.paste(lg,(x,y+35),lg);tiny=s.resize((36,36),Image.Resampling.NEAREST);im.paste(tiny,(x+220,y+150),tiny);d.text((x+207,y+192),'36px',font=sm,fill='#a5aebb')
  response=json.loads((p/(n+'-response.json')).read_text());response.pop('image',None);records.append({'id':n,'request':json.loads((p/(n+'-request.json')).read_text()),'response_metadata':response,'submission':json.loads((p/(n+'-submitted.json')).read_text())})
  reviews.append({'id':n,'sha256':hashlib.sha256((p/(n+'.png')).read_bytes()).hexdigest(),'bbox':bb,'size':[96,96],'status':'pending_user_choice','checks':{'decode':'pass','inside_canvas':'pass','limb_separation':'visual_pass','theme_readability':'visual_pass'},'note':'좌향 원본. 게임 표시 시 수평반전 가능; 원본 무변경' if n=='chick3-B' else '사용자 선택 전. 세부 외형은 생성 후보.'})
im.save(p/'round3-board.png')
k=(p.parent/'.pet-private/pixel.key').read_text().strip()
with urllib.request.urlopen(urllib.request.Request('https://api.pixellab.ai/v2/balance',headers={'Authorization':'Bearer '+k}),timeout=30) as r:bal=json.loads(r.read())
(p/'ROUND3_REVIEWS.json').write_text(json.dumps({'generated':6,'before':json.loads((p/'round3-balance-before.json').read_text()),'after':bal,'images':reviews,'game_applied':False},ensure_ascii=False,indent=2));(p/'ROUND3_GENERATION_RECORDS.json').write_text(json.dumps(records,ensure_ascii=False,indent=2));print(bal['subscription']['generations'])
