# sea3에서 산호·불가사리·보물상자·진주·해초를 지우고 모래 바닥으로 정리 (크레딧 없음)
# 양옆 바위는 원본 모양을 그대로 살리고, 바위 주변만 모래로 채운다.
import numpy as np, colorsys, math
from PIL import Image
from scipy.ndimage import binary_dilation, binary_closing, binary_opening, binary_fill_holes, label
rng=np.random.RandomState(5)
src=np.array(Image.open('sea3.png').convert('RGB')); a=src.copy(); H,W,_=a.shape
FLOOR=80
def hsv(p): return colorsys.rgb_to_hsv(*(p/255.0))
def deco(p):
    h,s,v=hsv(p)
    return ((h<0.05 or h>0.93) and s>0.5) or (0.05<=h<0.20 and s>0.72 and v>0.6) or (0.17<h<0.45 and s>0.2) or (0.5<h<0.64 and s>0.5 and v>0.7)
# 1) 장식 지우기 (배는 건드리지 않음). 아래쪽 바위 위 장식도 포함
boxes=[(0,44,46,FLOOR),(60,58,90,FLOOR),(148,58,200,FLOOR),(170,40,232,FLOOR),(80,66,118,FLOOR),(0,FLOOR,100,H),(160,FLOOR,W,H)]
dec=np.zeros((H,W),bool)
def deco2(p):   # 바위 위 잔여 조각용: 더 느슨한 기준
    h,s,v=hsv(p)
    return deco(p) or (0.5<h<0.66 and s>0.25 and v>0.55) or ((h<0.06 or h>0.9) and s>0.33 and v>0.45) or (v>0.8 and s<0.4) or (0.05<=h<0.2 and s>0.6 and v>0.7)
for x0,y0,x1,y1 in boxes:
    loose=(y1==H) or x1==46 or (x0==170)
    for y in range(y0,y1):
        for x in range(x0,x1):
            if (deco2 if loose else deco)(src[y,x]): dec[y,x]=True
dec[66:FLOOR,82:118]=True
dec=binary_dilation(dec,iterations=3)
dec[:, 100:160][FLOOR-4:,:]=False   # 가운데 아래쪽은 어차피 모래로 덮음
ok=~dec
for y in range(0,H):
    for x in range(W):
        if dec[y,x]:
            ys,xs=slice(max(0,y-7),min(H,y+8)),slice(max(0,x-7),min(W,x+8))
            m=ok[ys,xs]
            if m.sum()>3: a[y,x]=np.median(src[ys,xs][m],axis=0)
a[66:FLOOR,82:118]=src[66:FLOOR,122:158]
# 2) 바위 마스크: 좌우 상자 안에서 회색·어두운 픽셀 (모래·진주 제외)
rock=np.zeros((H,W),bool)
for x0,x1 in [(0,92),(165,W)]:
    for y in range(FLOOR-6,H):
        for x in range(x0,x1):
            h,s,v=hsv(a[y,x])
            if v<0.2 or (s<0.30 and v<0.72): rock[y,x]=True
rock=binary_closing(rock,iterations=2); rock=binary_opening(rock,iterations=1); rock=binary_fill_holes(rock)
lab,n=label(rock)
for i in range(1,n+1):
    if (lab==i).sum()<40: rock[lab==i]=False
# 3) 모래: 원본에서 장식 없는 모래 조각 이어 붙이기
low=np.zeros((H,W),bool)
for y in range(FLOOR,H):
    for x in range(W):
        p=src[y,x]; h,s,v=hsv(p)
        low[y,x]=deco(p) or (v>0.78 and s<0.4) or v<0.35
low=binary_dilation(low,iterations=2)
PW,PH=12,5
cand=[(x,y) for y in range(FLOOR+4,H-PH) for x in range(0,W-PW) if not low[y:y+PH,x:x+PW].any()]
sand=np.zeros_like(a); water=a.copy()
y=FLOOR-3
while y<H:
    x=-int(rng.randint(0,PW))
    while x<W:
        px,py=cand[rng.randint(len(cand))]
        ph=min(PH,H-y); x0=max(0,x); x1=min(W,x+PW)
        sand[y:y+ph,x0:x1]=src[py:py+ph,px+(x0-x):px+(x1-x)]
        x+=PW
    y+=PH
light=np.percentile(sand[FLOOR+3:H].reshape(-1,3),90,axis=0).astype('uint8')
dark=(np.median(sand[FLOOR+3:FLOOR+9].reshape(-1,3),axis=0)*0.80).astype('uint8')
out=a.copy()
for x in range(W):
    fy=FLOOR+int(round(1.6*math.sin(x*0.17)+1.0*math.sin(x*0.43+1.3)))
    for yy in range(FLOOR-3,H):
        if rock[yy,x]: continue            # 바위는 원본 그대로
        if yy<fy: out[yy,x]=water[yy,x]
        elif yy==fy: out[yy,x]=light
        elif yy==fy+1: out[yy,x]=dark
        else: out[yy,x]=sand[yy,x]
# 바위 밑 그림자: 바위 바로 아래 모래 3줄을 어둡게
for x in range(W):
    for yy in range(FLOOR-3,H-1):
        if rock[yy,x] and not rock[yy+1,x]:
            for k in range(1,4):
                if yy+k<H and not rock[yy+k,x]:
                    out[yy+k,x]=(out[yy+k,x]*(0.70+0.07*k)).astype('uint8')
# 4) 마무리: 바위 위에 남은 색 잔여물(초록·주황·분홍)을 주변 바위색으로 덮기
near=binary_dilation(rock,iterations=3)
def bad(p):
    h,s,v=hsv(p)
    return (0.17<h<0.5 and s>0.15) or (s>0.4 and (h<0.12 or h>0.9)) or (0.5<h<0.66 and s>0.25 and v>0.5)
for _ in range(2):
    mark=np.zeros((H,W),bool)
    for y in range(H):
        for x in range(W):
            if near[y,x] and (x<100 or x>160) and bad(out[y,x]): mark[y,x]=True
    mark=binary_dilation(mark,iterations=1)&near
    good=near&~mark
    nxt=out.copy()
    for y in range(H):
        for x in range(W):
            if mark[y,x]:
                ys,xs=slice(max(0,y-6),min(H,y+7)),slice(max(0,x-6),min(W,x+7))
                m=good[ys,xs]&rock[ys,xs]
                if m.sum()>2: nxt[y,x]=np.median(out[ys,xs][m],axis=0)
    out=nxt
Image.fromarray(out).save('sea3_clean.png')
Image.fromarray(out).resize((W*4,H*4),Image.NEAREST).save('sea3_clean_x4.png')
