import sys,os
exec(open('run3.py').read().split("for k,pid in enumerate")[0])
K="Keep the same character, colors, face, outline and details. Redraw as a low wide creature composition about 79 pixels wide and 70 tall: a big head at the upper right with the face mostly front-facing and turned only slightly right, the body low and horizontal toward the lower left, short legs at the bottom, a cloak or tail curling out to the left. "
J={"o1":("bk42/p1_f.png",K+"Feathered wings folded up behind the body, short gold spear lying along the body, no halo. 1px outline, flat shades. Transparent background."),
   "o2":("bk42/p2_f.png",K+"Bat wings folded up behind the body, short scythe lying along the body. 1px outline, flat shades. Transparent background."),
   "o3":("bk42/p3_f.png",K+"No wings, horns on the hood, a small red flame above the head. 1px outline, flat shades. Transparent background.")}
for k,(b,d) in J.items():
    out=f'bk43/{k}'
    if os.path.exists(out+'.png'): continue
    assert len(d)<=500,len(d)
    o,a,bb=gen(open(b,'rb').read(),d,2026124400+int(k[-1]),out); print(k,a,'->',bb,flush=True)
