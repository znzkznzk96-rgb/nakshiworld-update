import sys;sys.argv=['x']
exec(open('gen5.py').read().split("if __name__")[0])
S=[("D","a small worm bait on a hook, brown and pink, simple icon"),
("C","a red and white fishing bobber float, simple icon"),
("B","a spiral seashell, cream and pink, simple icon"),
("A","a shiny white pearl in an open clam shell, simple icon"),
("S","a glowing yellow five-point star, simple icon"),
("SS","a golden crown with blue gem, simple icon"),
("SSS","a glowing rainbow-colored angel wing with sparkles, simple icon")]
for i,(k,d) in enumerate(S):
    gen5("cozy 16-bit pixel art slot machine symbol: "+d+", centered, warm colors, black outline",2026112500+i,'slot/sym_'+k,{"image_size":{"width":48,"height":48},"view":"side","direction":"south"})
M=["a retro arcade slot machine cabinet seen from front, wooden body with warm brass trim, 3x3 reel window, red lever on right side, row of small lamps on top, cozy fishing theme",
"a cute chunky fishing-themed slot machine seen from front, shaped like a treasure chest with brass corners, 3x3 reel window, lever on right, lamps on top"]
for i,d in enumerate(M):
    gen5("cozy 16-bit pixel art: "+d+", warm night lighting, black outline",2026112510+i,'slot/machine_%d'%i,{"image_size":{"width":128,"height":128},"view":"side","direction":"south"})
