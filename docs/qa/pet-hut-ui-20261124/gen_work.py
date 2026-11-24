import sys,json,base64,time,os
sys.argv=['x']
exec(open('gen5.py').read().split("if __name__")[0])
from concurrent.futures import ThreadPoolExecutor
OUT='../pet-hut-ui-20261124/work/'
D={
'd_chick':"the little chick pecks the ground quickly again and again with its beak, digging up a small white pearl",
'd_frog':"the green frog shoots its tongue out and grabs a small white pearl, then gulps and croaks",
'd_mouse':"the grey mouse digs the ground fast with both front paws, dirt flying, and pulls out a small white pearl",
'c_mushroom':"the mushroom boy stomps and shakes, the red cap puffs spores that blow dirt away and reveal a small white pearl",
'c_puffbird':"the white bird pecks and pulls hard with its beak, tugging a small white pearl out of the ground",
'c_slime':"the blue slime stretches over the ground, wraps around a small white pearl, and absorbs it with a happy wobble",
'b_hamster':"the hamster digs a little then stuffs a small white pearl into its puffed cheeks",
'b_hedgehog':"the hedgehog scratches the ground with its spiky back and claws, scraping out a small white pearl",
'b_sparrow':"the sparrow hops, pecks the ground, and flaps its wings carrying up a small white pearl in its beak",
'a_fennec':"the fennec fox digs sand quickly with both paws, sand flying, ears twitching, and uncovers a small white pearl",
'a_otter':"the otter smashes a shell against a stone on its belly and picks out a small white pearl",
'a_owl':"the owl stares with glowing eyes at the ground, then dives its talons down and picks up a small white pearl",
's_fairy':"the fairy flutters and sprinkles glittering dust on the ground, a small white pearl floats up into the air",
's_tome':"the spell book flips its pages and glows, magic runes pull a small white pearl up out of the ground",
's_wisp':"the candle flame flares bigger and burns the ground, melting open a small white pearl that sparkles",
'ss_golem':"the stone golem raises both fists and pounds the ground hard, cracks of light, a small white pearl pops out",
'ss_knight':"the knight raises its sword and slashes down, cracking the ground open, a small white pearl pops out with a flash",
'ss_storm':"the storm dragon coils and lightning strikes the ground, rocks crack, a small white pearl is blasted out",
'sss_apostle':"the skeleton king raises his star scepter, a beam of light pulls a small white pearl up from the ground",
'sss_demon':"the dark demon knight slams its sword down, red flames burst, and hooks a small white pearl up from the ground",
'sss_lunar':"the moon maiden raises the glowing orb, moonlight pulls a small white pearl floating up toward her",
'sss_seraph':"the seraph spreads its wings wide, golden feathers fall, and a small white pearl rises up in a ring of light"}
def run(k):
    img=base64.b64encode(open('anim/%s_00.png'%k,'rb').read()).decode()
    req={"first_frame":{"type":"base64","base64":img,"format":"png"},"description":D[k],"frame_count":8,"seed":20261401,"no_background":True,"view":"side"}
    jid=call('https://api.pixellab.ai/v2/animate-pixminimax',json.dumps(req).encode())['background_job_id']
    for _ in range(100):
        time.sleep(5);s=call('https://api.pixellab.ai/v2/background-jobs/%s'%jid)
        if s.get('status') in('completed','failed'):break
    ims=(s.get('last_response') or s).get('images') or []
    for i,im in enumerate(ims):open(OUT+'%s_%02d.png'%(k,i),'wb').write(base64.b64decode(im['base64'] if isinstance(im,dict) else im))
    return k,s.get('status'),len(ims)
if __name__=='__main__':
    b0=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
    with ThreadPoolExecutor(5) as ex:
        for r in ex.map(run,list(D)):print(r,flush=True)
    print(b0,'->',call('https://api.pixellab.ai/v2/balance')['subscription']['generations'])
