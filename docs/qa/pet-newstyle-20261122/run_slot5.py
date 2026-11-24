import sys;sys.argv=['x']
exec(open('gen5.py').read().split("if __name__")[0])
P="chunky low-resolution pixel art, visible big pixels, flat colors, limited palette of 16 colors, no gradients, no smooth shading, bright cheerful candy colors, thick black outline, "
M=[("a","a bright red and gold arcade slot machine front view with white and cyan trim, big 3x3 reel window with white panel, red ball lever on right side, row of yellow lamps on top"),
("b","a bright turquoise and yellow fishing-themed arcade slot machine front view shaped like a treasure chest, big 3x3 reel window, red ball lever on right side, row of pink and yellow lamps on top"),
("c","a bright pink and gold cute arcade slot machine front view with star decorations, big 3x3 reel window, red ball lever on right side, rows of blinking colorful lamps on top")]
for n,d in M:
    gen5(P+d,2026112550+ord(n),'slot/m5_'+n,{"image_size":{"width":96,"height":112},"view":"side","direction":"south"})
V="classic casino slot machine symbol, no border, no frame, no background, bright saturated colors, thick black outline, glossy highlights, "
S=[("C","a bunch of purple grapes with green leaf"),
("S","a big glossy golden capital letter S with small sparkles"),
("SS","two glossy capital letters SS in gold and red with blue jewels and bigger sparkles"),
("SSS","three huge glowing capital letters SSS in rainbow gold with flames, jewels, halo and many sparkles, very ornate")]
for i,(k,t) in enumerate(S):
    gen5(V+t,2026112560+i,'slot/v4_'+k,{"image_size":{"width":48,"height":48},"view":"side","direction":"south"})
