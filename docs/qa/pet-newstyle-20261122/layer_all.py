# 22종 포인트 레이어 + A~SSS 윤곽 오라 시안 (바닥 요소 없음). 원본 스프라이트 불변.
from PIL import Image,ImageDraw,ImageFont
import numpy as np,math,random
from scipy.ndimage import distance_transform_edt as EDT
FR=24; Z=3; TW=64; TH=64
bg0=Image.open('rn3/style/night_game.png').convert('RGBA'); bg0.paste(bg0.crop((20,262,38,284)),(39,262)); bg0.paste(bg0.crop((20,262,38,284)),(46,262))
WH=lambda r,g,b:(r>222)&(g>222)&(b>200)
CY=lambda r,g,b:(b>150)&(g>130)&(r<150)
YE=lambda r,g,b:(r>205)&(g>140)&(b<90)
FI=lambda r,g,b:(r>215)&(g>110)&(b<130)
RD=lambda r,g,b:(r>140)&(g<80)&(b<80)
MO=lambda r,g,b:(r>235)&(g>220)&(b>130)
GR=lambda r,g,b:(g>150)&(r<150)&(b<150)
PK=lambda r,g,b:(r>200)&(g>110)&(g<190)&(b>100)&(b<200)&(r>g+30)
AL=lambda r,g,b:np.ones_like(r,bool)
# ops: shift(box,ax,ay,per,wave) / breathe(box,amt) / glow(mask,box,color,per,seq) / blink(box) / part(kind,colors,n,per)
D={ # key:(오라 팔레트 또는 None, R, 단수, [ops])
"d_frog":(None,0,0,[("breathe",(.25,.5,.75,.9),1),("blink",(.4,.1,.9,.5),12),("part","hop",[(120,190,255)],2,12)]),
"d_chick":(None,0,0,[("shift",(.35,0,.75,.2),1,0,12,"x"),("shift",(.0,.35,.3,.75),0,1,6,"y"),("part","hop",[(220,200,150)],2,12)]),
"d_mouse":(None,0,0,[("shift",(0,.4,.4,1),0,1,24,"x"),("shift",(.4,0,.8,.3),1,0,12,"y")]),
"c_slime":(None,0,0,[("glow",WH,(0,0,1,.5),(255,255,255),12,0),("shift",(.15,0,.85,.4),0,1,12,"y"),("part","up",[(200,240,255)],3,12)]),
"c_mushroom":(None,0,0,[("glow",lambda r,g,b:(r>235)&(g>200)&(b>150),(0,0,1,.45),(255,255,200),24,0),("part","down",[(255,240,200)],2,12)]),
"c_puffbird":(None,0,0,[("breathe",(0,.2,1,1),1),("part","drift",[(255,255,255)],2,12)]),
"b_hamster":(None,0,0,[("shift",(.35,.55,.75,.85),0,1,4,"y"),("glow",PK,(0,.2,1,.7),(255,150,170),12,0),("shift",(.1,0,.5,.2),0,-1,12,"y")]),
"b_hedgehog":(None,0,0,[("shift",(0,0,.7,.5),0,-1,12,"x"),("shift",(.75,.4,1,.7),0,1,6,"y"),("part","down",[(190,130,60)],2,12)]),
"b_sparrow":(None,0,0,[("shift",(0,.4,.35,.8),0,1,6,"y"),("shift",(.3,.35,.7,.7),0,-1,12,"y")]),
"a_fennec":([(255,240,190),(235,200,120),(140,110,60)],1.8,1,[("glow",lambda r,g,b:(r>235)&(g>180)&(b>130),(0,0,1,.7),(255,245,200),24,0),("part","hop",[(236,205,140),(255,235,180)],3,12)]),
"a_otter":([(220,245,255),(90,170,235),(30,70,130)],2.0,2,[("glow",lambda r,g,b:(b>r+20)&(b>130),(.2,.4,.8,.8),(200,240,255),12,0),("part","up",[(170,220,255),(255,255,255)],3,12)]),
"a_owl":([(255,250,200),(190,190,230),(60,60,130)],2.0,2,[("glow",YE,(0,0,1,.5),(255,255,160),24,0),("shift",(.1,0,.9,.2),0,-1,24,"x"),("part","down",[(220,220,240)],2,12)]),
"s_wisp":([(255,240,170),(255,150,50),(150,60,30)],2.6,2,[("shift",(.3,0,.8,.3),1,0,12,"x"),("glow",lambda r,g,b:(r>230)&(g>180)&(b>120),(0,.25,1,1),(255,245,200),24,0),("part","up",[(255,170,60),(255,110,40)],4,12)]),
"s_tome":([(240,225,255),(150,100,230),(50,30,110)],2.4,2,[("glow",WH,(.3,.3,.8,.7),(255,255,255),12,0),("glow",YE,(0,0,1,1),(255,255,200),12,0),("part","orbit",[(220,190,255),(255,255,255)],4,24)]),
"s_fairy":([(225,255,215),(80,215,120),(20,100,60)],2.4,2,[("glow",CY,(0,0,1,.4),(210,255,255),24,0),("glow",WH,(0,0,1,.3),(255,255,255),12,0),("part","up",[(190,255,150),(255,255,200)],5,12)]),
"s_rock":([(220,255,200),(70,200,110),(20,90,50)],2.4,2,[("shift",(.35,0,.65,.25),1,0,12,"x"),("glow",CY,(0,.2,1,.7),(200,255,255),24,0),("part","up",[(190,255,150),(120,220,90)],3,12)]),
"s_fairy":([(225,255,215),(90,215,120),(25,95,55)],2.4,2,[("glow",CY,(0,0,1,.5),(210,255,255),24,0),("glow",lambda r,g,b:(r>235)&(g>235)&(b>200),(0,0,1,.3),(255,255,255),12,0),("part","up",[(190,255,160),(255,255,200)],5,12)]),
"ss_golem":([(220,255,225),(60,210,110),(15,80,50)],3.2,3,[("glow",CY,(0,0,1,1),(215,255,235),24,1),("shift",(.0,.1,.25,.5),0,-1,12,"y"),("shift",(.75,.1,1,.5),0,-1,12,"y"),("part","up",[(120,110,95),(200,255,220)],4,12)]),
"ss_knight":([(225,235,255),(150,120,230),(50,40,110)],3.2,3,[("glow",CY,(0,0,1,.9),(220,255,255),24,0),("shift",(0,.6,.5,1),1,0,12,"y"),("part","up",[(180,230,255),(210,170,255)],4,12)]),
"ss_storm":([(240,255,245),(120,230,200),(30,110,120)],3.2,3,[("shift",(.0,.4,.3,1),1,0,12,"y"),("glow",lambda r,g,b:(r>230)&(g>200),(.6,.2,1,.8),(255,255,200),6,0),("part","orbit",[(220,255,245),(255,255,255)],5,12)]),
"sss_seraph":([(255,250,210),(255,205,90),(170,110,40)],3.2,3,[("shift",(0,.1,.35,.6),-1,0,24,"x"),("shift",(.65,.1,1,.6),1,0,24,"x"),("glow",lambda r,g,b:(r>225)&(g>185)&(b<215),(.2,0,.8,.2),(255,255,235),24,0),("part","down",[(255,240,170),(255,255,255)],6,12),("part","up",[(255,245,190)],3,24)]),
"sss_demon":([(255,200,120),(230,50,40),(90,10,30)],3.4,3,[("glow",RD,(0,0,1,1),(255,170,90),12,0),("shift",(0,.4,.25,1),0,1,12,"y"),("shift",(.75,.4,1,1),0,1,12,"y"),("part","up",[(255,140,50),(255,70,40)],6,12)]),
"sss_apostle":([(255,250,200),(110,110,230),(40,30,100)],3.4,3,[("glow",lambda r,g,b:(r>220)&(g>170)&(b<120),(0,0,1,.5),(255,255,230),12,0),("shift",(.2,0,.8,.25),0,-1,24,"y"),("part","orbit",[(255,240,160),(255,255,255)],6,24)]),
"sss_lunar":([(250,250,255),(190,170,240),(70,60,130)],3.4,3,[("glow",MO,(.7,.1,1,.5),(255,255,255),24,0),("shift",(0,.4,.3,1),-1,0,24,"x"),("shift",(.7,.55,1,1),1,0,24,"x"),("part","down",[(235,235,255),(200,180,255)],5,12)]),
}
def region(w,h,b): return (int(b[0]*w),int(b[1]*h),max(int(b[0]*w)+1,int(b[2]*w)),max(int(b[1]*h)+1,int(b[3]*h)))
def render(k,t):
    p=Image.open(f'final/{k}.png').convert('RGBA'); p=p.crop(p.getbbox()); w,h=p.size
    au,R,steps,ops=D[k]; a=np.array(p).astype(int); u=2*math.pi*t/FR
    base=p.copy(); extra=[]; parts=[]
    for op in ops:
        if op[0]=="glow":
            _,fn,box,col,per,seq=op; x0,y0,x1,y1=region(w,h,box)
            m=np.zeros((h,w),bool); m[y0:y1,x0:x1]=fn(a[y0:y1,x0:x1,0],a[y0:y1,x0:x1,1],a[y0:y1,x0:x1,2])&(a[y0:y1,x0:x1,3]>128)
            yy=np.arange(h)[:,None]*np.ones((1,w)); ph=0.5+0.5*np.sin(u*FR/per-(yy/h*3 if seq else 0))
            mix=np.clip(ph*0.8,0,1)[...,None]*m[...,None]; a[...,:3]=a[...,:3]*(1-mix)+np.array(col)*mix
        elif op[0]=="blink":
            _,box,per=op; 
            if t%per in (0,1):
                x0,y0,x1,y1=region(w,h,box); m=WH(a[y0:y1,x0:x1,0],a[y0:y1,x0:x1,1],a[y0:y1,x0:x1,2])&(a[y0:y1,x0:x1,3]>128); sub=a[y0:y1,x0:x1]; sub[m,:3]=(40,50,30)
    base=Image.fromarray(np.clip(a,0,255).astype(np.uint8))
    for op in ops:
        if op[0]=="shift":
            _,box,dx,dy,per,ax=op; x0,y0,x1,y1=region(w,h,box); s=math.sin(2*math.pi*t/per)
            ox=round(dx*s); oy=round(dy*s)
            if ax=="x": oy=round(dy*s) 
            piece=base.crop((x0,y0,x1,y1)); base.alpha_composite(piece,(x0+ox,y0+oy)) if (ox or oy) else None
        elif op[0]=="breathe":
            _,box,amt=op; x0,y0,x1,y1=region(w,h,box); s=1 if math.sin(u)>0 else 0
            if s: piece=base.crop((x0,y0,x1,y1)); base.alpha_composite(piece,(x0,y0-1)) if False else base.alpha_composite(piece.resize((x1-x0+1,y1-y0),Image.NEAREST),(x0-0,y0))
        elif op[0]=="part": parts.append(op)
    bg=bg0.copy(); W,H=bg.size; ox,oy=49-w//2,285-h; bob=round(0.6*math.sin(u)); oy+=bob
    if au:
        m=np.zeros((H,W),bool); m[oy:oy+h,ox:ox+w]=np.array(base)[...,3]>128
        d=EDT(~m); yy,xx=np.mgrid[0:H,0:W]; up=np.clip((oy+h-yy)/h,0,1)
        n=(np.sin(xx//2*1.3+u-yy//2*0.9)+np.sin(xx//2*0.7-2*u+yy//2*0.5)+np.sin(yy//2*1.7-3*u+xx//2*0.4))/3
        Rr=R*(0.55+0.45*up)+n*R*0.55+up*1.2; out=np.array(bg).astype(float)
        idx=[2,1,0] if steps==3 else ([2,1] if steps==2 else [1]); al=[.55,.7,.85] if steps==3 else [.6,.8] if steps==2 else [.5]
        for b in range(steps):
            mk=(d>0)&(d<=Rr*(1-b*.38)); out[mk,:3]=np.minimum(255,out[mk,:3]+np.array(au[idx[b]])*al[b]*(.55 if b==0 else .7))
        bg=Image.fromarray(out.astype(np.uint8)).convert('RGBA')
    bg.alpha_composite(base,(ox,oy)); px=bg.load(); r=random.Random(k)
    for (_,kind,cols,n,per) in parts:
        for i in range(n):
            x0,y0=r.uniform(-1,1),r.uniform(0,1); ph=((t/per)+y0)%1.0; cx=ox+w/2; cy=oy+h/2
            if kind=="up": X=cx+x0*w*.45+1.5*math.sin(2*math.pi*(ph+x0)); Y=oy+h*.8-ph*h*1.3
            elif kind=="down": X=cx+x0*w*.5+1.5*math.sin(2*math.pi*ph); Y=oy-2+ph*h*1.1
            elif kind=="hop": X=cx+x0*w*.4; Y=oy+h-1-ph*4
            elif kind=="drift": X=cx+x0*w*.6+3*math.sin(2*math.pi*ph); Y=oy+h*.3+ph*h*.4
            else: ang=2*math.pi*(ph+i/n); X=cx+math.cos(ang)*(w*.6+3); Y=cy+math.sin(ang)*(h*.22)-h*.1
            X=int(X);Y=int(Y)
            if 0<=X<W and 0<=Y<H: px[X,Y]=(*cols[i%len(cols)],255)
    cxp=49; return bg.crop((cxp-TW//2,285+6-TH,cxp+TW//2,285+6)).resize((TW*Z,TH*Z),Image.NEAREST).convert('RGB')
G=[("SSS",["sss_seraph","sss_demon","sss_apostle","sss_lunar"]),("SS",["ss_golem","ss_knight","ss_storm"]),("S",["s_wisp","s_tome","s_rock"]),("A",["a_fennec","a_otter","a_owl"]),("B",["b_hamster","b_hedgehog","b_sparrow"]),("C",["c_slime","c_mushroom","c_puffbird"]),("D",["d_frog","d_chick","d_mouse"])]
NM=dict(sss_seraph="수호천사",sss_demon="심연 악마",sss_apostle="별의 사도",sss_lunar="달의 마녀",ss_golem="룬 골렘",ss_knight="유령 기사",ss_storm="바람 정령",s_wisp="도깨비불",s_tome="마도서",s_rock="이끼 바위",a_fennec="사막여우",a_otter="수달",a_owl="부엉이",b_hamster="햄스터",b_hedgehog="고슴도치",b_sparrow="참새",c_slime="슬라임",c_mushroom="버섯",c_puffbird="솜뭉치새",d_frog="개구리",d_chick="병아리",d_mouse="생쥐")
import os; os.makedirs('layer_all',exist_ok=True)
F=ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc',14)
for g,ks in G:
    frames=[]
    for t in range(FR):
        S=Image.new('RGB',(TW*Z*len(ks),TW*Z+20),(20,16,14)); d=ImageDraw.Draw(S)
        for i,k in enumerate(ks): S.paste(render(k,t),(i*TW*Z,0)); d.text((i*TW*Z+6,TW*Z+2),f"{g} {NM[k]}",font=F,fill=(240,225,190))
        frames.append(S)
    frames[0].save(f'layer_all/{g}.gif',save_all=True,append_images=frames[1:],duration=100,loop=0); frames[6].save(f'layer_all/{g}_still.png')
