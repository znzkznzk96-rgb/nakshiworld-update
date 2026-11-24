import sys,os
sys.argv=['x']
exec(open('run3.py').read().split("for k,pid in enumerate")[0])
S=" Dark navy 1px outline, small dark round eye with 1px white highlight, muted colors, no ground shadow, no gradients."
J={
"wolf":("final6/wolf/wolf-final.png",2026112301,"Keep this exact wolf, pose and silhouette, but turn the neckerchief into a torn yellowed peeling-wallpaper scarf, make the purple glow pale fluorescent yellow-white, add a small flicker halo above the head and a few dust specks and tiny sparks."+S),
"penguin":("../pet-roster-20261118/penguin-B.png",2026112302,"Keep this exact penguin, pose and silhouette, but replace the purple knit hat and scarf with a small dull-yellow guard cap with a tiny exit-sign green badge, add a small damp-carpet brown patch on the belly. Muted black and white body."+S),
"duck":("../pet-roster-20261118/cd-pixellab-right/reed-duck-A.png",2026112303,"Keep this exact duck, pose and silhouette, remove the reed grass, add a small yellow rubber-duck swim ring around the waist. Simple plain pose, cream white feathers, orange bill and feet."+S),
}
for pid,(ref,seed,desc) in J.items():
    out=f'bk3/{pid}'
    if os.path.exists(out+'.png'): continue
    o,a,b=gen(open(ref,'rb').read(),desc,seed,out); print(pid,a,'->',b,flush=True)
