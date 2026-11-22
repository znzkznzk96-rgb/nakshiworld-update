import sys,os,json,base64,time,io
import numpy as np
from PIL import Image
exec(open('run3.py').read().split("for k,pid in enumerate")[0])
import gen12 as G
BG=(32,22,58)
T={"v1":(74,72),"v4":(72,72),"v6":(72,72)}
X={"v1":"","v4":" Turn to face right in a 3/4 side view and hold the spear diagonally forward.","v6":""}
D="Keep the same character and details. Redraw to match the rendering of existing top-rank pets: soft lavender and violet palette, 2-3 flat shade colors, uniform 1px navy outline, no anti-aliasing, no noise, solid black hood void with small glowing eyes.{x} Compact wide pose. Remove ground shadow, halo and background. Transparent background."
for k,(w,h) in T.items():
    a=Image.open(f'bk32/{k}_f.png').convert('RGBA'); bb=a.getbbox(); c=a.crop(bb)
    ar=w/h; cw,ch=c.size
    W_=max(cw,int(round(ch*ar))); H_=max(ch,int(round(cw/ar)))
    can=Image.new('RGBA',(W_,H_),BG+(255,)); can.paste(c,((W_-cw)//2,H_-ch),c)
    S=5; inp=can.convert('RGB').resize((w*S,h*S),Image.NEAREST); inp.save(f'bk33/in/{k}.png')
    out=f'bk33/s1/{k}'
    if not os.path.exists(out+'.png'):
        req={"image":{"type":"base64","base64":base64.b64encode(open(f'bk33/in/{k}.png','rb').read()).decode()},"image_size":{"width":w*S,"height":h*S},"output_size":{"width":w,"height":h},"fixer":True,"init_image_strength":700,"seed":2026123500+int(k[-1])}
        r=G.call('https://api.pixellab.ai/v2/image-to-pixelart',json.dumps(req).encode())
        for _ in range(30):
            if 'image' in r or r.get('status') in('completed','failed'): break
            time.sleep(6); r=G.call('https://api.pixellab.ai/v2/background-jobs/'+r['background_job_id'])
        img=r.get('image') or r.get('last_response',{}).get('image')
        if not img: print('s1 실패',k,str(r)[:300]); raise SystemExit(1)
        open(out+'.png','wb').write(base64.b64decode(img['base64'])); print('s1',k,flush=True)
    s=Image.open(out+'.png').convert('RGB'); can=Image.new('RGB',(96,96),BG)
    can.paste(s,((96-w)//2,92-h)); can.save(f'bk33/s1/{k}_96.png')
    d=D.format(x=X[k]); assert len(d)<=500,len(d)
    o2=f'bk33/s2/{k}'
    if not os.path.exists(o2+'.png'):
        o,aa,bb2=gen(open(f'bk33/s1/{k}_96.png','rb').read(),d,2026123600+int(k[-1]),o2); print('s2',k,aa,'->',bb2,flush=True)
