import sys,os
src=open('run3.py').read(); exec(src[:src.index('for k,pid in enumerate')])
for k,pid in enumerate(sys.argv[1:]):
    ref,name,an,col,parts,hl,tex=P[pid]; d=f'final/{pid}1x'; os.makedirs(d,exist_ok=True)
    if os.path.exists(f'{d}/gen.png'): continue
    s=(f"Redraw this {name} as a detailed 16-bit indie game sprite: realistic {an} proportions, same face, {col}, small plain eyes, same pose and silhouette. "
       f"Muted natural palette, thin dark navy outline, 3-4 shade steps with pixel clusters, deeper shadows under head and belly, highlights on {hl}, subtle {tex} shading. No gradients, no ground shadow.")
    o,a0,b=gen(open(ref,'rb').read(),s,2026121000+k,f'{d}/gen'); print(pid,len(s),a0,'->',b,flush=True)
