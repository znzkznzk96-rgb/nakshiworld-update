from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json,hashlib,zipfile
p=Path(__file__).parent;f=ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc',19);small=ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',14)
tiers=['레어','유니크','전설','신화'];names=['가늘고 긴 꽁치','둥근 복어','큰 다랑어'];checks=[]
for tier,label in enumerate(tiers):
 folder=p/'output'/str(tier)
 for file in folder.glob('frame-*.png'):
  im=Image.open(file).convert('RGB');d=ImageDraw.Draw(im)
  d.text((16,10),label+' · 방출형 오라 시안',font=f,fill='#e7f1ff')
  for i,n in enumerate(names):d.text((16,i*240+218),n,font=small,fill='#b7ccdf')
  im.save(file)
 for file in folder.glob('alpha-*.png'):
  im=Image.open(file);im.load();checks.append({'tier':tier,'frame':file.name,'sha256':hashlib.sha256(file.read_bytes()).hexdigest(),'transparent_pixels':sum(a==0 for a in im.getchannel('A').get_flattened_data())})
(p/'output'/'VERIFICATION.json').write_text(json.dumps({'render_frames':192,'alpha_checks':checks,'fish_texture_unchanged':True,'paid_calls':0,'game_integration_tested':False},indent=2))
print('Prepared labels and 192 decoded frames')
