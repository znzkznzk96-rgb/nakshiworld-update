import sys,os
exec(open('run3.py').read().split("for k,pid in enumerate")[0])
K="Keep the same character, colors, eyes, outline and details. Composition: an upright hooded figure about 72 pixels wide and 72 tall, body turned slightly right in a 3/4 view like a floating mage, the prop held at its right hand beside the body, small feet visible at the bottom, centered. "
J={"q1":("bk37/y3_f.png",K+"Bat wings spread symmetrically behind on both sides at shoulder height, scythe held upright on the right. 1px outline, flat shades. Transparent background."),
   "q2":("bk37/y2_f.png",K+"Feathered wings spread symmetrically behind on both sides at shoulder height, gold spear held upright on the right, no halo. 1px outline, flat shades. Transparent background."),
   "q3":("bk40/u2_f.png",K+"No wings: a long cloak flowing behind, horns on the hood, a small red flame floating above the right hand. 1px outline, flat shades. Transparent background.")}
for k,(b,d) in J.items():
    out=f'bk41/{k}'
    if os.path.exists(out+'.png'): continue
    assert len(d)<=500,len(d)
    o,a,bb=gen(open(b,'rb').read(),d,2026124200+int(k[-1]),out); print(k,a,'->',bb,flush=True)
