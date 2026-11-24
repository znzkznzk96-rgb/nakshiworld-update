import sys,json,base64,time,os
sys.argv=['x']
exec(open('gen5.py').read().split("if __name__")[0])
from concurrent.futures import ThreadPoolExecutor
O='slot/fx/'
J={'burst':"the starburst explodes: starts small and bright, then grows large with long rays shooting outward, then fades into small sparks",
'rainbow':"the rainbow starburst explodes: starts small and bright, then grows large with long rays shooting outward, then fades into small colorful sparks",
'coin':"the gold coin spins around its vertical axis, turning edge on and back, with a small glint of light",
'gem':"the blue gem rotates slightly and sparkles, white twinkles flash on its facets"}
def run(k):
    img=base64.b64encode(open(O+'seed_%s.png'%k,'rb').read()).decode()
    req={"first_frame":{"type":"base64","base64":img,"format":"png"},"description":J[k],"frame_count":8,"seed":20261210,"no_background":True,"view":"side"}
    jid=call('https://api.pixellab.ai/v2/animate-pixminimax',json.dumps(req).encode())['background_job_id']
    for _ in range(100):
        time.sleep(5);s=call('https://api.pixellab.ai/v2/background-jobs/%s'%jid)
        if s.get('status') in('completed','failed'):break
    ims=(s.get('last_response') or s).get('images') or []
    for i,im in enumerate(ims):open(O+'%s_%02d.png'%(k,i),'wb').write(base64.b64decode(im['base64'] if isinstance(im,dict) else im))
    return k,s.get('status'),len(ims)
b0=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
with ThreadPoolExecutor(4) as ex:
    for r in ex.map(run,list(J)):print(r,flush=True)
print(b0,'->',call('https://api.pixellab.ai/v2/balance')['subscription']['generations'])
