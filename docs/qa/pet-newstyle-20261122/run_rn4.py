import json,base64,io,os,sys
from PIL import Image
from gen5 import call
exec(open('run_rn3.py').read().split('base=Image.open')[0].split('from gen5 import call,H')[1])  # S, SD, P 재사용
pick=Image.open('rn3/sss_seraph_pick.png').convert('RGBA')  # 사용자 선택 5-3
base=Image.open('rn3/style/night_base_game.png').convert('RGBA')
def b64(im):
    f=io.BytesIO(); im.save(f,'PNG'); return {"type":"base64","base64":base64.b64encode(f.getvalue()).decode()}
col=Image.new('RGBA',(72,36)); col.paste(pick,(0,0)); col.paste(base.crop((10,200,46,236)),(36,0))
os.makedirs('rn4',exist_ok=True)
for k in sys.argv[1:]:
  for v in 'AB'[:int(os.environ.get('NV','1'))]:
    out=f'rn4/{k}-{v}'
    if os.path.exists(out+'.png'): continue
    s=S[k.split('_')[0]]
    req={"description":P[k]+" Full body, facing right. "+SD,"image_size":{"width":s,"height":s},"no_background":True,
         "style_image":b64(pick.crop(((36-s)//2,36-s,(36-s)//2+s,36))),"style_strength":60,"color_image":b64(col),"outline":"single color outline",
         "seed":2026112700+list(P).index(k)+(100 if v=='B' else 0)}
    b0=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    r=call('https://api.pixellab.ai/v2/create-image-bitforge',json.dumps(req).encode())
    img=r.get('image') or r.get('last_response',{}).get('image')
    open(out+'.png','wb').write(base64.b64decode(img['base64'].split(',')[-1]))
    b1=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    json.dump({"desc":P[k],"size":s,"seed":req['seed'],"before":b0,"after":b1},open(out+'.rec.json','w'))
    print(out,s,b0,'->',b1,flush=True)
