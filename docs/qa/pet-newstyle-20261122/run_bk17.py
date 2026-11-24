from gen5 import *
C=" An abstract spirit creature, absolutely no animal parts: no beak, wings, feathers, ears, fur or animal body. Cute chibi, right-facing 3/4. 16-bit pixel art, 1px navy outline, 2-3 flat shades, no gradients, no noise. Round black void face with two small white dot eyes. No halo, sparkles or shadow."
J=[("ss_kingfisher",2026119001,"Water spirit: a round blue-lavender orb body with three blue crystal shards on top like a crown, a gold fishing hook hanging below as a dangling tail, tiny stubby feet, gold ring on the body."),
("ss_hawk",2026119002,"Ember spirit: a round dark violet orb body, red crystal flames rising from head and back, a gold emblem on the chest, tiny stubby feet.")]
for k,seed,d in J:
    if os.path.exists(f'bk17/{k}.png'): continue
    gen5(d+C,seed,f'bk17/{k}')
