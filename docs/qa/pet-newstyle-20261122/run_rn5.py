import json,base64,io,os,time,sys
from PIL import Image
from gen5 import call
exec(open('run_rn3.py').read().split('base=Image.open')[0].split('from gen5 import call,H')[1])
pick=Image.open('rn3/sss_seraph_pick.png').convert('RGBA')
def ref(im): 
    f=io.BytesIO(); im.save(f,'PNG'); return {"image":{"type":"base64","base64":base64.b64encode(f.getvalue()).decode()},"size":{"width":im.size[0],"height":im.size[1]}}
os.makedirs('rn5',exist_ok=True)
for k in sys.argv[1:]:
    d=f'rn5/{k}'; os.makedirs(d,exist_ok=True); s=S[k.split('_')[0]]
    req={"description":P[k]+" Full body, facing right.","image_size":{"width":s,"height":s},"no_background":True,
         "style_image":ref(pick),"seed":2026112800+list(P).index(k)}
    b0=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    r=call('https://api.pixellab.ai/v2/generate-image-v2',json.dumps(req).encode()); jid=r.get('background_job_id')
    for _ in range(90):
        time.sleep(6); j=call(f'https://api.pixellab.ai/v2/background-jobs/{jid}')
        if j.get('status') in ('completed','failed'): break
    if j.get('status')!='completed': print(k,str(j)[:300]); raise SystemExit(1)
    ims=j['last_response'].get('images') or [j['last_response'].get('image')]
    for n,im in enumerate(ims): open(f'{d}/{n:02d}.png','wb').write(base64.b64decode(im['base64'].split(',')[-1]))
    b1=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    json.dump({"size":s,"before":b0,"after":b1,"count":len(ims)},open(d+'/rec.json','w')); print(k,s,len(ims),b0,'->',b1,flush=True)
