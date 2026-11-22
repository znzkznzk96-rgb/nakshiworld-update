import sys,os
exec(open('run3.py').read().split("for k,pid in enumerate")[0])
S=" Keep the exact same pixel style, size, 1px outline, palette and black void face as the input. Remove ground shadow, no glow, no ring. Transparent background."
J={
"t1":("a10","Make a taller upgraded version of this ghost: a lavender hooded sheet body whose hem trails into a long thin pale-blue fishing-line tail ending in a small gold hook, two small white eyes, one gold cardboard cube on its back plus a tiny gold bell charm."),
"t2":("c16","Make an upgraded version of this winged creature: bigger pale-lavender star-patterned wings with gold star marks, a long soft tail with a gold star tip, sleepy half-closed white eyes in the black void face, one gold cardboard cube on its back."),
"t3":("s08","Make an upgraded version of this dark creature: dark violet round body with a few red crystal shards on its back, narrow glowing red slit eyes in the black void face, a gold collar, one gold cardboard cube on its back.")}
for k,(b,d) in J.items():
    out=f'bk24/{k}'
    if os.path.exists(out+'.png'): continue
    assert len(d+S)<=500,len(d+S)
    o,a,bb=gen(open(f'bk13/f/{b}.png','rb').read(),d+S,2026122600+int(k[-1]),out); print(k,a,'->',bb,flush=True)
