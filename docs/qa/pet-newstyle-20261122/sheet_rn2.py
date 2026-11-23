from PIL import Image,ImageDraw,ImageFont
import numpy as np, os
exec(open('run_rn2.py').read().split('os.makedirs')[0].replace('from gen5 import *',''))
F=ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc',14)
G=ImageFont.truetype('/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc',26)
N={"sss_seraph":"수호천사","sss_demon":"심연 악마","sss_apostle":"별의 사도","sss_lunar":"달의 마녀","ss_golem":"태엽 골렘","ss_knight":"유령 기사","ss_storm":"폭풍 구름","s_wisp":"촛불 도깨비불","s_tome":"걷는 마도서","s_rock":"이끼 바위","a_fennec":"사막여우","a_otter":"수달","a_owl":"부엉이","b_hamster":"햄스터","b_hedgehog":"고슴도치","b_sparrow":"참새","c_slime":"슬라임","c_mushroom":"버섯","c_puffbird":"솜뭉치새","d_frog":"개구리","d_chick":"병아리","d_mouse":"생쥐"}
os.makedirs('rn2/96',exist_ok=True)
def place(k):  # 확대 없이 96 캔버스 바닥 4px·좌우 중앙
    a=np.array(Image.open(f'rn2/{k}.png').convert('RGBA')); a[a[...,3]<128]=0
    ys,xs=np.where(a[...,3]>0); c=a[ys.min():ys.max()+1,xs.min():xs.max()+1]; h,w=c.shape[:2]
    o=np.zeros((96,96,4),np.uint8); oy,ox=max(0,96-4-h),(96-w)//2; o[oy:oy+h,ox:ox+w]=c[:96-oy]
    Image.fromarray(o).save(f'rn2/96/{k}.png'); return Image.fromarray(o),w,h
rows={}
for k in P: rows.setdefault(k.split('_')[0].upper(),[]).append(k)
CW,CH=200,230; sz=[]
W=Image.new('RGB',(70+8*CW,len(rows)*CH),(32,22,58)); d=ImageDraw.Draw(W)
for r,(g,ks) in enumerate(rows.items()):
    d.text((10,r*CH+80),g,font=G,fill=(235,200,120)); c=0
    for k in ks:
        for v in 'AB':
            x,y=70+c*CW,r*CH; c+=1
            im,w,h=place(f'{k}-{v}'); sz.append((f'{k}-{v}',w,h))
            im=im.resize((192,192),Image.NEAREST); W.paste(im,(x+4,y+4),im)
            d.text((x+8,y+202),f'{N[k]} {v} {w}×{h}',font=F,fill=(230,220,240))
W.save('rn2/sheet.png')
