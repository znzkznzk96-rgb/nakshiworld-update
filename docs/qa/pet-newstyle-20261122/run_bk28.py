import sys,os
exec(open('run3.py').read().split("for k,pid in enumerate")[0])
S=" Tiny chibi humanoid with big head, two arms and two legs, right-facing 3/4. Keep the exact same pixel style, size, 1px outline, palette and black void face as the input. Remove ground shadow, no glow, no ring, no halo. Transparent background."
J={
"h1":("bk27/e1_f.png","Obvious top-rank angel: three stacked layers of pale feathered wings on each side with gold edges, gold shoulder armor, long gold-trimmed sash, gold bell and one gold cardboard cube, sleepy white eyes."),
"h2":("bk27/e2_f.png","Obvious top-rank angel with a different look: a long white hooded robe, three stacked layers of white and lavender wings on each side with gold tips, a gold key charm, gold armlets, calm round white eyes."),
"h3":("bk27/d0_f.png","Obvious top-rank demon: three stacked layers of dark bat wings on each side with red crystal edges, big red crystal horns, gold chain belt, gold shoulder spikes, white eyes and a toothy grin."),
"h4":("bk27/e4_f.png","Obvious top-rank demon with a different look: round dark violet body, three stacked layers of dark violet wings on each side with red crystal rims, four red crystal horns, gold collar, gold spade tail, holds a gold cardboard cube, red slit eyes."),
"h5":("bk27/e5_f.png","Obvious top-rank spirit: three stacked layers of lavender butterfly wings on each side with gold star marks, a gold star crown, floating gold star orbs near its hands, flowing cloak, closed happy arc eyes."),
"h6":("bk25/g6_f.png","Obvious top-rank spirit with a different look: pale blue and white body, three stacked layers of translucent blue butterfly wings on each side with gold edges, a gold hook charm and a gold cardboard cube, round white eyes.")}
for k,(src,d) in J.items():
    out=f'bk28/{k}'
    if os.path.exists(out+'.png'): continue
    assert len(d+S)<=500,len(d+S)
    o,a,bb=gen(open(src,'rb').read(),d+S,2026122900+int(k[-1]),out); print(k,a,'->',bb,flush=True)
