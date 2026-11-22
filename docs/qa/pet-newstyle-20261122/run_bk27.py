import sys,os
exec(open('run3.py').read().split("for k,pid in enumerate")[0])
S=" Tiny chibi humanoid with big head, two arms and two legs, right-facing 3/4. Keep the exact same pixel style, size, 1px outline, palette and black void face as the input. Remove ground shadow, no glow, no ring, no halo. Transparent background."
J={
"d0":("g4","Same demon but turned to face right in a 3/4 side view, walking pose with one foot forward, dark hooded cloak, red crystal horns, gold chain belt, white eyes and tiny toothy grin."),
"e1":("g2","Upgraded elite angel: two pairs of pale feathered wings with gold edges, lavender robe with a gold sash, gold bell and one gold cardboard cube, gold shoulder pieces, sleepy white eyes."),
"e2":("g2","Upgraded elite angel: large six-feather wings in white and lavender with gold tips, long white ribbon sash, gold armlets, a small gold key charm, calm round white eyes."),
"e3":("g4","Upgraded elite demon: bigger red crystal horns, small dark bat-like wings with red crystal edges, gold chain belt and gold shoulder spikes, long tail with a gold blade tip, fierce white eyes and grin."),
"e4":("g3","Upgraded elite demon: dark violet body with four red crystal horns, red crystal shard armor on shoulders, gold collar, tail with a gold spade tip, holds a gold cardboard cube, narrow red slit eyes."),
"e5":("g6","Upgraded elite star spirit: flowing lavender cloak with many gold star marks, a gold star crown, two small floating gold star orbs near its hands, closed happy arc eyes."),
"e6":("g5","Upgraded elite water spirit as a tiny humanoid: pale blue flowing robe with a long fishing-line tail ending in a big gold hook, two gold cardboard cubes, round white eyes in the black void face.")}
for k,(b,d) in J.items():
    out=f'bk27/{k}'
    if os.path.exists(out+'.png'): continue
    src=f'bk25/{b}_f.png' if os.path.exists(f'bk25/{b}_f.png') else f'bk25/{b}.png'
    assert len(d+S)<=500,len(d+S)
    o,a,bb=gen(open(src,'rb').read(),d+S,2026122800+int(k[-1]),out); print(k,a,'->',bb,flush=True)
