from gen5 import *
import sys
# 모션 고려: 머리·몸통·다리(또는 떠 있는 몸) 구조 분명, 납작한 몸·다리 많음·꼬리 여러 개·흩날리는 리본 금지
T=" High quality 16-bit pixel art game pet, crisp pixels, right-facing 3/4 view, full body, dark violet outline, pixel cluster shading with clear light and shadow, palette of lavender, pale violet, cream, ivory and deep navy, no props, no background."
P={
"sss_seraph":"A legendary seraph knight, small humanoid in ivory armor with a lavender cape, two folded white feathered wings, gold halo, calm golden eyes, holding a short gold spear.",
"sss_demon":"A legendary abyss demon, small humanoid with curved black horns, deep navy skin, small bat wings, thin tail, fierce crimson eyes, tattered violet robe.",
"sss_spirit":"A legendary floating star spirit, round glowing lavender body with two small arms and no legs, crown of pale crystal spikes, wide gentle teal eyes, small gold rings orbiting.",
"sss_lunar":"A legendary lunar witch, small humanoid girl in a deep navy hooded cloak with crescent moon embroidery, long silver hair, sleepy pink eyes, holding a short crescent staff.",
"ss_kirin":"A rare thunder kirin, four-legged deer-horse creature, ivory body, one gold horn, short lavender mane crackling with small teal sparks, proud sharp eyes.",
"ss_crystal":"A rare crystal drake, four-legged small dragon, deep navy scales, pale violet crystal spikes along the back, two small wings folded, bright teal slit eyes.",
"ss_salamander":"A rare flame salamander, four-legged lizard, cream belly, lavender back, tail tip burning with a pink flame, round amber eyes.",
"s_stag":"A mystical spirit fawn, four-legged, ivory fur with pale violet spots, glowing gold antlers, soft dark eyes with long lashes.",
"s_lanternfox":"A mystical lantern fox, four-legged, cream fur, single bushy tail ending in a glowing gold light orb, big pointed ears, narrow clever eyes.",
"s_mothcat":"A mystical moth cat, four-legged cat with two soft lavender moth wings on its back, fluffy ivory chest ruff, feathery antennae, large round violet eyes.",
"a_fennec":"A friendly fennec fox, four-legged, sand-cream fur, huge ears with pink insides, small black nose, cheerful curved eyes.",
"a_otter":"A friendly river otter standing upright, brown-lavender fur, cream face and belly, thick tail, holding a small fish, bright round eyes.",
"a_owl":"A friendly horned owl, round body, ivory and lavender feathers, ear tufts, big orange eyes with heavy brows.",
"b_hamster":"A small hamster, round body, cream and lavender fur, puffed cheeks, tiny paws, shiny black bead eyes.",
"b_hedgehog":"A small hedgehog, four short legs, navy-violet spines, cream face, pink nose, small sleepy eyes.",
"b_sparrow":"A small sparrow, round body, brown and lavender feathers with cream breast, short tail, sharp little black eyes.",
"c_slime":"A cute simple slime creature, round jelly body, translucent lavender with lighter top highlight, two big simple eyes and a tiny smile.",
"c_mushroom":"A cute simple mushroom creature walking on two tiny legs, pink spotted mushroom cap, cream stem body, dot eyes.",
"c_puffbird":"A cute simple round puffball bird, fluffy ivory body, tiny wings, small orange beak, two short legs, wide oval eyes.",
"d_frog":"A basic small frog, four legs, green body with cream belly, big round eyes on top of head.",
"d_chick":"A basic small chick, yellow fluffy body, orange beak and feet, small dot eyes.",
"d_mouse":"A basic small mouse, four legs, gray-lavender fur, pink ears and long pink tail, small black eyes.",
}
os.makedirs('rn1',exist_ok=True)
for v in 'AB':
  for i,k in enumerate(P):
    out=f'rn1/{k}-{v}'
    if os.path.exists(out+'.png'): continue
    gen5(P[k]+T,2026112300+i+(100 if v=='B' else 0),out,{"image_size":{"width":48,"height":48}})
