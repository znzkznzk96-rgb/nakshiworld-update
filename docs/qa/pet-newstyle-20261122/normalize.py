from PIL import Image
import numpy as np, hashlib, os, json
from collections import Counter
from scipy import ndimage
OUT=np.array([8,18,60,255],np.uint8)
otter=np.array(Image.open('final2/otter/otter-final.png').convert('RGBA'))
EYE=otter[26:32,50:58].copy()   # 6x8 수달 눈 블록
def lum(c): return c[...,:3].astype(int).mean(-1)
def put_eye(a,cx,cy):
    # 중심 주변에서 피부색(고리 최빈값) 찾고, 피부색과 다른 연결 영역을 눈으로 보고 지움
    yy,xx=np.ogrid[:96,:96]; r=np.sqrt((yy-cy)**2+(xx-cx)**2)
    ring=(r>=7)&(r<=9)&(a[:,:,3]>0)
    skin=np.array(Counter(map(tuple,a[ring])).most_common(1)[0][0],np.uint8)
    diff=np.abs(a[:,:,:3].astype(int)-skin[:3].astype(int)).sum(-1)>60
    lab,_=ndimage.label(diff&(r<7))
    l=lab[cy,cx] if lab[cy,cx] else (Counter(lab[(r<3)&(lab>0)]).most_common(1) or [(0,0)])[0][0]
    if l: a[lab==l]=skin
    ex,ey=cx-4,cy-3
    for y in range(6):
        for x in range(8):
            v=lum(EYE[y,x])
            if v<=45 or v>=240: a[ey+y,ex+x]=EYE[y,x]
            elif v<=80: a[ey+y,ex+x]=((EYE[y,x].astype(int)+skin.astype(int))//2).astype(np.uint8)
    return a
def outline(a):
    m=a[:,:,3]>0; t=np.pad(m,1)
    edge=m&~(t[:-2,1:-1]&t[2:,1:-1]&t[1:-1,:-2]&t[1:-1,2:])
    a[edge]=OUT; return a
def quant(a,n=40):
    m=a[:,:,3]>0; rgb=Image.fromarray(a[:,:,:3]); q=np.array(rgb.quantize(n,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE).convert('RGB'))
    b=a.copy(); b[m,:3]=q[m]; return b
EYES={"hawk":[(52,36)],"turtle":[(72,50)],"raccoon":[(48,36),(66,36)],"squirrel":[(61,37)],"rabbit":[(53,37)],"tadpole":[(68,50)],"hedgehog":[(55,48),(77,46)]}
import sys
for pid in sys.argv[1:]:
    src=f'final/{pid}1x/gen.png'; a=np.array(Image.open(src).convert('RGBA'))
    a=quant(a)
    for c in EYES.get(pid,[]): a=put_eye(a,*c)
    a=outline(a)
    d=f'final7/{pid}';os.makedirs(d,exist_ok=True);p=f'{d}/{pid}-final.png'
    Image.fromarray(a).save(p); print(pid,hashlib.sha256(open(p,'rb').read()).hexdigest()[:12])
