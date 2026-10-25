from PIL import Image,ImageDraw
import numpy as np
from pathlib import Path
p=Path(__file__).resolve().parent;src=p.parent/'puffer-motion-v1'
# Impact overlay frames are omitted, not inpainted. Shield/body preserved.
seq=[0,1,4,5,5,4,1,0];frames=[]
for i,n in enumerate(seq):
 im=Image.open(src/f'frame-{n:02d}.png').convert('RGBA')
 if n==4:
  a=np.array(im);m=a[:,:,3]>0;seen=set();cs=[]
  for y,x in zip(*np.where(m)):
   q=(int(y),int(x))
   if q in seen:continue
   st=[q];seen.add(q);c=[]
   while st:
    yy,xx=st.pop();c.append((yy,xx))
    for dy in [-1,0,1]:
     for dx in [-1,0,1]:
      q=(yy+dy,xx+dx)
      if 0<=q[0]<128 and 0<=q[1]<128 and m[q] and q not in seen:seen.add(q);st.append(q)
   cs.append(c)
  for c in cs:
   if len(c)<20:
    for yy,xx in c:a[yy,xx]=0
  im=Image.fromarray(a)
 im.save(p/f'frame-{i:02d}.png');frames.append(im)
s=Image.new('RGB',(1152,840),(35,42,54));d=ImageDraw.Draw(s);g=[]
for i,im in enumerate(frames):
 z=im.resize((384,384),Image.Resampling.NEAREST);s.paste(z,(i%3*384,i//3*280),z) if False else None
 bg=Image.new('RGBA',(144,144),(35,42,54));bg.alpha_composite(im,(8,8));g.append(bg.convert('RGB').resize((288,288),Image.Resampling.NEAREST))
s=Image.new('RGB',(1152,1296),(35,42,54));d=ImageDraw.Draw(s)
for i,im in enumerate(frames):
 z=im.resize((384,384),Image.Resampling.NEAREST);s.paste(z,(i%3*384,i//3*432),z);d.text((i%3*384+8,i//3*432+395),str(i),fill='white')
s.save(p/'sheet.png');g[0].save(p/'preview.gif',save_all=True,append_images=g[1:],duration=[400,140,130,120,100,130,140,300],loop=0)
