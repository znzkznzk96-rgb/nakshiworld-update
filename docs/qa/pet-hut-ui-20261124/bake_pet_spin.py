import numpy as np, math, sys
from PIL import Image
from scipy import ndimage as ndi
def build(img):
    a=np.array(img.convert('RGBA'));al=a[...,3]>40
    dt=ndi.distance_transform_edt(np.pad(al,1))[1:-1,1:-1]
    t=np.clip(np.round(dt*0.9),1,None)*al    # 가장자리에서 멀수록 두껍게
    t=np.minimum(t,np.round(al.shape[1]*0.22))
    ys,xs=np.nonzero(al);vox=[]
    for y,x in zip(ys,xs):
        for z in range(-int(t[y,x]),int(t[y,x])+1):
            vox.append((x,y,z,a[y,x,:3],abs(z)/(t[y,x]+0.5)))
    return a,vox
def render(a,vox,ang,tilt=0.0,pad=6):
    H,W=a.shape[:2];cx=sum(v[0] for v in vox)/len(vox)
    out=np.zeros((H+2*pad,W+2*pad,4),np.uint8);zb=np.full(out.shape[:2],-1e9)
    c,s=math.cos(ang),math.sin(ang)
    for x,y,z,col,e in vox:
        dx=x-cx
        X=dx*c+z*s; Z=-dx*s+z*c            # Z가 클수록 가까움
        sx=int(round(cx+X))+pad; sy=int(round(y+Z*tilt*-1))+pad
        if 0<=sx<out.shape[1] and 0<=sy<out.shape[0] and Z>zb[sy,sx]:
            zb[sy,sx]=Z
            sh=1.0-0.28*e*(1 if abs(math.sin(ang))>0.05 else 0)
            out[sy,sx,:3]=np.clip(col*sh,0,255);out[sy,sx,3]=255
    return Image.fromarray(out)
if __name__=='__main__':
    import glob,os
    N=16;PAD=6
    for f in sorted(glob.glob('game/art/pet_hut/slot/rv_*_00.png')):
        k=os.path.basename(f)[3:-7]
        a,vox=build(Image.open(f));h,w=a.shape[:2]
        sheet=Image.new('RGBA',((h+2*PAD)*N,h+2*PAD))   # PAD가 render 안에서 이미 들어감: 정사각 셀
        for i in range(N):
            fr=render(a,vox,2*math.pi*i/N,0.0,PAD)
            cell=Image.new('RGBA',(h+2*PAD,h+2*PAD));cell.paste(fr,((h+2*PAD-fr.size[0])//2,0))
            sheet.paste(cell,(i*(h+2*PAD),0))
        sheet.save('game/art/pet_hut/pets/%s_spin.png'%k);print(k,sheet.size)
