from PIL import Image,ImageDraw
import numpy as np
from pathlib import Path
import json,hashlib,zipfile,base64
p=Path(__file__).resolve().parent;src=p.parent/'perch-motion-v1'
# Preserve source and pixel scale. Extend transparent bounds only.
ims={i:Image.open(src/f'frame-{i:02d}.png').convert('RGBA') for i in [1,3,4,6,7]}
# Only detached components outside body/weapon are removed, per inspected frames.
for n in [3,4]:
 a=np.array(ims[n]);mask=a[:,:,3]>0;seen=set()
 for y,x in zip(*np.where(mask)):
  if (int(y),int(x)) in seen:continue
  stack=[(int(y),int(x))];seen.add(stack[0]);comp=[]
  while stack:
   yy,xx=stack.pop();comp.append((yy,xx))
   for dy in [-1,0,1]:
    for dx in [-1,0,1]:
     q=(yy+dy,xx+dx)
     if 0<=q[0]<128 and 0<=q[1]<128 and mask[q] and q not in seen:seen.add(q);stack.append(q)
  if len(comp)<25 and min(x for y,x in comp)>95:
   for yy,xx in comp:a[yy,xx]=0
 ims[n]=Image.fromarray(a)
# Restore full silver tip from the clean horizontal guard, preserving native pixels.
a=np.array(ims[7]);a[:,108:]=0
a[:85,104:]=0;a[94:,104:]=0
attack=Image.new('RGBA',(160,128));attack.alpha_composite(Image.fromarray(a),(8,0))
tip=ims[6].crop((87,79,125,99));attack.alpha_composite(tip,(116,80))
# No generated flourish frames: readable anticipation, thrust, recoil, guard.
seq=[1,3,4,6,'thrust',6,4,3,1];frames=[]
for i,n in enumerate(seq):
 im=Image.new('RGBA',(160,128))
 if n=='thrust':im=attack.copy()
 else:im.alpha_composite(ims[n],(8,0))
 im.save(p/f'frame-{i:02d}.png');frames.append(im)
frames[0].save(p/'perch.png')
sheet=Image.new('RGB',(1440,1248),(35,42,54));d=ImageDraw.Draw(sheet)
gifs=[]
for i,im in enumerate(frames):
 large=im.resize((480,384),Image.Resampling.NEAREST);sheet.paste(large,(i%3*480,i//3*416),large);d.text((i%3*480+8,i//3*416+390),str(i),fill='white')
 bg=Image.new('RGBA',(192,144),(35,42,54));bg.alpha_composite(im,(8,8));gifs.append(bg.convert('RGB').resize((384,288),Image.Resampling.NEAREST))
sheet.save(p/'sheet.png');gifs[0].save(p/'preview.gif',save_all=True,append_images=gifs[1:],duration=[450,90,80,100,130,80,80,90,300],loop=0)
print('created9timelineframes; native160x128; no paid request')
