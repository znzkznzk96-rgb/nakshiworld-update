import json,base64,hashlib,time,os,urllib.request,sys
from PIL import Image
K=open(os.path.expanduser('~/.pixellab_key')).read().strip()
H={'Authorization':'Bearer '+K,'Content-Type':'application/json'}
def call(u,d=None): return json.load(urllib.request.urlopen(urllib.request.Request(u,data=d,headers=H),timeout=120))
R='../pet-roster-20261118/';C=R+'cd-pixellab-right/'
# id, 원본, 이름, 동물, 색·소품, 부위, 하이라이트, 질감
P={
"whale":(R+"whale-A.png","golden whale","whale","golden yellow skin with cream belly, small gold crown and blue goggles on the head","crown, fins, tail","crown and fins","skin"),
"wolf":(R+"wolf-B.png","rift wolf","wolf","black and gray fur, purple glowing paws and cracks, white-tipped tail, purple neckerchief","ears, tail, paws","ears and glowing cracks","fur"),
"fox":(R+"fox-B.png","star-tailed fox","fox","lavender fur with purple tail and legs, small star marks, star hairpin","ears, tail, legs","ears and tail tip","fur"),
"kingfisher":(R+"kingfisher-A.png","kingfisher","kingfisher","blue back and wings, orange belly, long black beak","beak, wings, crest","crest and wings","feather"),
"hawk":(R+"hawk-A.png","flame hawk","hawk","red and orange feathers with a flame crest","crest, wings, talons","flame crest and wings","feather"),
"penguin":(R+"penguin-B.png","little penguin","penguin","black and white body, purple knit hat with star, purple scarf","hat, scarf, flippers","hat and flippers","feather"),
"frog":(R+"frog-A.png","spring frog","frog","green skin with light belly, blue water drop pendant","legs, pendant","eye ridges and pendant","skin"),
"turtle":(R+"turtle-B.png","backpack turtle","turtle","teal shell, green bedroll backpack with straps, light blue skin","shell, backpack, legs","shell and bedroll","shell"),
"hedgehog":(R+"hedgehog-A.png","chestnut hedgehog","hedgehog","brown spines, cream face, small leaf on the spines","spines, leaf","spine tips and leaf","spine"),
"sparrow":(R+"sparrow-B.png","sparrow","sparrow","brown cap, white cheeks, striped brown wings, blue bead necklace","wings, beak, necklace","cap and wings","feather"),
"raccoon":(R+"raccoon-A.png","raccoon","raccoon","gray fur, black eye mask, ringed tail, green scarf, small pouch","ears, tail, scarf","ears and tail rings","fur"),
"hamster":(R+"hamster7-B.png","jewel hamster","hamster","gray fur with cream belly, pink cheeks, holding a purple gem","ears, paws, gem","gem and ears","fur"),
"chick":(R+"chick7-B.png","flame chick","chick","dark gray body with white chest, orange beak and feet, small flame on the tail","flame tail, beak","flame and beak","feather"),
"boar":(R+"boar-style.png","little boar","boar","dark brown bristles with cream stripes, pink snout, small tusks","bristle mane, snout, tusks","mane and tusks","bristle"),
"squirrel":(C+"chestnut-squirrel-A.png","chestnut squirrel","squirrel","red-brown fur with cream belly, bushy tail, holding an acorn","ears, tail, acorn","tail and acorn","fur"),
"rabbit":(C+"dandelion-rabbit-A.png","dandelion rabbit","rabbit","cream white fur, pink inner ears, small dandelion flower","ears, dandelion","ears and flower","fur"),
"duck":(C+"reed-duck-A.png","reed duck","duck","cream white feathers, orange bill and feet, reed grass behind","wings, bill, reeds","wings and bill","feather"),
"tadpole":(C+"puddle-tadpole-B.png","puddle tadpole","tadpole","gray spotted skin with pale belly, leaf on the tail","tail, leaf","leaf and spots","skin"),
"snail":(C+"waterdrop-snail-A.png","water drop snail","snail","mint spiral shell with a blue water drop on top, pale green body","shell, drop, antennae","shell and drop","shell"),
}
def gen(img_bytes,desc,seed,out):
    assert len(desc)<=500,(len(desc),desc)
    req={"image":{"type":"base64","base64":base64.b64encode(img_bytes).decode()},"description":desc,"width":96,"height":96,"seed":seed,"no_background":True}
    b0=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    r=call('https://api.pixellab.ai/v2/edit-image-pixen',json.dumps(req).encode()); json.dump(r,open(out+'.raw.json','w'))
    if 'image' in r: img=r['image']
    else:
        jid=r['background_job_id']
        for _ in range(30):
            time.sleep(6); r=call('https://api.pixellab.ai/v2/background-jobs/'+jid); json.dump(r,open(out+'.raw.json','w'))
            if r['status']!='processing': break
        if r['status']!='completed': raise SystemExit('실패 '+out)
        img=r['last_response']['image']
    o=base64.b64decode(img['base64']); open(out+'.png','wb').write(o)
    b1=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    json.dump({"desc":desc,"seed":seed,"input_sha256":hashlib.sha256(img_bytes).hexdigest(),"before":b0,"after":b1,"sha256":hashlib.sha256(o).hexdigest()},open(out+'.rec.json','w'),ensure_ascii=False,indent=1)
    return o,b0,b1
for k,pid in enumerate(sys.argv[1:]):
    ref,name,an,col,parts,hl,tex=P[pid]; d=f'final/{pid}3';os.makedirs(d,exist_ok=True)
    if os.path.exists(f'{d}/step3.png'): continue
    base=hash(pid)%1000
    s1=f"Redraw this {name} as a detailed game sprite: realistic {an} proportions, same face, {col}, small plain eyes, same pose and silhouette. Desaturated natural palette, thin dark selective outline, many subtle tonal steps, soft lighting with rim light, clear limbs, no anti-aliasing."
    o1,a0,_=gen(open(ref,'rb').read(),s1,2026120000+len(pid)*7+k,f'{d}/step1')
    s2=f"Edit only the face of this {an}. Keep everything else exactly the same: pixel texture, dark outline, {parts}, body, colors and shading. 1) Replace the eyes with small calm 2x2 pixel dark eyes with a single 1px highlight, placed naturally. 2) Make the mouth and face plain and natural, no big smile, a calm heavy look like a small otter sprite. Do not simplify any details."
    o2,_,_=gen(o1,s2,2026120100+len(pid)*7+k,f'{d}/step2')
    s3=f"Keep this exact {an}: same silhouette, pose, face, small eyes, mouth, colors and outline. Only enrich the rendering: add more shading steps and pixel clusters for volume, deeper shadows under the head, belly and legs, highlights on {hl}, subtle {tex} shading. Keep it clean and readable, no noisy random texture."
    o3,_,b3=gen(o2,s3,2026120200+len(pid)*7+k,f'{d}/step3')
    print(pid,a0,'->',b3,flush=True)
