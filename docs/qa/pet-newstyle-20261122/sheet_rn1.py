from PIL import Image,ImageDraw,ImageFont
import numpy as np, os
exec(open('run_rn1.py').read().split('os.makedirs')[0].replace('from gen5 import *',''))
F=ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc',14)
G=ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc',26)
N={"sss_seraph":"수호천사","sss_demon":"심연 악마","sss_spirit":"별 정령","sss_lunar":"달의 마녀","ss_kirin":"천둥 기린","ss_crystal":"수정 드레이크","ss_salamander":"불꽃 도롱뇽","s_stag":"정령 새끼사슴","s_lanternfox":"등불 여우","s_mothcat":"나방 고양이","a_fennec":"사막여우","a_otter":"수달","a_owl":"부엉이","b_hamster":"햄스터","b_hedgehog":"고슴도치","b_sparrow":"참새","c_slime":"슬라임","c_mushroom":"버섯","c_puffbird":"솜뭉치새","d_frog":"개구리","d_chick":"병아리","d_mouse":"생쥐"}
os.makedirs('rn1/96',exist_ok=True)
def to96(k):
    a=np.array(Image.open(f'rn1/{k}.png').convert('RGBA')); a[a[...,3]<128]=0
    ys,xs=np.where(a[...,3]>0); c=a[ys.min():ys.max()+1,xs.min():xs.max()+1]
    c=np.repeat(np.repeat(c,2,0),2,1); h,w=c.shape[:2]; o=np.zeros((96,96,4),np.uint8)
    oy,ox=96-4-h,(96-w)//2; o[max(0,oy):oy+h,max(0,ox):ox+w]=c[max(0,-oy):,max(0,-ox):][:96,:96]
    Image.fromarray(o).save(f'rn1/96/{k}.png'); return Image.fromarray(o)
rows={}
for k in P: rows.setdefault(k.split('_')[0].upper(),[]).append(k)
CW,CH=150,180
W=Image.new('RGB',(70+8*CW,len(rows)*CH),(32,22,58)); d=ImageDraw.Draw(W)
for r,(g,ks) in enumerate(rows.items()):
    d.text((10,r*CH+60),g,font=G,fill=(235,200,120))
    c=0
    for k in ks:
        for v in 'AB':
            x,y=70+c*CW,r*CH; c+=1
            if not os.path.exists(f'rn1/{k}-{v}.png'): continue
            im=to96(f'{k}-{v}').resize((144,144),Image.NEAREST); W.paste(im,(x+3,y+4),im)
            d.text((x+6,y+152),f'{N[k]} {v}',font=F,fill=(230,220,240))
W.save('rn1/sheet.png')
