# 침식 레이어 정지 시안: 원본 스프라이트는 그대로 두고, 그 위에 바닥부터 올라오는 그림자 레이어를 덮는다(게임에서는 셰이더로 같은 계산)
from PIL import Image,ImageDraw,ImageFont
import numpy as np,json
LV={"a":0.18,"s":0.38,"ss":0.62,"sss":0.86}   # 등급별 침식 높이(몸 아래에서부터 비율)
SH=np.array([(22,14,40),(40,24,70),(64,40,104)])  # 그림자 3톤(남보라)
EDGE=np.array((176,120,255))                     # 침식 경계 발광
def noise(h,w,seed,cell=3):
    r=np.random.default_rng(seed); g=r.random((h//cell+2,w//cell+2))
    return np.kron(g,np.ones((cell,cell)))[:h,:w]
def erode(im,lv,seed=1):
    a=np.array(im.convert('RGBA')).astype(int); m=a[...,3]>=128
    ys=np.where(m.any(1))[0]; top,bot=ys.min(),ys.max(); h=bot-top+1
    yy=np.arange(a.shape[0])[:,None]; frac=(bot-yy)/h            # 0=발끝, 1=머리끝
    edge_line=lv+ (noise(*m.shape,seed)-.5)*.22                 # 들쭉날쭉한 경계(픽셀 3칸 단위)
    sh=m&(frac<=edge_line)
    lum=(a[...,:3]@[.3,.59,.11])/255; tone=np.clip((lum*3).astype(int),0,2)
    out=a.copy(); out[sh,:3]=SH[tone[sh]]
    # 경계 1픽셀 발광: 그림자 바로 위의 그림자 아닌 픽셀
    up=np.zeros_like(sh); up[:-1]=sh[1:]; e=m&~sh&up
    out[e,:3]=EDGE
    return Image.fromarray(out.astype(np.uint8))
src=json.load(open('final/source.json'))
order=["sss_seraph","sss_demon","sss_apostle","sss_lunar","ss_golem","ss_knight","ss_storm","s_wisp","s_tome","s_rock","a_fennec","a_otter","a_owl"]
gn=Image.open('rn3/style/night_game.png').convert('RGBA'); crop=(18,220,108,296); Z=3; cw=(crop[2]-crop[0])*Z; ch=(crop[3]-crop[1])*Z
F=ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc',13)
N={"sss_seraph":"수호천사 SSS","sss_demon":"심연 악마 SSS","sss_apostle":"별의 사도 SSS","sss_lunar":"달의 마녀 SSS","ss_golem":"골렘 SS","ss_knight":"유령 기사 SS","ss_storm":"폭풍 SS","s_wisp":"도깨비불 S","s_tome":"마도서 S","s_rock":"이끼 바위 S","a_fennec":"사막여우 A","a_otter":"수달 A","a_owl":"부엉이 A"}
cols=5; W=Image.new('RGB',(cols*(cw+6),((len(order)+cols-1)//cols)*(ch+22)),(20,20,30)); d=ImageDraw.Draw(W)
for n,k in enumerate(order):
  bg=gn.copy(); bg.paste(bg.crop((20,262,38,284)),(39,262)); bg.paste(bg.crop((20,262,38,284)),(46,262))
  p=erode(Image.open(f'final/{k}.png'),LV[k.split('_')[0]],n); p=p.crop(p.getbbox())
  bg.alpha_composite(p,(49-p.size[0]//2,285-p.size[1]))
  t=bg.crop(crop).resize((cw,ch),Image.NEAREST); x=(n%cols)*(cw+6); y=(n//cols)*(ch+22)
  W.paste(t,(x,y)); d.text((x+4,y+ch+2),N[k],font=F,fill=(240,225,190))
W.save('final/erosion_mock.png')
