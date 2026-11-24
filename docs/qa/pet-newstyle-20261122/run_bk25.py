import sys,os
exec(open('run3.py').read().split("for k,pid in enumerate")[0])
S=" Tiny chibi humanoid with big head, two arms and two legs, standing, right-facing 3/4. Keep the exact same pixel style, size, 1px outline, palette and black void face as the input. Remove ground shadow, no glow, no ring. Transparent background."
J={
"g1":("c16","Angel: white-lavender short robe, small pale feathered wings, holds one gold cardboard cube, two small white dot eyes in the black void face."),
"g2":("a10","Angel: lavender hooded robe with long sleeves, big pale wings, tiny gold bell charm, sleepy half-closed white eyes in the black void face."),
"g3":("s08","Demon: dark violet body, small red crystal horns, pointed tail with a gold tip, holds one gold cardboard cube, narrow red slit eyes in the black void face."),
"g4":("a10","Demon: dark hooded cloak, red crystal horns, gold chain belt, mischievous white eyes and a tiny toothy grin in the black void face."),
"g5":("a10","Water spirit: pale blue translucent robe flowing into a thin fishing-line tail with a gold hook charm, round white eyes in the black void face."),
"g6":("c16","Star spirit: lavender cloak with gold star marks, a small gold star hair ornament, closed happy arc eyes in the black void face.")}
for k,(b,d) in J.items():
    out=f'bk25/{k}'
    if os.path.exists(out+'.png'): continue
    assert len(d+S)<=500,len(d+S)
    o,a,bb=gen(open(f'bk13/f/{b}.png','rb').read(),d+S,2026122700+int(k[-1]),out); print(k,a,'->',bb,flush=True)
