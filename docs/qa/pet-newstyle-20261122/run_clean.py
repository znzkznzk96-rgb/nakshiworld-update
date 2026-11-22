import sys,os
src=open('run3.py').read(); exec(src[:src.index('for k,pid in enumerate')])
for k,pid in enumerate(sys.argv[1:]):
    ref,name,an,col,parts,hl,tex=P[pid]; d=f'final8/{pid}'; os.makedirs(d,exist_ok=True)
    if os.path.exists(f'{d}/gen.png'): continue
    s=(f"Redraw this {name} from scratch as a clean, sharp 16-bit pixel art sprite. Do not copy the source; keep only the species, pose and colors: {col}. "
       "Eyes: small, a dark pupil with one clear white highlight pixel, crisp and sharp. "
       "Dark navy outline, 2 to 3 flat shade steps, clean readable shapes, no noise, no texture, no gradients, no blur, no ground shadow.")
    o,a0,b=gen(open(ref,'rb').read(),s,2026121100+k,f'{d}/gen'); print(pid,len(s),a0,'->',b,flush=True)
