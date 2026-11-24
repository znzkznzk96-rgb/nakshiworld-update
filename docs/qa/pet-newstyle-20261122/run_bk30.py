import sys,os
exec(open('run3.py').read().split("for k,pid in enumerate")[0])
D="Keep the exact same body, pose, wings, armor and gold details. Change only the face to a solid black void face with two small white dot eyes, and make the head slightly bigger like a chibi. Remove any halo. Simplify to 2-3 flat shade colors, uniform 1px dark outline, no anti-aliasing, no noise. Transparent background."
for i in range(1,7):
    k=f'm{i}'; out=f'bk30/{k}'
    if os.path.exists(out+'.png'): continue
    assert len(D)<=500
    o,a,bb=gen(open(f'bk29/n{i}_f.png','rb').read(),D,2026123100+i,out); print(k,a,'->',bb,flush=True)
