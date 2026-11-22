import sys,os
exec(open('run3.py').read().split("for k,pid in enumerate")[0])
E="Keep the exact same shape, pose, size, wings and props. Only recolor with clearly distinct color groups. "
J={"w1":("v1",E+"Cloak charcoal dark gray with red trim, wings and cloak lining bright red, scythe blade silver-gray with a red edge, handle dark brown, glowing red eyes. No purple. Keep 1px outline, 2-3 flat shades, no noise. Transparent background."),
   "w6":("v6",E+"Cloak deep navy blue, butterfly wings pale cyan and white with gold patterns, lantern warm yellow, trim cyan, glowing cyan eyes. No purple. Keep 1px outline, 2-3 flat shades, no noise. Transparent background.")}
for k,(b,d) in J.items():
    out=f'bk34/{k}'
    if os.path.exists(out+'.png'): continue
    assert len(d)<=500
    o,a,bb=gen(open(f'bk33/f/{b}.png','rb').read(),d,2026123700+int(k[-1]),out); print(k,a,'->',bb,flush=True)
