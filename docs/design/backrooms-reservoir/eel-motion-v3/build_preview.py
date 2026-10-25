"""Composite the generated attack with a separate projectile, at 20 FPS."""
from pathlib import Path
from PIL import Image, ImageDraw
import json,zipfile
P=Path(__file__).resolve().parent
fs=[Image.open(p).convert('RGBA') for p in sorted(P.glob('frame-*.png'))]
assert len(fs)==9 and all(f.size==(128,128) for f in fs)
sheet=Image.new('RGBA',(1152,128))
for i,f in enumerate(fs):sheet.paste(f,(i*128,0))
sheet.save(P/'attack-sheet.png')
sheet.resize((2304,256),Image.Resampling.NEAREST).save(P/'sheet-preview.png')
# Independent bolt: it travels to the target, not with the soldier's body.
bolt=Image.new('RGBA',(24,7));d=ImageDraw.Draw(bolt)
d.rectangle((3,3,19,4),fill='#583622');d.line((4,3,19,3),fill='#dcb46b');d.polygon([(18,0),(23,3),(18,6)],fill='#e7eff1');d.line((18,0,23,3,18,6),fill='#59637d',width=1);d.polygon([(0,0),(6,3),(0,3)],fill='#efce58');d.polygon([(0,6),(6,4),(0,4)],fill='#9c7335');bolt.save(P/'bolt.png')
frames=[]
for tick in range(52):
 t=tick*.05
 im=Image.new('RGB',(400,160),'#272a38');d=ImageDraw.Draw(im)
 d.rectangle((0,136,399,159),fill='#444351');d.line((0,136,399,136),fill='#706675')
 # Readable stand-in target, not a new monster design.
 hit=1.0<=t<1.15
 x=345+(3 if hit else 0)
 d.rectangle((x-3,118,x+3,135),fill='#95714b')
 for r,c in [(23,'#a77e50'),(18,'#e3cf9e'),(12,'#a85c48'),(5,'#e3cf9e')]:d.ellipse((x-r,99-r,x+r,99+r),fill=c)
 if t<.45:idx=0
 elif t<1.25:idx=min(8,1+int((t-.45)/.10))
 else:idx=0
 im.paste(fs[idx],(12,18),fs[idx])
 # Spawn at recoil, travel for 0.35s; no damage before arrival.
 if .65<=t<1.0:
  xbolt=round(127+(345-127)*(t-.65)/.35)
  im.paste(bolt,(xbolt-23,96),bolt)
 if 1.0<=t<1.15:
  d.line((334,86,352,112),fill='#fff1b8',width=2);d.line((332,109,354,88),fill='#fff1b8',width=2)
 d.text((12,6),'AIM > FIRE > HIT > RECOVER',fill='#ead9b7')
 frames.append(im.resize((800,320),Image.Resampling.NEAREST))
frames[0].save(P/'shot-preview.gif',save_all=True,append_images=frames[1:],duration=50,loop=0,disposal=2)
print('preview ready',len(fs),'source frames,',len(frames),'playback frames')
