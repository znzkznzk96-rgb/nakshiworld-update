import json,base64,hashlib,time,os,urllib.request,sys
K=open(os.path.expanduser('~/.pixellab_key')).read().strip()
H={'Authorization':'Bearer '+K,'Content-Type':'application/json'}
def call(u,d=None): return json.load(urllib.request.urlopen(urllib.request.Request(u,data=d,headers=H),timeout=120))
R='../pet-roster-20261118/'
L=[("otter",R+"otter-A.png","otter"),("whale",R+"whale-A.png","golden whale"),("wolf",R+"wolf-B.png","rift wolf"),("fox",R+"fox-B.png","star-tailed fox"),("kingfisher",R+"kingfisher-A.png","kingfisher"),("hawk",R+"hawk-A.png","flame hawk"),("penguin",R+"penguin-B.png","little penguin"),("frog",R+"frog-A.png","spring frog"),("turtle",R+"turtle-B.png","backpack turtle"),("hedgehog",R+"hedgehog-A.png","chestnut hedgehog"),("sparrow",R+"sparrow-B.png","sparrow"),("raccoon",R+"raccoon-A.png","raccoon"),("hamster",R+"hamster7-B.png","jewel hamster"),("chick",R+"chick7-B.png","flame chick"),("boar",R+"boar-style.png","little boar")]
C=R+"cd-pixellab-right/"
L+=[("squirrel",C+"chestnut-squirrel-A.png","chestnut squirrel"),("rabbit",C+"dandelion-rabbit-A.png","dandelion rabbit"),("duck",C+"reed-duck-A.png","reed duck"),("tadpole",C+"puddle-tadpole-B.png","tadpole"),("snail",C+"waterdrop-snail-A.png","snail")]
a,b=int(sys.argv[1]),int(sys.argv[2])
for idx,(pid,ref,nm) in enumerate(L[a:b],a):
    d=f'render/{pid}'; os.makedirs(d,exist_ok=True)
    if os.path.exists(f'{d}/{pid}-render.png'): continue
    if not os.path.exists(ref): print('REF 없음',pid,ref); break
    rb=open(ref,'rb').read()
    desc=f"Keep this cute chubby {nm} character design, but repaint it with rich material rendering like detailed painterly pixel art: thin dark selective outline in a darker shade of each fill color instead of a thick navy outline, many subtle tonal steps, desaturated natural palette, visible fur, feather or scale texture, soft volumetric lighting with a rim light, subtle wear. Keep 1px pixels, no chunky blocks."
    req={"image":{"type":"base64","base64":base64.b64encode(rb).decode()},"description":desc,"width":96,"height":96,"seed":2026112400+idx,"no_background":True}
    b0=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    r=call('https://api.pixellab.ai/v2/edit-image-pixen',json.dumps(req).encode()); json.dump(r,open(f'{d}/raw.json','w'))
    if 'image' in r: img=r['image']
    else:
        jid=r['background_job_id']
        for _ in range(30):
            time.sleep(6); r=call('https://api.pixellab.ai/v2/background-jobs/'+jid); json.dump(r,open(f'{d}/raw.json','w'))
            if r['status']!='processing': break
        if r['status']!='completed': print('실패',pid,r['status']); break
        img=r['last_response']['image']
    out=base64.b64decode(img['base64']); open(f'{d}/{pid}-render.png','wb').write(out)
    b1=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    json.dump({"id":pid,"ref":ref,"ref_sha256":hashlib.sha256(rb).hexdigest(),"desc":desc,"seed":req['seed'],"before":b0,"after":b1,"sha256":hashlib.sha256(out).hexdigest()},open(f'{d}/record.json','w'),ensure_ascii=False,indent=1)
    print(pid,b0,'->',b1,flush=True)
