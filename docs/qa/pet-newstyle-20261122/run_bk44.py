import sys,os
exec(open('run3.py').read().split("for k,pid in enumerate")[0])
D="Keep the same character, colors, face, outline, pose and low wide composition. Change only two things: the bat wings must be folded and tucked tight against the back, not spread out; the scythe must lie low along the body pointing left, not standing upright. 1px outline, flat shades. Transparent background."
out='bk44/r2'
os.makedirs('bk44',exist_ok=True)
if not os.path.exists(out+'.png'):
    o,a,b=gen(open('bk43/o2_f.png','rb').read(),D,2026124410,out); print('r2',a,'->',b,flush=True)
