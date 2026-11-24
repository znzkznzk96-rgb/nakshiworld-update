import json,base64,os,sys,time,urllib.request,urllib.error
K=open(os.path.expanduser('~/.pixellab_key')).read().strip()
H={'Authorization':'Bearer '+K,'Content-Type':'application/json'}
def call(u,d=None):
    try: return json.load(urllib.request.urlopen(urllib.request.Request(u,data=d,headers=H),timeout=180))
    except urllib.error.HTTPError as e: print('HTTP',e.code,e.read()[:500].decode()); raise SystemExit(1)
def run(k,seed,strength):
    out=f'bk12/{k}'
    if os.path.exists(out+'.png'): return
    req={"image":{"type":"base64","base64":base64.b64encode(open(f'bk12/in/{k}.png','rb').read()).decode()},"image_size":{"width":384,"height":384},"output_size":{"width":96,"height":96},"fixer":True,"init_image_strength":strength,"seed":seed}
    b0=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    r=call('https://api.pixellab.ai/v2/image-to-pixelart',json.dumps(req).encode()); json.dump(r,open(out+'.raw.json','w'))
    for _ in range(30):
        if 'image' in r or r.get('status')=='completed' or r.get('status')=='failed': break
        time.sleep(6); r=call('https://api.pixellab.ai/v2/background-jobs/'+r['background_job_id']); json.dump(r,open(out+'.raw.json','w'))
    img=r.get('image') or r.get('last_response',{}).get('image')
    if not img: print('실패',k,str(r)[:300]); raise SystemExit(1)
    open(out+'.png','wb').write(base64.b64decode(img['base64']))
    b1=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    json.dump({"seed":seed,"strength":strength,"before":b0,"after":b1},open(out+'.rec.json','w')); print(k,b0,'->',b1,flush=True)
if __name__=='__main__':
    for k in sys.argv[2:]: run(k,2026114000+int(k[-2:]),int(sys.argv[1]))
