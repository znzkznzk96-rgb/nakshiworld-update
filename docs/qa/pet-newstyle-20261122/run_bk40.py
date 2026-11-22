import sys,os
exec(open('run3.py').read().split("for k,pid in enumerate")[0])
K="Keep the same character, colors, outline and details, about 78 pixels wide and 68 pixels tall. Make it match small pets that stand on four-ish low legs seen from the right side: a right-facing 3/4 view with the whole head and hood turned right so the face and eyes sit on the right half of the head, body low and horizontal, tail or cloak trailing to the left. "
J={"u1":("bk39/z1_f.png",K+"Wings folded back and spread low behind the body, scythe lying along the back. 1px outline, flat shades. Transparent background."),
   "u2":("bk39/z2_f.png",K+"Low horizontal hooded body with two short legs and a long cloak tail. 1px outline, flat shades. Transparent background.")}
for k,(b,d) in J.items():
    out=f'bk40/{k}'
    if os.path.exists(out+'.png'): continue
    assert len(d)<=500,len(d)
    o,a,bb=gen(open(b,'rb').read(),d,2026124100+int(k[-1]),out); print(k,a,'->',bb,flush=True)
