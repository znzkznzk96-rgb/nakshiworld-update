import sys
import rv_anim as R
D=R.D; run=R.run; call=R.call; ThreadPoolExecutor=R.ThreadPoolExecutor
D.update({
'd_frog':"the green frog does a big hop, croaks with its throat puffing out, then lands with a wobble",
'd_mouse':"the grey mouse pops up excitedly, sniffs the air with twitching nose, tail swishing, then stands tall",
'c_mushroom':"the mushroom boy bounces up and down, the red cap wobbles and releases a puff of spores",
'c_puffbird':"the white bird flaps its wings fast, fluffs up its feathers, and chirps with a head bob",
'c_slime':"the blue slime squishes down flat and bounces up stretching tall, jiggling with a happy wobble",
'b_hamster':"the hamster stuffs its cheeks, puffs them out, then pumps a tiny fist in victory",
'b_hedgehog':"the hedgehog curls into a ball and rolls once, then pops up spiky and proud",
'b_sparrow':"the sparrow flutters its wings, hops twice, and sings with its beak open",
'a_otter':"the otter spins a shiny pebble on its belly, then holds it up proudly with a splash of water drops",
'a_owl':"the owl turns its head slowly side to side, blinks big eyes, then spreads its wings wide",
's_fairy':"the fairy flutters its wings and twirls in the air, trailing sparkling dust, then strikes a pose",
's_rock':"the mossy rock creature stomps and shakes, the sprout on its head sways and grows a little leaf",
's_tome':"the spell book flips open its cover by itself, pages flutter, magic runes glow and float out",
's_wisp':"the candle flame flickers and surges bigger, the little flame dances and sparks fly up",
'ss_golem':"the stone golem slams its fists together, the glowing core flares, cracks of light pulse across its body",
'ss_knight':"the knight draws its sword and raises it high, then slashes down with a flash of light",
'ss_storm':"the storm dragon coils in the air, lightning crackles around it, its eyes flash and it roars",
'sss_apostle':"the skeleton king raises his star scepter, the crown glows, magic stars swirl around him",
'sss_demon':"the dark armored demon knight stamps and slams its sword down, red flames burst out around it",
'sss_lunar':"the moon maiden raises the glowing orb, long hair and dress flow in a gentle wind, moonlight sparkles around her"})
ks=[k for k in D if k not in('d_chick','a_fennec','sss_seraph')]
b0=call('https://api.pixellab.ai/v2/balance')['subscription']['generations']
with ThreadPoolExecutor(5) as ex:
    for r in ex.map(run,ks):print(r,flush=True)
print(b0,'->',call('https://api.pixellab.ai/v2/balance')['subscription']['generations'])
