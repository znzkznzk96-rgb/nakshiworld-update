from gen5 import *
C=" Abstract spirit creature, no animal parts. Cute and cool chibi, right-facing 3/4. 16-bit pixel art, 1px navy outline, 2-3 flat shades, no gradients, no noise. Lavender, white, violet, gold palette. No halo, sparkles or shadow."
J={
"k1":"Diving-bell spirit: lavender brass diving helmet body, tiny blue body, gold rivets, coiled fishing line. Face: one big round glass porthole eye with a white highlight, sleepy half-lid.",
"k2":"Fishing float spirit: pale blue and white bobber body, gold hook tail, ripple ring base. Face: two tiny bright dot eyes high on the body and a small open smile.",
"k3":"Raindrop spirit: translucent blue droplet body with a gold crown of water crests. Face: two big glossy sparkly oval eyes with white highlights, rosy cheeks, tiny mouth.",
"k4":"Tackle box spirit: small violet tackle box with a gold latch, tiny legs. Face: a single round cyclops eye peeking from the open lid, a thin gold-lined slit.",
"f1":"Comet spirit: round pale lavender body with a long gold star-trail tail. Face: determined narrow angled eyes with white highlights and a tiny smirk.",
"f2":"Lantern spirit: pale paper-lantern body with three gold star flame tails. Face: warm closed crescent happy eyes (arcs) and a small round mouth, no pupils.",
"f3":"Constellation cloak spirit: floating violet hooded cloak with gold star studs and a small gold star crown. Face: hidden in the hood shadow, only two glowing gold slit eyes visible, no mouth.",
"f4":"Moon spirit: crescent-moon shaped pale body with small gold stars, tiny feet. Face: calm sleepy droopy half-closed eyes with long lashes on the crescent's inner curve.",
"h1":"Brazier spirit: small dark violet iron brazier body with a red crystal flame on top. Face: two fierce angry slanted red glowing eyes and a jagged little mouth.",
"h2":"Firework spirit: round dark violet bomb-like body with red crystal fuse spikes and a gold cap. Face: wide startled round eyes with tiny pupils, a small wavy mouth.",
"h3":"Phoenix egg spirit: egg-shaped dark violet body cracked with red crystal glow, tiny feet. Face: a single eye peeking through the crack, orange iris, curious.",
"h4":"Armor golem spirit: chubby dark violet armored body, red crystal horns, gold trim. Face: a flat visor with one horizontal glowing red slit eye, no mouth."}
for i,(k,d) in enumerate(J.items()):
    if os.path.exists(f'bk20/{k}.png'): continue
    gen5(d+C,2026122001+i,f'bk20/{k}')
