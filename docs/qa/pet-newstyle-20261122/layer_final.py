# 애니메이션 몸(PixelLab) + 윤곽 오라 + 발광 + 파티클 합성. 바닥 요소 없음.
exec(open('layer_all.py').read().split("G=[")[0])
import os
FRM={}
def frames(k):
    if k not in FRM:
        fs=[Image.open(f'anim/{k}_{i:02d}.png').convert('RGBA') for i in range(9)]
        bb=None
        for f in fs:
            b=f.getbbox(); bb=b if bb is None else (min(bb[0],b[0]),min(bb[1],b[1]),max(bb[2],b[2]),max(bb[3],b[3]))
        FRM[k]=[f.crop(bb) for f in fs]
    return FRM[k]
def render(k,t):
    au,R,steps,ops=D[k]; fs=frames(k); p=fs[t%8+1]; w,h=p.size; a=np.array(p).astype(int); u=2*math.pi*t/FR
    for op in ops:
        if op[0]=="glow":
            _,fn,box,col,per,seq=op; x0,y0,x1,y1=region(w,h,box)
            m=np.zeros((h,w),bool); m[y0:y1,x0:x1]=fn(a[y0:y1,x0:x1,0],a[y0:y1,x0:x1,1],a[y0:y1,x0:x1,2])&(a[y0:y1,x0:x1,3]>128)
            yy=np.arange(h)[:,None]*np.ones((1,w)); ph=0.5+0.5*np.sin(u*FR/per-(yy/h*3 if seq else 0))
            mix=np.clip(ph*0.8,0,1)[...,None]*m[...,None]; a[...,:3]=a[...,:3]*(1-mix)+np.array(col)*mix
        elif op[0]=="blink" and t%op[2] in (0,1):
            x0,y0,x1,y1=region(w,h,op[1]); sub=a[y0:y1,x0:x1]; m=WH(sub[...,0],sub[...,1],sub[...,2])&(sub[...,3]>128); sub[m,:3]=(40,50,30)
    base=Image.fromarray(np.clip(a,0,255).astype(np.uint8)); parts=[o for o in ops if o[0]=="part"]
    bg=bg0.copy(); W,H=bg.size; ox,oy=49-w//2,285-h
    if au:
        m=np.zeros((H,W),bool); m[oy:oy+h,ox:ox+w]=a[...,3]>128
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
    return bg.crop((49-TW//2,285+6-TH,49+TW//2,285+6)).resize((TW*Z,TH*Z),Image.NEAREST).convert('RGB')
G=[("SSS",["sss_seraph","sss_demon","sss_apostle","sss_lunar"]),("SS",["ss_golem","ss_knight","ss_storm"]),("S",["s_wisp","s_tome","s_fairy"]),("A",["a_fennec","a_otter","a_owl"]),("B",["b_hamster","b_hedgehog","b_sparrow"]),("C",["c_slime","c_mushroom","c_puffbird"]),("D",["d_frog","d_chick","d_mouse"])]
NM=dict(sss_seraph="수호천사",sss_demon="심연 악마",sss_apostle="별의 사도",sss_lunar="달의 마녀",ss_golem="룬 골렘",ss_knight="유령 기사",ss_storm="바람 정령",s_wisp="도깨비불",s_tome="마도서",s_fairy="숲 요정",a_fennec="사막여우",a_otter="수달",a_owl="부엉이",b_hamster="햄스터",b_hedgehog="고슴도치",b_sparrow="참새",c_slime="슬라임",c_mushroom="버섯",c_puffbird="솜뭉치새",d_frog="개구리",d_chick="병아리",d_mouse="생쥐")
os.makedirs('final_anim',exist_ok=True); F=ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc',14)
for g,ks in G:
    fr=[]
    for t in range(FR):
        S=Image.new('RGB',(TW*Z*len(ks),TW*Z+20),(20,16,14)); d=ImageDraw.Draw(S)
        for i,k in enumerate(ks): S.paste(render(k,t),(i*TW*Z,0)); d.text((i*TW*Z+6,TW*Z+2),f"{g} {NM[k]}",font=F,fill=(240,225,190))
        fr.append(S)
    fr[0].save(f'final_anim/{g}.gif',save_all=True,append_images=fr[1:],duration=100,loop=0); fr[5].save(f'final_anim/{g}_still.png')
