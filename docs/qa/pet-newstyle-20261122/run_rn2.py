from gen5 import *
import sys
# 확대 금지: 등급별 캔버스 크기로 바로 생성, 96 캔버스에 원본 크기 그대로 배치
T=" High quality 16-bit pixel art game pet, crisp pixels, right-facing 3/4 view, full body with empty margin, dark violet outline, pixel cluster shading with clear light and shadow, palette of lavender, pale violet, cream, ivory and deep navy, no background."
S={"sss":96,"ss":88,"s":80,"a":72,"b":64,"c":56,"d":52}
P={
"sss_seraph":"A legendary seraph knight, small humanoid in ivory armor with a lavender cape, two folded white feathered wings, gold halo, calm golden eyes, holding a short gold spear.",
"sss_demon":"A legendary abyss demon, small humanoid with curved horns, deep navy skin with lighter violet highlights, small bat wings, thin tail, fierce crimson eyes, tattered violet robe.",
"sss_apostle":"A legendary star apostle, tall humanoid with a pale skull face and glowing gold eyes, gold spiked crown, long deep navy cloak sprinkled with stars, holding a staff topped with a star.",
"sss_lunar":"A legendary lunar witch, small humanoid girl in a deep navy hooded cloak with crescent moon embroidery, long silver hair, sleepy pink eyes, holding a short crescent staff.",
"ss_golem":"A rare clockwork golem, sturdy humanoid machine of ivory and brass plates, visible gear in the chest, two arms and two legs, single round teal lens eye. Not an animal.",
"ss_knight":"A rare phantom knight, empty suit of lavender armor with a helmet, two arms and two legs, cold teal glow inside the visor, holding a broken sword. Not an animal.",
"ss_storm":"A rare storm cloud spirit, floating cumulus body of pale lavender cloud with two cloud arms, angry gold eyes, small teal lightning bolts under it. Not an animal.",
"s_wisp":"A mystical candle wisp, small humanoid made of cream wax with a lit candle flame as its head, two stubby legs, two dot eyes in the flame. Not an animal.",
"s_tome":"A mystical walking spellbook, deep navy leather book with gold corners and a single eye on the cover, two small legs, pages fluttering. Not an animal.",
"s_rock":"A mystical moss rock spirit, round gray-lavender stone body covered in green moss, two stone legs, glowing teal crack eyes. Not an animal.",
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
os.makedirs('rn2',exist_ok=True)
for i,k in enumerate(P):
  for v in 'AB':
    out=f'rn2/{k}-{v}'
    if os.path.exists(out+'.png'): continue
    n=S[k.split('_')[0]]
    gen5(P[k]+T,2026112500+i+(100 if v=='B' else 0),out,{"image_size":{"width":n,"height":n},"outline":"single color outline"})
