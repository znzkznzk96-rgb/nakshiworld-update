import json,base64,hashlib,sys,time,io,subprocess,os,urllib.request
from PIL import Image
pid,ref,name,seed=sys.argv[1],sys.argv[2],sys.argv[3],int(sys.argv[4])
K=open(os.path.expanduser('~/.pixellab_key')).read().strip()
H={'Authorization':'Bearer '+K,'Content-Type':'application/json'}
def call(url,data=None):
    r=urllib.request.Request(url,data=data,headers=H)
    return json.load(urllib.request.urlopen(r,timeout=60))
os.makedirs(pid,exist_ok=True)
b=open(ref,'rb').read()
desc=f"Redraw this {name} as a detailed game sprite: realistic proportions, same face and expression, same colors and accessories, same pose and silhouette. Clean dark navy 1px outline, dithered two-tone shading, limited palette, small plain eyes, no extra tiny details, no gradients, no anti-aliasing."
req={"image":{"type":"base64","base64":base64.b64encode(b).decode()},"description":desc,"width":96,"height":96,"seed":seed,"no_background":True}
bal0=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
r=call('https://api.pixellab.ai/v2/edit-image-pixen',json.dumps(req).encode())
job=r['background_job_id']
for _ in range(20):
    time.sleep(8); d=call('https://api.pixellab.ai/v2/background-jobs/'+job)
    if d['status']!='processing': break
bal1=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
rec={"id":pid,"ref":ref,"ref_sha256":hashlib.sha256(b).hexdigest(),"description":desc,"seed":seed,"job":job,"status":d['status'],"generations_before":bal0,"generations_after":bal1}
if d['status']=='completed':
    out=base64.b64decode(d['last_response']['image']['base64']); open(f'{pid}/{pid}-new.png','wb').write(out)
    rec['sha256']=hashlib.sha256(out).hexdigest()
json.dump(rec,open(f'{pid}/record.json','w'),ensure_ascii=False,indent=1)
print(pid,d['status'],bal0,'->',bal1,rec.get('sha256','')[:12])
