from gen5 import *
C=" Abstract spirit creature, no animal parts. Cute and cool chibi, right-facing 3/4. 16-bit pixel art, 1px navy outline, 2-3 flat shades, no gradients, no noise. Round black void face with two small white dot eyes. Lavender, white, violet, gold palette. No halo, sparkles or shadow."
J={
"k1":"Diving-bell spirit: a round lavender glass diving helmet with a void face, tiny blue body, gold rivets, coiled fishing line.",
"k2":"Fishing float spirit: a pale blue and white bobber body with a void face, gold hook as a tail, small ripple ring base.",
"k3":"Raindrop spirit: a translucent blue droplet body with a void face, a gold crown of small water crests.",
"k4":"Tackle box spirit: a small violet tackle box body whose open lid frames a void face, gold latch, tiny legs.",
"f1":"Comet spirit: a round pale lavender body with a void face and a long gold star-trail tail.",
"f2":"Lantern spirit: a pale paper-lantern body with a void face and three gold star-shaped flame tails.",
"f3":"Constellation cloak spirit: a floating violet hooded cloak with gold star studs, a void face and a small gold star crown.",
"f4":"Moon spirit: a crescent-moon shaped pale body with a void face, small gold stars studded on it, tiny feet.",
"h1":"Brazier spirit: a small dark violet iron brazier body with a void face and a red crystal flame on top.",
"h2":"Firework spirit: a round dark violet bomb-like body with a void face, red crystal fuse spikes and a gold cap.",
"h3":"Phoenix egg spirit: an egg-shaped dark violet body cracked with red crystal glow, a void face, tiny feet.",
"h4":"Armor golem spirit: a chubby dark violet armored body with a void face visor, red crystal horns, gold trim."}
for i,(k,d) in enumerate(J.items()):
    if os.path.exists(f'bk19/{k}.png'): continue
    gen5(d+C,2026121001+i,f'bk19/{k}')
