from PIL import Image,ImageDraw,ImageFont
import numpy as np, glob, os
from scipy import ndimage as nd
NAVY=(6,18,76)
PAL=np.array([NAVY,(24,26,38),(48,50,64),(80,82,96),(120,120,130),(165,163,165),(210,206,196),(240,236,224),(252,250,238),
 (120,100,40),(170,148,64),(214,192,98),(240,224,150),
 (70,48,34),(110,78,52),(150,112,74),(190,152,108),
 (30,90,60),(60,150,90),(140,210,150),
 (150,70,30),(220,120,50),(245,175,90),
 (40,100,110),(80,150,150),(150,200,195),
 (190,120,125),(235,180,175)],float)
def lab(c):
    c=c/255.0; return np.stack([c[...,0]*0.3+c[...,1]*0.59+c[...,2]*0.11, c[...,0]-c[...,1], (c[...,0]+c[...,1])/2-c[...,2]],-1)*[2.0,1,1]
PL=lab(PAL)
def unify(f):
    a=np.array(Image.open(f).convert('RGBA')); al=a[...,3]>128; a[~al]=0
    # 본체 외 조각 제거
    l,n=nd.label(al,structure=np.ones((3,3))); s=nd.sum(al,l,range(1,n+1)); keep=np.isin(l,1+np.where(s>=max(20,s.max()*0.02))[0]); a[~keep]=0; al=keep
    # 바닥 그림자: 하단 8줄의 반투명/회색 넓은 덩어리 제거
    ys,xs=np.where(al); bot=ys.max()
    c=a[...,:3].astype(int); sat=c.max(2)-c.min(2); lum=c.mean(2)
    sh=al&(np.arange(96)[:,None]>=bot-5)&(sat<25)&(lum<140)&(lum>30)
    a[sh]=0; al=a[...,3]>0
    # 팔레트 매핑
    px=lab(a[...,:3].astype(float)); d=((px[...,None,:]-PL[None,None])**2).sum(-1); idx=d.argmin(-1)
    a[...,:3]=PAL[idx].astype(np.uint8)
    # 1px 남색 외곽선 (바깥 경계), 안쪽 이중선 제거
    p=np.pad(al,1); edge=al&~(p[:-2,1:-1]&p[2:,1:-1]&p[1:-1,:-2]&p[1:-1,2:])
    a[edge,:3]=NAVY
    inner=al&~edge&nd.binary_dilation(edge)&(idx==0)
    for y,x in zip(*np.where(inner)):
        w=a[max(0,y-2):y+3,max(0,x-2):x+3]; ok=(w[...,3]>0)&~(np.all(w[...,:3]==NAVY,-1))
        if ok.sum(): 
            vals,cnt=np.unique(w[ok][:,:3],axis=0,return_counts=True); a[y,x,:3]=vals[cnt.argmax()]
    # 위치: 바닥 4px, 좌우 중앙
    ys,xs=np.where(a[...,3]>0); out=np.zeros_like(a)
    h,w=ys.max()-ys.min()+1,xs.max()-xs.min()+1
    oy=96-4-h; ox=(96-w)//2
    out[max(0,oy):oy+h,ox:ox+w]=a[ys.min():ys.max()+1,xs.min():xs.max()+1][max(0,-oy):]
    return out
os.makedirs('bk7/u',exist_ok=True)
for f in sorted(glob.glob('bk7/*_[12].png')):
    Image.fromarray(unify(f)).save('bk7/u/'+os.path.basename(f))
F=ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc',16)
G=[('sss_wolf','SSS 늑대'),('ss_fox','SS 여우'),('s_hamster','S 햄스터'),('a_hedgehog','A 고슴도치'),('b_turtle','B 거북'),('cd_duck','C/D 오리')]
W=Image.new('RGB',(6*200,2*230+10),(200,200,190)); d=ImageDraw.Draw(W)
for i,(k,n) in enumerate(G):
    for j in (1,2):
        im=Image.open(f'bk7/u/{k}_{j}.png').resize((192,192),Image.NEAREST); x,y=i*200,(j-1)*235
        W.paste(im,(x+4,y+30),im); d.text((x+6,y+6),f'{n} {j}번',font=F,fill=(0,0,0))
W.save('bk7/sheet.png')
