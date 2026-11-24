import json,base64,io,os,time,sys
exec(open('run_rn3.py').read().split("os.makedirs('rn3/out'")[0])
M={"m3_lantern":"Mystical moss stone lantern spirit pet: small ancient stone lantern creature thickly covered in green moss, glowing teal flame in its window like an eye, two short stone feet, tiny fern on top.",
"m4_statue":"Mystical moss ancient statue pet: small stone statue creature with a big carved face covered in green moss and vines, glowing green eyes, short stubby arms and legs.",
"m5_jar":"Mystical moss clay jar spirit pet: small cracked clay jar creature overgrown with green moss, a leafy sprout poking from its mouth, glowing teal eyes, two tiny feet.",
"m6_anchor":"Mystical moss anchor spirit pet: small rusty ship anchor creature covered in green moss and barnacles, glowing teal eyes in its center, two short legs.",
"m7_fairy":"Mystical moss forest fairy pet: tiny girl spirit in a green moss and leaf dress with fern-leaf wings, flower in her hair, glowing teal eyes."}
for i,(k,desc) in enumerate(M.items()):
    d=f'moss/{k}'
    if os.path.exists(d+'/rec.json'): continue
    os.makedirs(d,exist_ok=True); s=28
    req={"style_images":refs(s),"description":desc+" Full body, facing right, transparent background.","style_description":SD,"seed":2026112710+i,"no_background":True,"target_palette":{"max_colors":32}}
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
