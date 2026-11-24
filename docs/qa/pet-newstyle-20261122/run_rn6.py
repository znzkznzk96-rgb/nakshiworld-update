import json,base64,io,os,sys
from PIL import Image
from gen5 import call
exec(open('run_rn3.py').read().split('base=Image.open')[0].split('from gen5 import call,H')[1])
base=Image.open('rn3/style/night_base_game.png').convert('RGBA')
def b64(im):
    f=io.BytesIO(); im.save(f,'PNG'); return {"type":"base64","base64":base64.b64encode(f.getvalue()).decode()}
os.makedirs('rn6',exist_ok=True)
for i,k in enumerate(P):
  if k=='sss_seraph': continue
  s=S[k.split('_')[0]]
  for v in 'ABC':
    out=f'rn6/{k}-{v}'
    if os.path.exists(out+'.png'): continue
    sty=base.crop((53-s//2,224-s//2,53-s//2+s,224-s//2+s))  # 게임 부두·오두막 원본 질감
    req={"description":P[k]+" Full body, facing right. "+SD,"image_size":{"width":s,"height":s},"no_background":True,
         "style_image":b64(sty),"style_strength":40,"outline":"single color outline","seed":2026112900+i*10+'ABC'.index(v)}
    b0=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    r=call('https://api.pixellab.ai/v2/create-image-bitforge',json.dumps(req).encode())
    img=r.get('image') or r.get('last_response',{}).get('image')
    open(out+'.png','wb').write(base64.b64decode(img['base64'].split(',')[-1]))
    b1=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    json.dump({"size":s,"seed":req['seed'],"before":b0,"after":b1},open(out+'.rec.json','w')); print(out,b0,'->',b1,flush=True)
