import sys,os
A=sys.argv[1:]; sys.argv=['x']
exec(open('run3.py').read().split("for k,pid in enumerate")[0])
D="Keep the same character, colors and key shapes, but rebuild it cuter: rounder chubby body, bigger head, short stubby limbs, softer rounded shapes, friendly small eyes, remove any creepy parts like thin tentacles or sharp spikes. True 16-bit pixel sprite, uniform 1px dark navy outline, 2-3 flat shades, no gradients, no noise, no shadow, transparent background."
for k in A:
    out=f'bk18/{k}'
    if os.path.exists(out+'.png'): continue
    o,a,b=gen(open(f'bk13/f/{k}.png','rb').read(),D,2026120001+int(k[-2:]),out); print(k,a,'->',b,flush=True)
