import sys,json,time,base64;sys.path.insert(0,'/tmp/cut1');from gen import *
img=lambda p:{"image":{"type":"base64","base64":b64(p)},"size":{"width":200,"height":200}}
r=curl('POST','https://api.pixellab.ai/v2/inpaint-v3',{"description":"open lined notebook right page with empty horizontal ruled lines, the notebook's dark right edge and bottom edge, dark teal shadowed area beyond the notebook, no hand, no pen","inpainting_image":img('/tmp/cut1/out/inp_src.png'),"mask_image":img('/tmp/cut1/out/inp_mask.png'),"seed":44})
jid=r.get('background_job_id');print(jid, r if not jid else '')
open('/tmp/cut1/out/inpaint.job','w').write(json.dumps(r))
for i in range(40):
    time.sleep(6);s=curl('GET',f'https://api.pixellab.ai/v2/background-jobs/{jid}')
    if s.get('status') in('completed','failed'):break
lr=s.get('last_response') or {};print(s.get('status'),lr.get('usage') or s.get('usage'),list(lr.keys())[:8])
ims=lr.get('images') or ([lr['image']] if lr.get('image') else [])
for i,im in enumerate(ims):
    d=im.get('base64') if isinstance(im,dict) else im
    open(f'/tmp/cut1/out/inpaint_{i}.png','wb').write(base64.b64decode(d.split(',',1)[-1]))
