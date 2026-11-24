from gen5 import *
C=" Living Backrooms creature, cute chibi but cool, right-facing 3/4. 16-bit pixel art, 1px navy outline, 2-3 flat shades, no gradients, no noise, no glow, no shadow. Yellow wallpaper, cardboard brown, lavender, gold palette."
J={
"a1":"Hallway wraith king: tall hooded yellow wallpaper cloak with gold trim, black void face with two glowing yellow eyes, a crown of three tiny light bulbs, cardboard box shoulder armor.",
"a2":"Fluorescent serpent: coiled body of white light-tube segments with gold clamps, a round black void head with one big eye and a smirk, a small cardboard box on its back.",
"a3":"Cardboard knight: living armor of stacked cardboard boxes with tape-strip cape and gold tape trim, a black void helmet with a thin glowing slit eye, holding a light bulb lance.",
"a4":"Pipe guardian: grey ventilation pipe body with a gold valve wheel crown and pipe arms, a round hatch showing a black void face with tired half-closed eyes.",
"a5":"Elevator spirit: a golden elevator-door body that opens to a black void face with wide curious eyes, a gold floor-indicator crown with small lit numbers, tiny legs.",
"a6":"Ceiling-tile shell guardian: floating pale ceiling-tile armor plates around a small black void face with sharp angry eyes, gold bolts, dangling wire tail.",
"a7":"Exit sign sentinel: tall dark cloaked body with a green exit-sign head, a black void face with a single square white eye, gold chain belt, small box satchel.",
"a8":"CRT overlord: round old monitor body with a pixel smiley on screen, four cable arms ending in gold plugs, an antenna crown with a tiny gold star, stubby feet.",
"a9":"Door wanderer: a yellow door as the body with a gold doorknob and hinge arms, a peephole eye that is big and round with a white highlight, a tiny welcome mat cape.",
"a10":"Tile maze golem: pale bathroom-tile body with moss patches, gold pipe horns, a black void face with soft dot eyes and tiny blush, a cardboard box hat.",
"a11":"Floor lamp spirit: tall slim body, a yellow lampshade hood over a black void face with gentle oval eyes, a long cord tail ending in a gold plug, tiny feet.",
"a12":"Wet carpet beast: a yellow-brown carpet blob body with fringe tassels as legs, gold drain-grate armor on its back, a black void face with wide mischievous eyes and a toothy grin."}
for i,(k,d) in enumerate(J.items()):
    if os.path.exists(f'bk22/{k}.png'): continue
    gen5(d+C,2026122301+i,f'bk22/{k}')
