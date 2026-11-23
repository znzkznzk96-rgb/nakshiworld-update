import sys,json,base64,time,os
sys.argv=['x']
exec(open('gen5.py').read().split("if __name__")[0])
from concurrent.futures import ThreadPoolExecutor
D={'d_chick':"the little chick hops in with a bouncy jump, flaps its tiny wings, lands and chirps happily",
'a_fennec':"the fennec fox leaps in from above spinning once, lands gracefully with ears flicking and tail swish",
'sss_seraph':"the seraph descends slowly from above, wings spreading wide open, feathers falling, halo glowing brighter"}
def run(k):
    img=base64.b64encode(open('anim/%s_00.png'%k,'rb').read()).decode()
    req={"first_frame":{"type":"base64","base64":img,"format":"png"},"description":D[k],"frame_count":8,"seed":20261301,"no_background":True,"view":"side"}
    jid=call('https://api.pixellab.ai/v2/animate-pixminimax',json.dumps(req).encode())['background_job_id']
    for _ in range(100):
        time.sleep(5);s=call('https://api.pixellab.ai/v2/background-jobs/%s'%jid)
        if s.get('status') in('completed','failed'):break
    ims=(s.get('last_response') or s).get('images') or []
    for i,im in enumerate(ims):open('slot/rv/%s_%02d.png'%(k,i),'wb').write(base64.b64decode(im['base64'] if isinstance(im,dict) else im))
    return k,s.get('status'),len(ims)
if __name__=='__main__':
    ks=sys.argv_k if hasattr(sys,'argv_k') else list(D)
    b0=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    with ThreadPoolExecutor(3) as ex:
        for r in ex.map(run,ks):print(r,flush=True)
    print(b0,'->',call('https://api.pixellab.ai/v2/balance')['subscription']['generations'])
