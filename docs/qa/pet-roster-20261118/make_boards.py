from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
p=Path(__file__).parent
font=ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc',22)
small=ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',15)
groups={'SSS':[('수달','otter'),('해룡','dragon'),('황금 고래','whale'),('균열 늑대','wolf')],'SS':[('별꼬리 여우','fox'),('사냥 물총새','kingfisher'),('불꽃 매','hawk')],'S':[('꼬마 펭귄','penguin'),('샘물 개구리','frog'),('보석 햄스터','hamster')]}
for rank,entries in groups.items():
 im=Image.new('RGB',(640,65+260*len(entries)),'#1b2a37');d=ImageDraw.Draw(im);d.text((20,12),rank+'급 기본 시안  /  왼쪽 A · 오른쪽 B',font=font,fill='#fff0cc')
 for i,(name,key) in enumerate(entries):
  top=65+i*260;d.text((20,top),name,font=font,fill='white')
  for j,v in enumerate(['A','B']):
   f=p/(key+'-'+v+'.png');x=25+j*320
   if not f.exists():d.text((x+50,top+100),'미생성',font=font,fill='#a5aebb');continue
   s=Image.open(f).convert('RGBA');im.paste(s.resize((192,192),Image.Resampling.NEAREST),(x,top+35),s.resize((192,192),Image.Resampling.NEAREST));tiny=s.resize((36,36),Image.Resampling.NEAREST);im.paste(tiny,(x+220,top+150),tiny);d.text((x+207,top+192),'36px',font=small,fill='#a5aebb')
   if key=='hamster':d.text((x,top+230),'검수 보류: 왕관 상단 경계',font=small,fill='#ff9988')
 im.save(p/(rank+'-board.png'))
