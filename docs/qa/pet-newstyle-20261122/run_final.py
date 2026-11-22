import json,base64,hashlib,time,os,urllib.request,sys
import numpy as np
from PIL import Image
K=open(os.path.expanduser('~/.pixellab_key')).read().strip()
H={'Authorization':'Bearer '+K,'Content-Type':'application/json'}
def call(u,d=None): return json.load(urllib.request.urlopen(urllib.request.Request(u,data=d,headers=H),timeout=120))
R='../pet-roster-20261118/';C=R+'cd-pixellab-right/'
L=[("otter",R+"otter-A.png","whiskers and muzzle fur strands, stitching and buckles on the backpack, paw pads with toe lines, belly fur lines"),
("whale",R+"whale-A.png","gold plate texture, fin veins, small sharp eye, throat pleats, barnacle marks"),
("wolf",R+"wolf-B.png","fur tufts, muzzle line, inner ear fur, glowing rift crack details, claw detail"),
("fox",R+"fox-B.png","layered fur, star pattern on the tail tip, muzzle line, inner ear, chest ruff"),
("kingfisher",R+"kingfisher-A.png","layered feathers, beak line, wing feather bars, chest shading, talons"),
("hawk",R+"hawk-A.png","layered feathers, hooked beak line, flame pattern on wings, talons"),
("penguin",R+"penguin-B.png","feather sheen on the belly, flipper edge feathers, beak line, webbed feet"),
("frog",R+"frog-A.png","skin texture and spots, throat sac shading, eye ridges, toe pads"),
("turtle",R+"turtle-B.png","shell scute pattern, backpack straps and stitching, skin scales, claws"),
("hedgehog",R+"hedgehog-A.png","individual spine rows, face fur, nose shine, chestnut burr texture"),
("sparrow",R+"sparrow-B.png","layered feathers, wing bars, beak line, bobber float details"),
("raccoon",R+"raccoon-A.png","fur strands, mask edge, tail rings, hand and finger details"),
("hamster",R+"hamster7-B.png","fur tufts, cheek shading, gem facets, paw details"),
("chick",R+"chick7-B.png","downy feather tufts, flame tuft shading, beak line, toe details"),
("boar",R+"boar-style.png","bristle fur, tusk, snout detail, hoof detail"),
("squirrel",C+"chestnut-squirrel-A.png","bushy tail strands, ear tufts, chestnut texture, fur lines"),
("rabbit",C+"dandelion-rabbit-A.png","inner ear shading, dandelion details, fur lines, paw details"),
("duck",C+"reed-duck-A.png","layered feathers, bill detail, reed texture, webbed feet"),
("tadpole",C+"puddle-tadpole-B.png","translucent skin shading, tail fin veins, eye detail, spots"),
("snail",C+"waterdrop-snail-A.png","shell spiral ridges, skin texture, antenna detail, droplet highlights")]
a,b=int(sys.argv[1]),int(sys.argv[2])
for idx,(pid,ref,det) in enumerate(L[a:b],a):
    d=f'final/{pid}';os.makedirs(d,exist_ok=True)
    if os.path.exists(f'{d}/{pid}-final.png'): continue
    rb=open(ref,'rb').read()
    desc=f"Edit this exact image. The outer silhouette, size, pose and every body part position must stay identical; do not lengthen or move anything. Change only internal details: {det}. Keep colors. Thin dark selective outline, many tonal steps, rim light, 1px pixels."
    assert len(desc)<=500
    req={"image":{"type":"base64","base64":base64.b64encode(rb).decode()},"description":desc,"width":96,"height":96,"seed":2026112600+idx,"no_background":True}
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
    out=base64.b64decode(img['base64']); open(f'{d}/{pid}-final.png','wb').write(out)
    b1=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    A=np.array(Image.open(ref).convert('RGBA'));B=np.array(Image.open(f'{d}/{pid}-final.png').convert('RGBA'))
    ma,mb=A[:,:,3]>0,B[:,:,3]>0;iou=(ma&mb).sum()/(ma|mb).sum();chg=(A!=B).any(2).mean()
    ok=bool(iou>=0.85 and chg>=0.45)
    json.dump({"id":pid,"ref":ref,"ref_sha256":hashlib.sha256(rb).hexdigest(),"desc":desc,"seed":req['seed'],"before":b0,"after":b1,"sha256":hashlib.sha256(out).hexdigest(),"iou":round(float(iou),3),"changed":round(float(chg),3),"gate_pass":ok},open(f'{d}/record.json','w'),ensure_ascii=False,indent=1)
    print(pid,b0,'->',b1,'IoU %.2f 변경 %.2f'%(iou,chg),'통과' if ok else '미달',flush=True)
