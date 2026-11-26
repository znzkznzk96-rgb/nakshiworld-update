import sys,json,time,base64;sys.path.insert(0,'/tmp/cut1');from gen import *
img=lambda p:{"image":{"type":"base64","base64":b64(p)},"size":{"width":200,"height":200}}
r=curl('POST','https://api.pixellab.ai/v2/inpaint-v3',{"description":"continue the mustard yellow work vest with a chest pocket and dark pants in shadow, seen from above, no arm, no sleeve","inpainting_image":img('/tmp/cut1/out/inp2_src.png'),"mask_image":img('/tmp/cut1/out/inp2_mask.png'),"seed":45})
print(r.get('background_job_id'));open('/tmp/cut1/out/inp2.job','w').write(json.dumps(r))
