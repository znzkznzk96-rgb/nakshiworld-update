import sys,json,base64,os,time,urllib.request,urllib.error
sys.argv=['x']
exec(open('gen5.py').read().split("if __name__")[0])
S='slot/final/'
def bal():return call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
# B. lever pull animation
b0=bal()
img=base64.b64encode(open(S+'lever_up.png','rb').read()).decode()
from PIL import Image
w,h=Image.open(S+'lever_up.png').size
req={"first_frame":{"type":"base64","base64":img,"format":"png"},"description":"a red ball slot machine lever is pulled down by a hand: the lever arm swings down from upright to fully pulled down, then springs back up to upright, the base stays fixed","frame_count":8,"seed":2026112572,"no_background":True,"view":"side"}
r=call('https://api.pixellab.ai/v2/animate-pixminimax',json.dumps(req).encode());jid=r['background_job_id']
json.dump({'job':jid,'before':b0},open('slot/lever_anim.job.json','w'));print('job',jid,flush=True)
for _ in range(100):
    time.sleep(5);s=call('https://api.pixellab.ai/v2/background-jobs/%s'%jid)
    if s.get('status') in('completed','failed'):break
print(s.get('status'))
ims=(s.get('last_response') or s).get('images') or []
for i,im in enumerate(ims):open('slot/lever_pull_%02d.png'%i,'wb').write(base64.b64decode(im['base64'] if isinstance(im,dict) else im))
print(len(ims),'frames',b0,'->',bal())
