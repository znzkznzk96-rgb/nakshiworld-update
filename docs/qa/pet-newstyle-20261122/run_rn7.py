import sys
exec(open('run_rn3.py').read().split("os.makedirs('rn3/out'")[0])
NA=" Not a cloud."
B={
"sss_seraph":"Legendary angel archer pet: slim humanoid in white and gold robe, large feathered wings slightly spread, gold halo, holding a gold bow.",
"sss_demon":"Legendary demon lord pet: humanoid in dark plate armor with glowing red cracks, big curved horns, no wings, jagged dark blade, burning red eyes.",
"sss_apostle":"Legendary star sage pet: tall robed humanoid whose head is a glowing gold star with no face, white robe with gold trim, small stars floating near the hands.",
"sss_lunar":"Legendary moon priestess pet: woman with long white hair, crescent moon crown, silver-white dress, holding a glowing moon orb.",
"ss_golem":"Rare rune golem pet: bulky humanoid of dark stone blocks with glowing teal runes, small head, big fists, two legs.",
"ss_knight":"Rare cursed samurai spirit pet: empty samurai armor with horned helmet, purple ghost flame inside, holding a katana.",
"ss_storm1":"Rare thunder spirit pet: small humanoid made of crackling lightning, glowing yellow body, spiky electric hair, teal sparks around the fists."+NA,
"ss_storm2":"Rare wind spirit pet: small floating figure whose lower body is a swirling teal wind trail, gold bracers on the arms, a small lightning bolt held in one hand."+NA,
"s_wisp":"Mystical lantern spirit pet: small iron lantern body with a teal ghost flame inside as its face, two tiny arms, two short legs.",
"s_tome":"Mystical living scroll pet: rolled parchment creature with a red wax seal as its face, two little legs, ribbon arms.",
"s_rock":"Mystical geode spirit pet: round dark rock body cracked open showing purple crystals, two stubby legs, glowing eyes.",
"a_fennec":"Fennec fox pet sitting upright, chubby round body, oversized fluffy ears, fluffy tail wrapped around the feet, sleepy half-closed eyes.",
"a_otter":"Sea otter pet standing, round chubby body, gray-brown fur, white face, paws together on the belly, whiskers.",
"a_owl":"Little elf owl pet, tiny round body, gray-brown speckled feathers, no ear tufts, huge yellow eyes.",
"b_hamster":"Dwarf hamster pet standing on hind legs, white fur with a gray back stripe, tiny raised paws, round black eyes.",
"b_hedgehog":"Hedgehog pet half curled, light tan spines, peeking face, pink nose, round eyes.",
"b_sparrow":"Chubby round finch pet, red cheeks, gray-brown back, cream belly, puffed feathers.",
"c_slime":"Green leaf slime pet, round translucent green jelly body with a small sprout growing on top, two dot eyes.",
"c_mushroom":"Blue mushroom creature pet, wide flat blue cap with white spots, chubby white stem body, two tiny legs, sleepy eyes.",
"c_puffbird":"Round fluffy pink puffball bird pet, cotton candy feathers, small wings, tiny beak, two short legs.",
"d_frog":"Small tree frog pet, bright blue-green body, orange toe pads, big red eyes, slim legs.",
"d_chick":"Small duckling pet, yellow fluffy body, flat orange bill, webbed feet, round eyes.",
"d_mouse":"Small field mouse pet sitting upright, brown fur, cream belly, big round ears, short tail.",
}
os.makedirs('rn7/out',exist_ok=True)
for i,k in enumerate(B):
    d=f'rn7/out/{k}'
    if os.path.exists(d+'/done'): continue
    os.makedirs(d,exist_ok=True); s=S[k.split('_')[0]]
    req={"style_images":refs(s),"description":B[k]+" Full body, facing right, transparent background.","style_description":SD,"seed":2026113000+i,"no_background":True,"target_palette":{"max_colors":32}}
    b0=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    r=call('https://api.pixellab.ai/v2/generate-with-style-v2',json.dumps(req).encode()); jid=r.get('background_job_id')
    open(d+'/jid','w').write(str(jid))
    for _ in range(90):
        time.sleep(6); j=call(f'https://api.pixellab.ai/v2/background-jobs/{jid}')
        if j.get('status') in ('completed','failed'): break
    if j.get('status')!='completed': print(k,'status',str(j)[:300]); raise SystemExit(1)
    ims=j['last_response'].get('images') or [j['last_response'].get('image')]
    for n,im in enumerate(ims): open(f'{d}/{n:02d}.png','wb').write(base64.b64decode(im['base64'].split(',')[-1]))
    b1=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    json.dump({"desc":B[k],"size":s,"before":b0,"after":b1,"count":len(ims)},open(d+'/rec.json','w'))
    open(d+'/done','w').write('1'); print(k,s,len(ims),b0,'->',b1,flush=True)
