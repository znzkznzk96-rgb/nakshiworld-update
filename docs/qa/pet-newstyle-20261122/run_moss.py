import json,base64,io,os,time,sys
exec(open('run_rn3.py').read().split("os.makedirs('rn3/out'")[0])
M={"s_moss1":"Mystical moss treant spirit pet: small walking tree-stump creature with a bark body thickly covered in green moss, two root legs, two leafy branch arms, a tiny sprout on top, glowing teal eyes.",
"s_moss2":"Mystical moss forest guardian pet: small humanoid of mossy stone and twisting vines with antler-like branches on its head, a hanging moss cloak, glowing green eyes, two arms and two legs."}
for i,(k,desc) in enumerate(M.items()):
    d=f'moss/{k}'
    if os.path.exists(d+'/rec.json'): continue
    os.makedirs(d,exist_ok=True); s=28
    req={"style_images":refs(s),"description":desc+" Full body, facing right, transparent background.","style_description":SD,"seed":2026112700+i,"no_background":True,"target_palette":{"max_colors":32}}
    b0=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    r=call('https://api.pixellab.ai/v2/generate-with-style-v2',json.dumps(req).encode()); jid=r.get('background_job_id') or r.get('job_id') or r.get('id')
    json.dump({"job":jid,"before":b0},open(d+'/job.json','w')); print(k,jid,flush=True)
    for _ in range(100):
        time.sleep(6); j=call(f'https://api.pixellab.ai/v2/background-jobs/{jid}')
        if j.get('status') in('completed','failed'): break
    if j.get('status')!='completed': print('FAIL',k,str(j)[:300]); raise SystemExit(1)
    lr=j['last_response']; ims=lr.get('images') or [lr.get('image')]
    for n,im in enumerate(ims): open(f'{d}/{n:02d}.png','wb').write(base64.b64decode(im['base64'].split(',')[-1]))
    b1=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    json.dump({"desc":desc,"before":b0,"after":b1,"count":len(ims)},open(d+'/rec.json','w')); print(k,len(ims),b0,'->',b1,flush=True)
