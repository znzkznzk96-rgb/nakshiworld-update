from PIL import Image,ImageDraw
from pathlib import Path
p=Path(__file__).resolve().parent;src=p.parent/'crucian-motion-v1'
# Keep the clean shield-raising defensive action; reverse clean poses for recovery.
seq=[0,1,2,3,2,1,0];frames=[Image.open(src/f'frame-{i:02d}.png').convert('RGBA') for i in seq]
g=[];s=Image.new('RGB',(1440,1260),(35,42,54));d=ImageDraw.Draw(s)
for i,im in enumerate(frames):
 im.save(p/f'frame-{i:02d}.png');bg=Image.new('RGBA',(176,144),(35,42,54));bg.alpha_composite(im,(8,8));g.append(bg.convert('RGB').resize((352,288),Image.Resampling.NEAREST));z=im.resize((480,384),Image.Resampling.NEAREST);s.paste(z,(i%3*480,i//3*420),z);d.text((i%3*480+6,i//3*420+392),str(i),fill='white')
s.save(p/'sheet.png');g[0].save(p/'preview.gif',save_all=True,append_images=g[1:],duration=[400,110,110,220,110,110,300],loop=0)
