import sys,os
A=sys.argv[1:]; sys.argv=['x']
exec(open('run3.py').read().split("for k,pid in enumerate")[0])
D="Clean up this 96x96 pixel art creature: keep exactly the same design, shape, pose and colors. Fine 1-pixel detail like a classic 16-bit game sprite. Remove noise and stray pixels, make outlines continuous 1px dark navy without gaps or jagged stairs, clean flat 2-3 tone shading, no blur, no ground shadow, transparent background."
for k in A:
    out=f'bk11/{k}'
    if os.path.exists(out+'.png'): continue
    o,a,b=gen(open(f'bk11/in/{k}.png','rb').read(),D,2026113201+int(k[-2:]),out); print(k,a,'->',b,flush=True)
