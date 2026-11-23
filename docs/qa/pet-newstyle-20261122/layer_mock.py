# 디테일+오로라+파티클 움직이는 시안(바닥 문양 없음). 원본 스프라이트 불변, 게임 해상도에서 합성 후 3배 확대 저장
from PIL import Image
import numpy as np,math
FR=12; crop=(18,220,108,296); Z=4
gn=Image.open('rn3/style/night_game.png').convert('RGBA')
bg0=gn.copy(); bg0.paste(bg0.crop((20,262,38,284)),(39,262)); bg0.paste(bg0.crop((20,262,38,284)),(46,262))
# name:(aurora색, 단수, 글로우조건, 글로우색, 파티클색, 파티클방향)
C={
 "sss_seraph":dict(au=[(255,250,210),(255,205,90),(170,110,40)],steps=3,R=3.2,gl=lambda r,g,b:(r>225)&(g>185)&(b<215),gc=(255,255,235),pc=[(255,240,170),(255,255,255)],dir=-1,n=7,wing=True),
 "ss_golem":dict(au=[(200,255,250),(60,210,190),(20,90,100)],steps=3,R=3.2,gl=lambda r,g,b:(b>150)&(g>130)&(r<140),gc=(190,255,250),pc=[(90,80,70),(120,110,95)],dir=-1,n=5,seq=True),
 "s_wisp":dict(au=[(255,240,170),(255,150,50),(150,60,30)],steps=2,R=2.6,gl=lambda r,g,b:(r>215)&(g>110)&(b<130),gc=(255,235,150),pc=[(255,170,60),(255,110,40)],dir=-1,n=6,sway=True),
 "a_fennec":dict(au=[(255,240,190),(235,200,120),(140,110,60)],steps=1,R=1.8,gl=None,gc=None,pc=[(236,205,140),(255,235,180)],dir=1,n=5),
}
def aurora(shape,cx,cy,rx,ry,col,steps,t):
    H,W=shape; yy,xx=np.mgrid[0:H,0:W]
    wob=1+0.07*math.sin(2*math.pi*t/FR)
    d=np.sqrt(((xx-cx)/(rx*wob))**2+((yy-cy)/(ry*wob))**2)
    L=np.zeros((H,W,4)); 
    for k in range(steps):                     # 바깥 단일수록 성긴 체크 도트
        lim=1.0+0.55*(steps-1-k)*0.9 if False else 1.0+0.45*(steps-1-k)
        band=(d<=lim)
        chk=((xx+yy+(t//3 if k==steps-1 else 0))%2==0) if k>=1 and k==steps-1 and steps>1 else np.ones_like(band)
        m=band&chk
        L[m]=(*col,[110,80,55][min(steps-1-k,2)] if steps>1 else 90)
    return L

from scipy.ndimage import distance_transform_edt as EDT
def flame_aura(bg,p,ox,oy,c,t):
    H,W=bg.size[1],bg.size[0]; m=np.zeros((H,W),bool)
    m[oy:oy+p.size[1],ox:ox+p.size[0]]=np.array(p)[...,3]>128
    d=EDT(~m); yy,xx=np.mgrid[0:H,0:W]; top=oy; hh=p.size[1]
    up=np.clip((oy+hh-yy)/hh,0,1)                     # 0=발 1=머리 (위로 갈수록 더 길게 일렁임)
    u=t/FR*2*math.pi
    n=(np.sin(xx//2*1.3+u*1.0-yy//2*0.9)+np.sin(xx//2*0.7-u*2.0+yy//2*0.5)+np.sin(yy//2*1.7-u*3.0+xx//2*0.4))/3  # 위로 흐르는 2px 단위 잡음
    Rr=c['R']*(0.55+0.45*up)+n*c['R']*0.55+up*1.2
    out=np.array(bg).astype(float)
    cols=c['au']; ns=c['steps']
    for band in range(ns):                              # 바깥부터: 어두운 외곽 -> 중간 -> 밝은 코어
        lim=Rr*(1.0-band*0.38)
        mk=(d>0)&(d<=lim)
        col=np.array(cols[2-band if ns==3 else (2-band if band==0 else 0) if False else [2,1,0][band] if ns==3 else [2,1][band] if ns==2 else 1]) 
        a=[0.55,0.7,0.85][band] if ns==3 else [0.6,0.8][band] if ns==2 else 0.5
        out[mk,:3]=np.minimum(255,out[mk,:3]+col*a*(0.55 if band==0 else 0.7))   # 가산 블렌딩
    return Image.fromarray(out.astype(np.uint8))
def frame(k,c,t,rng_pos):
    p=Image.open(f'final/{k}.png').convert('RGBA'); p=p.crop(p.getbbox()); w,h=p.size
    bg=bg0.copy(); H=bg.size[1]; W=bg.size[0]
    ox,oy=49-w//2,285-h; cx,cy=49,285-h/2
    a=np.array(p).astype(int)
    if c['gl'] is not None:
        m=c['gl'](a[...,0],a[...,1],a[...,2])&(a[...,3]>128)
        yy=np.arange(h)[:,None]*np.ones((1,w))
        if c.get('seq'):   ph=0.5+0.5*np.sin(2*math.pi*(t/FR)-yy/h*3)
        elif c.get('wing'): ph=0.5+0.5*math.sin(2*math.pi*t/FR)*np.ones((h,w))
        else: ph=0.5+0.5*math.sin(2*math.pi*t/FR*2)*np.ones((h,w))
        mix=np.clip(ph*0.75,0,1)[...,None]*m[...,None]
        a[...,:3]=a[...,:3]*(1-mix)+np.array(c['gc'])*mix
    p=Image.fromarray(np.clip(a,0,255).astype(np.uint8))
    if c.get('sway'):  # 윗부분 불꽃을 좌우 1px 흔들기
        top=p.crop((0,0,w,h//3)); rest=p.crop((0,h//3,w,h)); q=Image.new('RGBA',(w,h)); q.paste(rest,(0,h//3)); q.alpha_composite(top,(round(math.sin(2*math.pi*t/FR*2)),0)); p=q
    bob=round(0.6*math.sin(2*math.pi*t/FR))  # 기본 대기 모션: 위아래 1px
    bg=flame_aura(bg,p,ox,oy+bob,c,t).convert('RGBA'); bg.alpha_composite(p,(ox,oy+bob))
    px=bg.load()
    for (x0,y0,sp,ci) in rng_pos:   # 파티클: 1~2px, 12프레임 루프
        ph=((t/FR)*sp+y0/20)%1.0
        yy_=int(cy+h*0.35-ph*h*1.3) if c['dir']<0 else int(oy+h*0.4+ph*h*0.55)
        xx_=int(cx+x0*w*0.6+2*math.sin(2*math.pi*(ph+x0)))
        if 0<=xx_<W and 0<=yy_<H: px[xx_,yy_]=(*c['pc'][ci%len(c['pc'])],255 if ph<0.8 else 120)
    return bg.crop(crop).resize(((crop[2]-crop[0])*Z,(crop[3]-crop[1])*Z),Image.NEAREST).convert('RGB')
import random
for k,c in C.items():
    r=random.Random(k); pos=[(r.uniform(-1,1),r.uniform(0,20),r.choice([1,1,2]),i) for i in range(c['n'])]
    fs=[frame(k,c,t,pos) for t in range(FR)]
    fs[0].save(f'layer_mock/{k}.gif',save_all=True,append_images=fs[1:],duration=100,loop=0)
    fs[3].save(f'layer_mock/{k}_still.png')
