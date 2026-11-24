import sys,os
src=open('run3.py').read(); exec(src[:src.index('for k,pid in enumerate')])
KEEP={"whale":"blue goggles and crown","penguin":"knit hat with star and scarf","frog":"water drop pendant","hamster":"purple gem in its paws"}
def s2(an,parts,pid): return (f"Edit only the eyes and mouth of this {an}. Keep everything else the same: pixel texture, outline, {parts}, body, colors, and keep the {KEEP[pid]}. "
    "Eyes: small round dark eyes about 3 to 4 pixels wide with a single 1px white highlight, slightly glossy, calm, like a small otter sprite. "
    f"Mouth: a natural short mouth line fitting a {an}, clearly visible, no big smile.")
def s3(an,hl,tex): return f"Keep this exact {an}: same silhouette, pose, face, eyes, mouth, colors, outline and accessories. Only enrich the rendering: add more shading steps and pixel clusters for volume, deeper shadows under the head, belly and legs, highlights on {hl}, subtle {tex} shading. No ground shadow, no noisy random texture."
mode=sys.argv[1]
for k,pid in enumerate(sys.argv[2:]):
    ref,name,an,col,parts,hl,tex=P[pid]; d=f'final/{pid}3'; os.makedirs(d,exist_ok=True)
    if mode=='eye':   # 기존 최종본에서 눈·입만 수정
        o,a0,b=gen(open(f'{d}/step3b.png','rb').read(),s2(an,parts,pid),2026120500+k,f'{d}/eyefix'); print(pid,a0,'->',b,flush=True); continue
    if os.path.exists(f'{d}/step3c.png'): continue
    s1=f"Redraw this {name} as a detailed game sprite: realistic {an} proportions, same face, {col}, small plain eyes, same pose and silhouette. Desaturated natural palette, thin dark selective outline, many subtle tonal steps, soft lighting with rim light, clear limbs, no anti-aliasing."
    o1,a0,_=gen(open(ref,'rb').read(),s1,2026120600+len(pid)*7+k,f'{d}/step1c')
    o2,_,_=gen(o1,s2(an,parts,pid),2026120700+len(pid)*7+k,f'{d}/step2c')
    o3,_,b3=gen(o2,s3(an,hl,tex),2026120800+len(pid)*7+k,f'{d}/step3c')
    print(pid,a0,'->',b3,flush=True)
