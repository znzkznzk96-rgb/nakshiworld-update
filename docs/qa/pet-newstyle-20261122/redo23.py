import sys,os
src=open('run3.py').read(); exec(src[:src.index('for k,pid in enumerate')])
EXTRA={"whale":" Keep the blue goggles on the head."}
for k,pid in enumerate(sys.argv[1:]):
    ref,name,an,col,parts,hl,tex=P[pid]; d=f'final/{pid}3'
    if os.path.exists(f'{d}/step3b.png'): continue
    o1=open(f'{d}/step1.png','rb').read()
    s2=(f"Edit only the face of this {an}. Keep everything else the same: pixel texture, outline, {parts}, body, colors.{EXTRA.get(pid,'')} "
        "Eyes: small round dark eyes about 3 to 4 pixels wide with a single 1px white highlight, slightly glossy, calm, like a small otter sprite. "
        f"Mouth: a natural short mouth line fitting a {an}, clearly visible, not erased, no big smile.")
    o2,a0,_=gen(o1,s2,2026120300+len(pid)*7+k,f'{d}/step2b')
    s3=f"Keep this exact {an}: same silhouette, pose, face, eyes, mouth, colors and outline. Only enrich the rendering: add more shading steps and pixel clusters for volume, deeper shadows under the head, belly and legs, highlights on {hl}, subtle {tex} shading. Keep it clean and readable, no noisy random texture."
    o3,_,b3=gen(o2,s3,2026120400+len(pid)*7+k,f'{d}/step3b')
    print(pid,a0,'->',b3,flush=True)
