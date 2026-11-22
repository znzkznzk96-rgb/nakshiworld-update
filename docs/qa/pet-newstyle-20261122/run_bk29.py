from gen5 import *
C=" Chibi 16-bit pixel art character sprite, big head, small body, right-facing 3/4, 1px navy outline, 2-3 flat shades, no gradients, no noise, no glow, no halo, no shadow. Black void face with small eyes. Palette lavender, white, violet, gold."
J={
"n1":"Archangel: white and gold plate armor dress, three stacked layers of huge feathered wings on each side, long flowing white cape, gold winged headpiece, holds a gold spear.",
"n2":"Seraph: six-winged angel with three layers of wings per side in white, lavender and gold, floating gold ribbon sashes, a gold chest gem, tall gold hood ornament, hands clasped.",
"n3":"Demon lord: dark violet armor, three layers of huge bat wings per side with red crystal ribs, curved gold-tipped horns, long cape, red crystal chest gem, gold spiked shoulder pieces, long tail.",
"n4":"Imp prince: black-violet body with a spiky red crystal mane, three layers of sharp small wings per side, a gold crown, long forked tail with gold tip, gold claws, toothy grin.",
"n5":"Butterfly queen spirit: flowing lavender gown with gold star hem, three layers of huge butterfly wings per side with gold star patterns, tall gold star crown, floating star orbs beside its hands.",
"n6":"Lake fairy spirit: pale blue and white gown flowing into long ribbons, three layers of translucent blue butterfly wings per side with gold edges, a gold fishing-hook scepter, a shell crown."}
for i,(k,d) in enumerate(J.items()):
    if os.path.exists(f'bk29/{k}.png'): continue
    gen5(d+C,2026123001+i,f'bk29/{k}')
