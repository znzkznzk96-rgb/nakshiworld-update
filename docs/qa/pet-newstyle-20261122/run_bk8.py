from gen5 import *
import sys
T=" Cute simple pixel art pet, chunky pixels, small chibi body, right-facing 3/4 view, full body centered, single dark outline, flat 2-3 tone shading, limited palette of lavender, pale white, deep violet and warm gold, no halo, no sparkles, no background, no ground shadow."
P={
"sss_wolf":"A majestic wolf-shaped rift spirit: body of deep void black with lavender cracks, round black void face with two small glowing white eyes, crown of pale gold crystal shards, violet cloak, gold leg rings, grandest design.",
"s_hamster":"A hamster-shaped spirit creature: round pale white body, black void face with two big white dot eyes, small gold ring earring, tiny lavender crystal on its back.",
"d_tadpole":"A small dark tadpole with a wide leaf-like tail and a tiny taped yellow cardboard tag stuck on its head.",
}
for k in sys.argv[1:]:
    out=f'bk8/{k}'
    if os.path.exists(out+'.png'): continue
    gen5(P[k]+T,2026112801+len(k),out,{"image_size":{"width":48,"height":48}})
