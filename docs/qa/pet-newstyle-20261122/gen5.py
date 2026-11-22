import json,base64,hashlib,os,urllib.request,urllib.error,sys
K=open(os.path.expanduser('~/.pixellab_key')).read().strip()
H={'Authorization':'Bearer '+K,'Content-Type':'application/json'}
def call(u,d=None):
    try: return json.load(urllib.request.urlopen(urllib.request.Request(u,data=d,headers=H),timeout=180))
    except urllib.error.HTTPError as e: print('HTTP',e.code,e.read()[:600].decode()); raise SystemExit(1)
def gen5(desc,seed,out,extra=None):
    assert len(desc)<=500,len(desc)
    req={"description":desc,"image_size":{"width":96,"height":96},"no_background":True,"seed":seed,"view":"side","direction":"east","outline":"single color black outline","detail":"medium detail"}
    if extra: req.update(extra)
    b0=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    r=call('https://api.pixellab.ai/v2/create-image-pixen',json.dumps(req).encode()); json.dump(r,open(out+'.raw.json','w'))
    img=r.get('image') or r.get('last_response',{}).get('image')
    if not img: print('no image',list(r)[:6]); raise SystemExit(1)
    open(out+'.png','wb').write(base64.b64decode(img['base64']))
    b1=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    json.dump({"desc":desc,"seed":seed,"before":b0,"after":b1},open(out+'.rec.json','w'),ensure_ascii=False)
    print(out,b0,'->',b1,flush=True)
if __name__=='__main__':
    gen5("a chibi wolf mascot, 2-head-tall, black-gray fur, white tail tip, yellowed peeling wallpaper scarf",2026112401,'bk5/probe')
