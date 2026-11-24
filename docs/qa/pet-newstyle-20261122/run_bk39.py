import sys,os
exec(open('run3.py').read().split("for k,pid in enumerate")[0])
K="Keep the same character, colors, eyes, outline and details. Redraw with a low, wide, compact right-facing side composition about 78 pixels wide and 68 pixels tall, like a small creature crouching or hovering low, facing right. "
J={"z1":("bk37/y3_f.png",K+"The bat wings spread wide to the left and right behind the body, the scythe is held lying nearly horizontal beside the body, hood and eyes point right. 1px outline, flat shades. Transparent background."),
   "z2":("bk37/y1_f.png",K+"Walking low with one foot forward, long cloak trailing far behind to the left, horns and hood point right. 1px outline, flat shades. Transparent background.")}
for k,(b,d) in J.items():
    out=f'bk39/{k}'
    if os.path.exists(out+'.png'): continue
    assert len(d)<=500,len(d)
    o,a,bb=gen(open(b,'rb').read(),d,2026124000+int(k[-1]),out); print(k,a,'->',bb,flush=True)
