import sys,os
exec(open('run3.py').read().split("for k,pid in enumerate")[0])
E="Keep the exact same shape, pose, size, colors, eyes and props. Add more pixel detail and shading without noise: "
J={"x1":("bk34/w1_f.png",E+"cloak folds with darker charcoal shadow shapes and a lighter highlight edge, tattered hem with red trim lines, wing bones and darker wing edges, silver highlight on the scythe blade. Keep 1px outline, 3-4 clear shade steps. Transparent background."),
   "x6":("bk34/w6_f.png",E+"cloak folds with darker navy shadow shapes and a lighter cyan rim light, small gold star dots on the cloak, golden veins on the butterfly wings, bright yellow light around the lantern. Keep 1px outline, 3-4 clear shade steps. Transparent background.")}
for k,(b,d) in J.items():
    out=f'bk35/{k}'
    if os.path.exists(out+'.png'): continue
    assert len(d)<=500
    o,a,bb=gen(open(b,'rb').read(),d,2026123800+int(k[-1]),out); print(k,a,'->',bb,flush=True)
