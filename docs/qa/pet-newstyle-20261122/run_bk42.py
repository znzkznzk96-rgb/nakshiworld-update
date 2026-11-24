import sys,os
exec(open('run3.py').read().split("for k,pid in enumerate")[0])
K="Keep the same character, colors, eyes, outline and details. Composition like a front-facing chibi mage: the whole hood, face and two eyes face the viewer symmetrically, body upright and front-facing, about 72 pixels wide and 72 tall, small feet at the bottom, centered. The prop is short and held low at its right hand beside the body, not taller than the head. "
J={"p1":("bk41/q2_f.png",K+"Feathered wings spread symmetrically behind both sides, short gold spear, no halo. 1px outline, flat shades. Transparent background."),
   "p2":("bk41/q1_f.png",K+"Bat wings spread symmetrically behind both sides, short scythe. 1px outline, flat shades. Transparent background."),
   "p3":("bk41/q3_f.png",K+"No wings, wide cloak, horns on the hood, small red flame above the right hand. 1px outline, flat shades. Transparent background.")}
for k,(b,d) in J.items():
    out=f'bk42/{k}'
    if os.path.exists(out+'.png'): continue
    assert len(d)<=500,len(d)
    o,a,bb=gen(open(b,'rb').read(),d,2026124300+int(k[-1]),out); print(k,a,'->',bb,flush=True)
