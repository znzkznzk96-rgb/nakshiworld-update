from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
import json,hashlib,urllib.request
p=Path(__file__).parent
font=ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc',22);small=ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',15)
groups={'hamster-new':[('보석햄스터 새 시안','hamster2')],'A-new':[('배낭 거북','turtle'),('불꽃 병아리','chick'),('밤송이 고슴도치','hedgehog')],'B-new':[('찌 참새','sparrow'),('장사 너구리','raccoon'),('꼬마 멧돼지','boar')]}
reviews=[];records=[]
for group,entries in groups.items():
 im=Image.new('RGB',(640,65+260*len(entries)),'#1b2a37');d=ImageDraw.Draw(im);d.text((20,12),'새 기본 시안  /  왼쪽 A · 오른쪽 B',font=font,fill='#fff0cc')
 for i,(name,key) in enumerate(entries):
  top=65+i*260;d.text((20,top),name,font=font,fill='white')
  for j,v in enumerate(['A','B']):
   n=key+'-'+v;f=p/(n+'.png');x=25+j*320;s=Image.open(f).convert('RGBA');large=s.resize((192,192),Image.Resampling.NEAREST);im.paste(large,(x,top+35),large);tiny=s.resize((36,36),Image.Resampling.NEAREST);im.paste(tiny,(x+220,top+150),tiny);d.text((x+207,top+192),'36px',font=small,fill='#a5aebb')
   bb=s.getbbox();assert bb[0]>0 and bb[1]>0 and bb[2]<96 and bb[3]<96,n
   response=json.loads((p/(n+'-response.json')).read_text());response.pop('image',None)
   reviews.append({'id':n,'name':name,'size':s.size,'bbox':bb,'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'status':'candidate_pending_user_selection','checks':{'decode':'pass','margin':'pass','limb_role_separation':'visual_pass','animation':'not_tested','game_integration':'not_applied'}})
   records.append({'id':n,'request':json.loads((p/(n+'-request.json')).read_text()),'submission':json.loads((p/(n+'-submitted.json')).read_text()),'response_metadata':response})
 im.save(p/(group+'-board.png'))
key=(p.parent/'.pet-private/pixel.key').read_text().strip()
with urllib.request.urlopen(urllib.request.Request('https://api.pixellab.ai/v2/balance',headers={'Authorization':'Bearer '+key}),timeout=30) as r:balance=json.loads(r.read())
meta={'date':'2026-11-18','generated':len(reviews),'balance_before':json.loads((p/'round2-balance-before.json').read_text()),'balance_after':balance,'images':reviews,'notes':['기존 사용자 선택9종 변경없음','거절 hamster-A는 미사용','새14장 원본 보존, 36px 정적 비교','거북 시안의 바닥 그림자는 최종 적용 시 별도 검토, 원본 수정 없음','고슴도치A는 네발, B는 앉은 자세의 후보 차이','세부 프롬프트와 결과 외형 차이는 최종 사용자 선택 대상']}
(p/'ROUND2_REVIEWS.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2));(p/'ROUND2_GENERATION_RECORDS.json').write_text(json.dumps(records,ensure_ascii=False,indent=2));print('generated',len(reviews),'balance',balance['subscription']['generations'])
