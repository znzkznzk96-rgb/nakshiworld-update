import sys;sys.argv=['x']
exec(open('gen5.py').read().split("if __name__")[0])
d="cozy 16-bit pixel art: a cute chunky fishing-themed slot machine seen from front, shaped like a treasure chest with brass corners, 3x3 reel window, lever on right, lamps on top, warm night lighting, black outline"
for n,sz in (("a",192),("b",224)):
    gen5(d,2026112511,'slot/machine_big_'+n,{"image_size":{"width":sz,"height":sz},"view":"side","direction":"south"})
V="classic casino slot machine symbol, no border, no frame, no medallion, no background circle, single object only, bright saturated colors, thick black outline, glossy highlights, "
S=[("D","a pair of red cherries with green stem"),("C","a yellow lemon with a green leaf"),("B","a golden bell"),
("A","a green striped watermelon slice"),("S","a big red lucky number seven with white outline"),
("SS","a large sparkling blue diamond gem"),("SSS","a golden crown with red and blue jewels")]
for i,(k,t) in enumerate(S):
    gen5(V+t,2026112540+i,'slot/v3_'+k,{"image_size":{"width":48,"height":48},"view":"side","direction":"south"})
