import json,base64,io,os,time,sys
from PIL import Image
from gen5 import call,H
# 게임 원본(밤 배경 base.png를 게임 해상도로) + 기존 고양이를 스타일 참조, 등급별 크기로 바로 생성(확대 없음)
S={"sss":36,"ss":32,"s":28,"a":26,"b":24,"c":22,"d":20}
SD="Same cozy fishing game: warm 16-bit pixel art, dark brown outlines, warm lantern-lit wood tones, rich saturated colors, crisp pixels, readable at small size."
P={
"sss_seraph":"Legendary seraph knight pet: small humanoid in ivory armor, cape, two folded white feathered wings, gold halo, golden eyes, short gold spear.",
"sss_demon":"Legendary abyss demon pet: small humanoid with curved horns, dark purple skin with bright highlights, small bat wings, thin tail, crimson eyes, tattered robe.",
"sss_apostle":"Legendary star apostle pet: small humanoid with pale skull face and glowing gold eyes, gold spiked crown, starry navy cloak, staff topped with a gold star.",
"sss_lunar":"Legendary lunar witch pet: small girl in a navy hooded cloak with crescent moon embroidery, silver hair, pink eyes, short crescent staff.",
"ss_golem":"Rare clockwork golem pet: sturdy humanoid machine of ivory and brass plates, gear in chest, two arms, two legs, single round teal lens eye.",
"ss_knight":"Rare phantom knight pet: empty suit of silver armor with helmet, two arms, two legs, teal glow inside the visor, broken sword.",
"ss_storm":"Rare storm cloud spirit pet: floating fluffy gray cloud body with two cloud arms, angry gold eyes, small teal lightning bolts below.",
"s_wisp":"Mystical candle wisp pet: small creature of cream wax with a lit candle flame as its head, two stubby legs, eyes in the flame.",
"s_tome":"Mystical walking spellbook pet: navy leather book with gold corners and one eye on the cover, two small legs.",
"s_rock":"Mystical moss rock spirit pet: round gray stone body with green moss, two stone legs, glowing teal crack eyes.",
"a_fennec":"Fennec fox pet, four legs, sand-colored fur, huge ears with pink insides, cheerful eyes.",
"a_otter":"River otter pet standing upright, brown fur, cream face and belly, holding a small fish, bright eyes.",
"a_owl":"Horned owl pet, round body, brown and ivory feathers, ear tufts, big orange eyes with heavy brows.",
"b_hamster":"Hamster pet, round body, golden and cream fur, puffed cheeks, tiny paws, black bead eyes.",
"b_hedgehog":"Hedgehog pet, short legs, dark brown spines, cream face, pink nose, sleepy eyes.",
"b_sparrow":"Sparrow pet, round body, brown feathers with cream breast, short tail, sharp black eyes.",
"c_slime":"Slime pet, round jelly body, translucent blue with a light highlight, two big eyes, tiny smile.",
"c_mushroom":"Mushroom creature pet walking on two tiny legs, red spotted cap, cream stem body, dot eyes.",
"c_puffbird":"Round puffball bird pet, fluffy white body, tiny wings, small orange beak, two short legs, oval eyes.",
"d_frog":"Small frog pet, four legs, green body with cream belly, big round eyes on top of head.",
"d_chick":"Small chick pet, yellow fluffy body, orange beak and feet, dot eyes.",
"d_mouse":"Small mouse pet, gray fur, pink ears and long pink tail, black eyes.",
}
base=Image.open('rn3/style/night_base_game.png').convert('RGBA')
cat=Image.open('rn3/style/cat256.png').convert('RGBA')
def b64(im):
    f=io.BytesIO(); im.save(f,'PNG'); return "data:image/png;base64,"+base64.b64encode(f.getvalue()).decode()
def refs(s):
    out=[cat.resize((s,s),Image.LANCZOS)]
    for cx,cy in [(53,224),(22,234),(225,222)]:
        out.append(base.crop((cx-s//2,cy-s//2,cx-s//2+s,cy-s//2+s)))
    return [{"image":{"base64":b64(i)},"width":s,"height":s} for i in out]
os.makedirs('rn3/out',exist_ok=True)
only=sys.argv[1:]
for i,k in enumerate(P):
    if only and k not in only: continue
    d=f'rn3/out/{k}'
    if os.path.exists(d+'/done'): continue
    os.makedirs(d,exist_ok=True); s=S[k.split('_')[0]]
    req={"style_images":refs(s),"description":P[k]+" Full body, facing right, transparent background.","style_description":SD,"seed":2026112600+i,"no_background":True,"target_palette":{"max_colors":32}}
    b0=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    r=call('https://api.pixellab.ai/v2/generate-with-style-v2',json.dumps(req).encode())
    jid=r.get('background_job_id') or r.get('job_id') or r.get('id')
    for _ in range(90):
        time.sleep(6); j=call(f'https://api.pixellab.ai/v2/background-jobs/{jid}')
        if j.get('status') in ('completed','failed'): break
    json.dump({k2:v for k2,v in j.items() if k2!='last_response'},open(d+'/job.json','w'))
    if j.get('status')!='completed': print(k,'status',j.get('status'),str(j)[:300]); raise SystemExit(1)
    lr=j['last_response']; ims=lr.get('images') or [lr.get('image')]
    for n,im in enumerate(ims):
        open(f'{d}/{n:02d}.png','wb').write(base64.b64decode(im['base64'].split(',')[-1]))
    b1=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    json.dump({"desc":P[k],"size":s,"seed":2026112600+i,"before":b0,"after":b1,"count":len(ims)},open(d+'/rec.json','w'))
    open(d+'/done','w').write('1'); print(k,s,len(ims),b0,'->',b1,flush=True)
