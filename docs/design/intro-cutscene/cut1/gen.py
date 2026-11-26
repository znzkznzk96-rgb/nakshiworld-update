import json,sys,time,base64,subprocess,os
K=open(os.path.expanduser('~/.pixellab_key')).read().strip()
def curl(method,url,body=None):
    cmd=['curl','-sS','-m','120','-X',method,'-H','Authorization: Bearer '+K,'-H','Content-Type: application/json',url]
    if body is not None: cmd+=['--data-binary','@-']
    r=subprocess.run(cmd,input=json.dumps(body) if body is not None else None,capture_output=True,text=True)
    return json.loads(r.stdout)
def b64(p): return base64.b64encode(open(p,'rb').read()).decode()
def ref(p,w,h,usage=None):
    d={"image":{"type":"base64","base64":b64(p)},"size":{"width":w,"height":h}}
    if usage:d["usage_description"]=usage
    return d
def run(name,body):
    r=curl('POST','https://api.pixellab.ai/v2/generate-image-v2',body)
    jid=r.get('background_job_id');open(f'/tmp/cut1/out/{name}.job','w').write(json.dumps(r))
    print('job',jid,{k:v for k,v in r.items() if k!='background_job_id'} if not jid else '')
    if not jid: return
    for i in range(60):
        time.sleep(8);s=curl('GET',f'https://api.pixellab.ai/v2/background-jobs/{jid}')
        if s.get('status') in ('completed','failed'):break
    json.dump({k:v for k,v in s.items() if k!='last_response'},open(f'/tmp/cut1/out/{name}.status.json','w'))
    lr=s.get('last_response') or {}
    imgs=lr.get('images') or ([lr.get('image')] if lr.get('image') else [])
    print(s.get('status'),'images',len(imgs),'usage',lr.get('usage') or s.get('usage'))
    for i,im in enumerate(imgs):
        data=im.get('base64') if isinstance(im,dict) else im
        if data and ',' in data[:40]: data=data.split(',',1)[1]
        open(f'/tmp/cut1/out/{name}_{i}.png','wb').write(base64.b64decode(data))
    if not imgs: print(json.dumps(lr)[:600])
