from PIL import Image
import numpy as np
from scipy import ndimage
import sys
T=int(sys.argv[1])
im=Image.open('src.jpg').convert('RGB');a=np.array(im).astype(float);L=a.mean(2)
lab,_=ndimage.label(L>110)
bg=np.isin(lab,[lab[0,0],lab[0,-1],lab[-1,0],lab[-1,-1]])
mask=ndimage.binary_fill_holes(~bg)
dark=(L<120)&mask
dl,_=ndimage.label(dark)
edge=ndimage.binary_dilation(bg,iterations=3)
outer=np.isin(dl,np.unique(dl[edge&dark]))&dark
inner=mask&~outer
ys,xs=np.nonzero(mask);y0,y1,x0,x1=ys.min(),ys.max()+1,xs.min(),xs.max()+1
w,h=x1-x0,y1-y0;k=(T-2)/max(w,h);nw,nh=round(w*k),round(h*k)
def rs(arr): return np.array(Image.fromarray((arr[y0:y1,x0:x1]*255).astype(np.uint8)).resize((nw,nh),Image.BOX)).astype(float)/255
inn=rs(inner)>0.45;innerdark=rs(dark&~outer)>0.22
c=np.array(im.crop((x0,y0,x1,y1)).resize((nw,nh),Image.BOX)).astype(float).mean(2)
W,H=nw+2,nh+2;out=np.zeros((H,W,4),np.uint8);O=(42,22,16,255)
I=np.pad(inn,1)
for y in range(nh):
  for x in range(nw):
    if inn[y,x]:
      v=c[y,x];out[y+1,x+1]=O if innerdark[y,x] else ((250,251,253,255) if v>238 else ((222,226,235,255) if v>210 else (184,190,204,255)))
ring=ndimage.binary_dilation(I,structure=[[0,1,0],[1,1,1],[0,1,0]])&~I
out[ring]=O
Image.fromarray(out).save(f'pawB_{T}.png')
bgc=Image.new('RGBA',(W,H),(70,90,120,255));bgc.alpha_composite(Image.fromarray(out));bgc.resize((W*10,H*10),Image.NEAREST).save(f'viewB_{T}.png');print(W,H)
