import sys,os
sys.argv=['x']
exec(open('run3.py').read().split("for k,pid in enumerate")[0])
S=" Redraw from scratch as clean pixel art: solid flat color areas with only 2-3 shade steps, no noise, no speckles, no dithering, no texture, crisp single 1px dark navy outline, small dark round eye with 1px white highlight, no glow, no sparkles, no particles, no ground shadow."
J={
"wolf":("bk3/wolf_base.png",2026112311,"A chibi wolf, same pose and design: black-gray fur, cream face and tail tip, torn yellowed wallpaper scarf, plain dark paws."+S),
"penguin":("bk3/penguin_g.png",2026112312,"A chibi penguin, same pose and design: black and white body, dull-yellow guard cap with a small green badge, orange beak and feet."+S),
"duck":("bk3/duck_g.png",2026112313,"A chibi duck, same pose and design: cream white feathers, orange bill and feet, yellow rubber-duck swim ring around the waist."+S),
}
for pid,(ref,seed,desc) in J.items():
    out=f'bk4/{pid}'
    if os.path.exists(out+'.png'): continue
    o,a,b=gen(open(ref,'rb').read(),desc,seed,out); print(pid,a,'->',b,flush=True)
