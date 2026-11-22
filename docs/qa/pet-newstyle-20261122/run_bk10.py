import sys,os
A=sys.argv[1:]; sys.argv=['x']
exec(open('run3.py').read().split("for k,pid in enumerate")[0])
D="Clean up this pixel art creature: keep exactly the same design, shape, pose and colors. Make every pixel crisp and aligned to one uniform 2x2 pixel grid, smooth clean outlines without gaps or jagged stairs, one dark navy 1px outline, clean flat shading, no blur, no noise, transparent background."
for k in A:
    out=f'bk10/{k}'
    if os.path.exists(out+'.png'): continue
    o,a,b=gen(open(f'bk10/in/{k}.png','rb').read(),D,2026113101+int(k[-2:]),out); print(k,a,'->',b,flush=True)
