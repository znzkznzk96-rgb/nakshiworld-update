from PIL import Image,ImageDraw,ImageFont
import numpy as np, os
F=ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc',15)
R=[("SSS",[("sss_otter","낚시왕 수달"),("sss_dragon","천둥 해룡"),("sss_whale","황금 고래"),("sss_wolf","균열 늑대")]),
("SS",[("ss_kingfisher","사냥 물총새"),("ss_fox","별꼬리 여우"),("ss_hawk","불꽃 매")]),
("S",[("s_penguin","꼬마 펭귄"),("s_frog","샘물 개구리"),("s_hamster","보석 햄스터")]),
("A",[("a_turtle","배낭 거북"),("a_chick","불꽃 병아리"),("a_hedgehog","밤송이 고슴도치")]),
("B",[("b_sparrow","찌 참새"),("b_raccoon","장사 너구리"),("b_boar","꼬마 멧돼지")]),
("C",[("c_snail","물방울 달팽이"),("c_arrow","비상구 화살표"),("c_pouch","잔향 주머니")]),
("D",[("d_tadpole","웅덩이 올챙이"),("d_door","문틈 보초"),("d_reflect","수조 반사체")])]
os.makedirs('bk8/96',exist_ok=True)
def to96(k):
    a=np.array(Image.open(f'bk8/{k}.png').convert('RGBA')); a[a[...,3]<128]=0
    ys,xs=np.where(a[...,3]>0); c=a[ys.min():ys.max()+1,xs.min():xs.max()+1]
    c=np.repeat(np.repeat(c,2,0),2,1); h,w=c.shape[:2]; o=np.zeros((96,96,4),np.uint8)
    oy,ox=96-4-h,(96-w)//2; o[max(0,oy):oy+h,max(0,ox):ox+w]=c[max(0,-oy):,max(0,-ox):][:96,:96]
    Image.fromarray(o).save(f'bk8/96/{k}.png'); return Image.fromarray(o)
CW,CH=200,230
W=Image.new('RGB',(90+4*CW,7*CH),(32,22,58)); d=ImageDraw.Draw(W)
for r,(g,items) in enumerate(R):
    d.text((14,r*CH+90),g,font=ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc',30),fill=(235,200,120))
    for c,(k,n) in enumerate(items):
        im=to96(k).resize((192,192),Image.NEAREST); x,y=90+c*CW,r*CH
        W.paste(im,(x+4,y+4),im); d.text((x+8,y+202),n,font=F,fill=(230,220,240))
W.save('bk8/sheet22.png')
