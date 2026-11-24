from gen5 import *
T=" Cute simple pixel art pet, chunky pixels, small chibi body, right-facing 3/4 view, full body centered, single dark outline, flat 2-3 tone shading, limited palette of lavender, pale white, deep violet and warm gold, no halo, no sparkles, no background, no ground shadow."
L=" Cute simple pixel art pet, chunky pixels, small chibi body, right-facing 3/4 view, full body centered, single dark outline, flat 2-3 tone shading, soft muted colors with violet shadows, no halo, no sparkles, no background, no ground shadow."
P=[
("sss_otter","A grand otter-shaped tide spirit: pale white body, black void face with two small white eyes, gold crystal crown, floating violet ribbon scarf, gold rings, grandest design."+T),
("sss_dragon","A majestic compact coiled sea-dragon spirit: violet body, black void face with two small white eyes, pale gold lightning horns and fins, gold rings, grandest design."+T),
("sss_whale","A majestic small whale-shaped spirit: round pale lavender body, black void face with two small white eyes, gold crystal crown, gold fin bands, grandest design."+T),
("ss_kingfisher","A kingfisher-shaped spirit: violet and pale white feathers, black void face with white eyes, long gold beak, lavender crystal crest, eerie."+T),
("ss_fox","A fox-shaped spirit in a hooded pale lavender cloak, black void face with two white eyes, tail of gold star shards, eerie."+T),
("ss_hawk","A hawk-shaped spirit: deep black body, crimson crystal spikes on wings, one red glowing eye, ominous."+T),
("s_penguin","A penguin-shaped spirit: round pale white body, black void face with two big white dot eyes, small gold ring on flipper, tiny lavender crystal on head."+T),
("s_frog","A frog-shaped spirit: pale lavender jelly body, black void face with two big white dot eyes, small gold ring, water drop on head."+T),
("a_turtle","A small turtle carrying a taped yellow cardboard box with a small symbol, tiny violet scarf."+L),
("a_chick","A small fluffy chick with a tiny lavender flame tuft and a taped yellow cardboard box on its back."+L),
("a_hedgehog","A small hedgehog with a soft beige face, a taped yellow cardboard box on its spines, tiny violet scarf."+L),
("b_sparrow","A small sparrow holding a fishing float, a taped yellow cardboard tag on its back."+L),
("b_raccoon","A small raccoon with a little taped yellow cardboard tag on its back."+L),
("b_boar","A small boar piglet with a taped yellow cardboard tag on its back."+L),
("c_snail","A small snail whose shell is a pale blue water drop, with a tiny taped yellow cardboard tag."+L),
("c_arrow","A small creature that is a green exit-sign arrow with tiny legs and two dot eyes."+L),
("c_pouch","A small creature that is a folded damp yellow wallpaper pouch with a zipper mouth and two dot eyes."+L),
("d_door","A tiny gray iron door creature with tiny legs and one eye peeking from the door crack."+L),
("d_reflect","A tiny pale blue glass fish-shaped reflection creature standing on small legs, two dot eyes."+L),
]
for i,(k,d) in enumerate(P):
    out=f'bk8/{k}'
    if os.path.exists(out+'.png'): continue
    gen5(d,2026112901+i,out,{"image_size":{"width":48,"height":48}})
