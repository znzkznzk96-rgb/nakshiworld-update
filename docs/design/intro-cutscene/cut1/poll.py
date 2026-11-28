import sys,json,time,base64;sys.path.insert(0,'/tmp/cut1');from gen import *
name,jid=sys.argv[1],sys.argv[2]
for i in range(12):
    s=curl('GET',f'https://api.pixellab.ai/v2/background-jobs/{jid}')
    if s.get('status') in('completed','failed'):break
    time.sleep(8)
lr=s.get('last_response') or {};print(s.get('status'),lr.get('usage') or s.get('usage'))
ims=lr.get('images') or ([lr['image']] if lr.get('image') else [])
for i,im in enumerate(ims):
    d=im.get('base64') if isinstance(im,dict) else im
    open(f'/tmp/cut1/out/{name}_{i}.png','wb').write(base64.b64decode(d.split(',',1)[-1]))
print(len(ims))
