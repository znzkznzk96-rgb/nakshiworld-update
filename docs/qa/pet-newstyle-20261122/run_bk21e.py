import sys,os
A=sys.argv[1:]; sys.argv=['x']
exec(open('run3.py').read().split("for k,pid in enumerate")[0])
D="Keep the exact same character design and silhouette. Redraw as a true 16-bit game sprite on a uniform 1px pixel grid: uniform 1px dark outline, 2-3 flat clear shade colors, no anti-aliasing, no blur, no gradients, no in-between colors, no noise or stipple dots, small crisp eyes and face, dark areas stay solid dark. Remove the ground shadow and background. Transparent background."
for k in A:
    out=f'bk21/e/{k}'
    if os.path.exists(out+'.png'): continue
    o,a,b=gen(open(f'bk21/{k}.png','rb').read(),D,2026122200+int(k[-2:]),out); print(k,a,'->',b,flush=True)
