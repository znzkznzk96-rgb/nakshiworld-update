from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json,shutil
p=Path(__file__).parent;f=ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc',19);small=ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',14)
for tier,label in [(2,'전설 · 태양 분출'),(3,'신화 · 공간 파열')]:
 for file in (p/'output'/str(tier)).glob('frame-*.png'):
  im=Image.open(file).convert('RGB');d=ImageDraw.Draw(im);d.text((16,10),label,font=f,fill='#e7f1ff')
  for i,n in enumerate(['가늘고 긴 꽁치','둥근 복어','큰 다랑어']):d.text((16,i*240+218),n,font=small,fill='#b7ccdf')
  im.save(file)
for t in [0,1]:shutil.copyfile(Path('aura-procedural-r4')/f'aura_{t}.gif',p/f'aura_{t}.gif')
s=json.load(open(p/'output/SPEC.json'));s['revision']=5;s['rendered_tiers_this_round']=['legendary','mythic'];s['selected_versions']={'rare':'R3 approved unchanged','unique':'R4 unchanged, prior approval pending','legendary':'R5 solar eruption pending','mythic':'R5 spatial rupture pending'};s['mechanisms']=['drifting blue motes','separate violet gems and short afterglow','wide solar flame eruption followed by embers','spatial tears open, discharge energy and close'];s.pop('emitter_counts',None);s['legendary_flame_emitters']=18;s['legendary_ember_emitters']=90;s['mythic_fissure_emitters']=7;s['cycles_seconds']=[3,3,1.5,3];s['status']='r5_user_review_pending';(p/'output/SPEC.json').write_text(json.dumps(s,indent=2))
