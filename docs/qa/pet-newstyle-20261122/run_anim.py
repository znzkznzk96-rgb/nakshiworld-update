# PixMiniMax 1종 1안 (사용자 승인 2026-11-23). 단일 요청, jobID 먼저 저장, 자동 재시도 없음, 실패 시 중단.
import json,base64,io,os,sys,time
sys.path.insert(0,'.'); from gen5 import call
from PIL import Image
M={ # 움직임만 서술(외형 서술 금지)
"sss_seraph":"wings flap gently, halo bobs, body floats up and down slightly",
"sss_demon":"cape and wings sway slowly, chest breathes, embers tremble",
"sss_apostle":"staff star twinkles, crown and cloak sway gently, idle breathing",
"sss_lunar":"long hair and dress hem flow weightlessly, orb in hand bobs, idle breathing",
"ss_golem":"chest breathes heavily, shoulders and fists tremble slightly, small rocks float",
"ss_knight":"cape and armor edges waver like smoke, idle breathing, sword tip sways",
"ss_storm":"hair and tail ripple like flowing water, staff tip flickers, floats up and down",
"s_wisp":"flame on top flickers and sways, body bounces softly",
"s_tome":"cover breathes, pages flutter slightly, floats up and down",
"s_fairy":"wings flutter quickly, body floats up and down gently, hair and leaf dress sway softly",
"s_rock":"sprout on top sways in the wind, body breathes slowly",
"s_fairy":"fern-leaf wings flutter quickly, hair and dress hem sway, floats up and down gently",
"a_fennec":"tail sways, large ears twitch, idle breathing",
"a_otter":"holds item to chest and bobs, whiskers and tail wiggle, idle breathing",
"a_owl":"head tilts slightly, feathers ruffle, blinks, idle breathing",
"b_hamster":"cheeks chew, hands tremble quickly, ears perk up",
"b_hedgehog":"back spines ripple in a wave, nose sniffs up and down",
"b_sparrow":"tail feathers bob up and down, wings fold and open slightly, hops in place",
"c_slime":"body squishes and stretches softly, jelly wobbles",
"c_mushroom":"cap bobs slightly, body breathes, tiny hop",
"c_puffbird":"fluffy body puffs in and out while breathing, small hop",
"d_frog":"throat pouch puffs in and out while breathing, small hop",
"d_chick":"tuft and tiny wings flutter, beak opens and closes, hops",
"d_mouse":"nose sniffs, whiskers and ears twitch, tail swishes in an S-curve"}
bal=lambda:call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
for k in sys.argv[1:]:
    out=f'anim/{k}'
    if os.path.exists(out+'.rec.json'): print('skip',k); continue
    im=Image.open(f'final/{k}.png').convert('RGBA'); b=io.BytesIO(); im.save(b,'PNG')
    req={"first_frame":{"type":"base64","base64":base64.b64encode(b.getvalue()).decode(),"format":"png"},"description":M[k],"frame_count":8,"seed":2026112300+len(k),"no_background":True,"direction":"east","view":"side"}
    b0=bal(); r=call('https://api.pixellab.ai/v2/animate-pixminimax',json.dumps(req).encode()); jid=r.get('background_job_id')
    json.dump({"job":jid,"before":b0},open(out+'.job.json','w')); print(k,'job',jid,flush=True)
    for _ in range(120):
        time.sleep(10); s=call(f'https://api.pixellab.ai/v2/background-jobs/{jid}')
        if s.get('status') in('completed','failed'): break
    if s.get('status')!='completed': print('FAIL',k,str(s)[:300]); sys.exit(1)
    ims=s['last_response']['images']; json.dump(s['last_response'],open(out+'.raw.json','w'))
    fr=[]
    for i,x in enumerate(ims):
        d=x['base64'] if isinstance(x,dict) else x; fr.append(Image.open(io.BytesIO(base64.b64decode(d))).convert('RGBA')); fr[-1].save(f'{out}_{i:02d}.png')
    sh=Image.new('RGBA',(fr[0].width*len(fr),fr[0].height)); [sh.paste(f,(i*f.width,0)) for i,f in enumerate(fr)]; sh.save(out+'_strip.png')
    b1=bal(); json.dump({"job":jid,"before":b0,"after":b1,"desc":M[k],"frames":len(fr)},open(out+'.rec.json','w'),ensure_ascii=False); print(k,len(fr),'frames',b0,'->',b1,flush=True)
