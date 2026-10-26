from PIL import Image,ImageDraw
from pathlib import Path
p=Path(__file__).resolve().parent;src=p.parent/'angler-motion-v1';frames=[]
for i,n in enumerate([0,1,1,7,8,8,7,0]):
 im=Image.open(src/f'frame-{n:02d}.png').convert('RGBA')
 im.save(p/f'frame-{i:02d}.png');frames.append(im)
s=Image.new('RGB',(1440,1260),(35,42,54));d=ImageDraw.Draw(s);g=[]
for i,im in enumerate(frames):
 z=im.resize((480,384),Image.Resampling.NEAREST);s.paste(z,(i%3*480,i//3*420),z);d.text((i%3*480+6,i//3*420+392),str(i),fill='white');bg=Image.new('RGBA',(176,144),(35,42,54));bg.alpha_composite(im,(8,8));g.append(bg.convert('RGB').resize((352,288),Image.Resampling.NEAREST))
s.resize((960,840)).save(p/'sheet.jpg');g[0].save(p/'preview.gif',save_all=True,append_images=g[1:],duration=[400]+[150]*7,loop=0)
