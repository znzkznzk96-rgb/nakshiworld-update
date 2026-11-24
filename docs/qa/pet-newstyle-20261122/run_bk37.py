import sys,os
exec(open('run3.py').read().split("for k,pid in enumerate")[0])
K="Keep the same character, colors, outline, size and details. "
J={"y1":("bk25/g4_f.png",K+"Redraw in a true right-facing side view: head and body turned to the right, one foot forward, hood opening and eyes pointing right, cloak trailing behind to the left, compact wide pose. 1px outline, flat shades. Transparent background."),
   "y2":("bk33/f/v4.png",K+"Redraw in a right-facing 3/4 side view: body turned to the right, wings spread behind, hood opening facing right, hold the gold spear diagonally forward to the right in a wide pose. 1px outline, flat shades, no halo. Transparent background."),
   "y3":("bk35/x1_f.png",K+"Only recolor the wings: make the bat wings a slightly reddish dark red with darker red bones and edges, keep the cloak charcoal. Same shape and shading. Transparent background.")}
for k,(b,d) in J.items():
    out=f'bk37/{k}'
    if os.path.exists(out+'.png'): continue
    assert len(d)<=500
    o,a,bb=gen(open(b,'rb').read(),d,2026123900+int(k[-1]),out); print(k,a,'->',bb,flush=True)
