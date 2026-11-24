import sys,os,json
sys.argv=[sys.argv[0]]+sys.argv[1:]
A=sys.argv[1:]
sys.argv=['x']
exec(open('run3.py').read().split("for k,pid in enumerate")[0])
D="Redraw this exact same creature as a clean 96x96 pixel art game sprite: same design, shape, pose, colors and proportions, crisp single 1px dark outline, clean flat 2-3 tone shading, sharp pixels, no blur, no halo rings, no sparkles, no floating squares, no ground shadow, transparent background."
for k in A:
    out=f'bk9/{k}'
    if os.path.exists(out+'.png'): continue
    o,a,b=gen(open(f'bk9/crop/{k}.png','rb').read(),D,2026113001+int(k[-2:]),out); print(k,a,'->',b,flush=True)
