from PIL import Image,ImageDraw
import numpy as np
from pathlib import Path
from collections import deque
p=Path(__file__).resolve().parent;src=p.parent/'angler-motion-v1';frames=[]
for i,n in enumerate([0,1,1,7,8,8,7,0]):
 im=Image.open(src/f'frame-{n:02d}.png').convert('RGBA');a=np.array(im);h,w=a.shape[:2]
 if False:
  colors=[(254,207,20),(248,163,8)];iscone=np.zeros((h,w),bool)
  for col in colors:iscone |= (a[:,:,:3]==col).all(axis=2)
  allowed=(a[:,:,3]==0)|iscone;seen=np.zeros((h,w),bool);q=deque([(0,0)]);seen[0,0]=True
  while q:
   y,x=q.popleft()
   for dy,dx in [(0,1),(0,-1),(1,0),(-1,0)]:
    yy,xx=y+dy,x+dx
    if 0<=yy<h and 0<=xx<w and allowed[yy,xx] and not seen[yy,xx]:seen[yy,xx]=True;q.append((yy,xx))
  a[seen & iscone]=0;im=Image.fromarray(a)
 im.save(p/f'frame-{i:02d}.png');frames.append(im)
s=Image.new('RGB',(1440,1260),(35,42,54));d=ImageDraw.Draw(s);g=[]
for i,im in enumerate(frames):
 z=im.resize((480,384),Image.Resampling.NEAREST);s.paste(z,(i%3*480,i//3*420),z);d.text((i%3*480+6,i//3*420+392),str(i),fill='white');bg=Image.new('RGBA',(176,144),(35,42,54));bg.alpha_composite(im,(8,8));g.append(bg.convert('RGB').resize((352,288),Image.Resampling.NEAREST))
s.resize((960,840)).save(p/'sheet.jpg');g[0].save(p/'preview.gif',save_all=True,append_images=g[1:],duration=[400]+[150]*7,loop=0)
