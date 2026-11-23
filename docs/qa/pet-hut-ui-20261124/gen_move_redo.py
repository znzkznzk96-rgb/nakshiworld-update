import sys,json,base64,time,os
sys.argv=['x']
os.chdir('../pet-newstyle-20261122')
exec(open('gen5.py').read().split("if __name__")[0])
from concurrent.futures import ThreadPoolExecutor
OUT='../pet-hut-ui-20261124/move_redo/'
os.makedirs(OUT,exist_ok=True)
S=" Stays in the same spot in the frame and does not move sideways."
D={
'd_frog':"the green frog hops up and down in place, small bouncy hops"+S,
'd_mouse':"the grey mouse walks in place, little legs scurrying"+S,
'c_slime':"the blue slime bounces up and down in place, squishing and stretching"+S,
'a_fennec':"the fennec fox trots in place, legs moving, ears bobbing"+S,
'a_otter':"the otter waddles in place, legs and tail swaying"+S,
'a_owl':"the owl flaps its wings gently and hovers floating in place, bobbing up and down"+S,
's_fairy':"the fairy flutters its wings and floats up and down in place"+S,
's_tome':"the spell book flaps its cover like wings and floats up and down in place"+S}
def run(k):
    img=base64.b64encode(open('anim/%s_00.png'%k,'rb').read()).decode()
    req={"first_frame":{"type":"base64","base64":img,"format":"png"},"description":D[k],"frame_count":8,"seed":20261402,"no_background":True,"view":"side"}
    jid=call('https://api.pixellab.ai/v2/animate-pixminimax',json.dumps(req).encode())['background_job_id']
    for _ in range(100):
        time.sleep(5);s=call('https://api.pixellab.ai/v2/background-jobs/%s'%jid)
        if s.get('status') in('completed','failed'):break
    ims=(s.get('last_response') or s).get('images') or []
    for i,im in enumerate(ims):open(OUT+'%s_%02d.png'%(k,i),'wb').write(base64.b64decode(im['base64'] if isinstance(im,dict) else im))
    return k,s.get('status'),len(ims)
b0=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
with ThreadPoolExecutor(4) as ex:
    for r in ex.map(run,list(D)):print(r,flush=True)
print(b0,'->',call('https://api.pixellab.ai/v2/balance')['subscription']['generations'])
