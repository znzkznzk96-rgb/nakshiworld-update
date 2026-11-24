import sys;sys.argv=['x']
exec(open('gen5.py').read().split("if __name__")[0])
V="vivid saturated glossy arcade slot machine symbol, bright candy colors, thick black outline, high contrast, shiny highlights, "
S=[("D","a cute pink and orange worm bait on a silver hook"),
("C","a bright red and white fishing bobber float"),
("B","a spiral seashell, hot pink and yellow"),
("A","a big white pearl in an open bright blue clam shell"),
("S","a big shiny golden yellow five-point star with orange edge"),
("SS","a golden crown with huge red ruby and blue gems"),
("SSS","a glowing rainbow angel wing with golden halo and sparkles")]
for i,(k,d) in enumerate(S):
    gen5(V+d+", centered icon",2026112520+i,'slot/v2_'+k,{"image_size":{"width":48,"height":48},"view":"side","direction":"south"})
