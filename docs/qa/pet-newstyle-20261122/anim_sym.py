import sys,json,base64,time
sys.argv=['x']
exec(open('gen5.py').read().split("if __name__")[0])
from concurrent.futures import ThreadPoolExecutor
A='../slot-module-20261123/assets/'
DESC={'S':"the golden letter S glows: a bright white shine sweeps across the letter from left to right, small sparkles twinkle on it, the letter shape stays fixed",
'SS':"the golden letters SS with gems glow: a bright white shine sweeps across the letters from left to right, gems twinkle with sparkles, letter shapes stay fixed",
'SSS':"the golden letters SSS with gems and flames: a bright white shine sweeps across the letters from left to right, gems twinkle with sparkles, small flames flicker on top, letter shapes stay fixed"}
def run(k):
    img=base64.b64encode(open(A+'sym_%s.png'%k,'rb').read()).decode()
    req={"first_frame":{"type":"base64","base64":img,"format":"png"},"description":DESC[k],"frame_count":8,"seed":20261123,"no_background":True,"view":"side"}
    jid=call('https://api.pixellab.ai/v2/animate-pixminimax',json.dumps(req).encode())['background_job_id']
    for _ in range(100):
        time.sleep(5);s=call('https://api.pixellab.ai/v2/background-jobs/%s'%jid)
        if s.get('status') in('completed','failed'):break
    ims=(s.get('last_response') or s).get('images') or []
    import os;os.makedirs('slot/fx',exist_ok=True)
    for i,im in enumerate(ims):open('slot/fx/shim_%s_%02d.png'%(k,i),'wb').write(base64.b64decode(im['base64'] if isinstance(im,dict) else im))
    return k,s.get('status'),len(ims),jid
b0=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
with ThreadPoolExecutor(3) as ex:
    for r in ex.map(run,['S','SS','SSS']):print(r,flush=True)
print(b0,'->',call('https://api.pixellab.ai/v2/balance')['subscription']['generations'])
