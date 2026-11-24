from gen5 import *
C=" Chibi 16-bit pixel art character sprite, big hooded head, small body, right-facing 3/4, 1px dark outline, 2-3 flat shades, no gradients, no noise, no glow, no halo, no shadow. Hood interior is a solid black void with only two small glowing eyes."
J={
"v1":"Reaper demon: dark gray tattered cloak trimmed with red, three stacked layers of red bat wings on each side, holds a large scythe. Glowing red narrow eyes.",
"v2":"Warlock demon: dark purple tattered cloak trimmed with red, three stacked layers of red bat wings on each side, holds a staff topped with a purple crystal, a small red flame floats above the other hand. Glowing red eyes.",
"v3":"Reaper angel: white and gold tattered cloak with gold trim, three stacked layers of white feathered wings on each side, holds a gold scepter. Glowing gold eyes.",
"v4":"Lancer angel: pale lavender and white tattered cloak with gold trim, three stacked layers of white and gold feathered wings on each side, holds a long gold spear. Glowing gold eyes.",
"v5":"Star spirit mage: violet and blue tattered cloak with cyan trim, three stacked layers of translucent butterfly wings on each side, holds a staff topped with a star crystal. Glowing cyan eyes.",
"v6":"Lantern spirit: deep violet and teal tattered cloak with cyan trim, three stacked layers of lavender butterfly wings on each side, holds a small glowing lantern on a hook. Glowing cyan eyes."}
for i,(k,d) in enumerate(J.items()):
    if os.path.exists(f'bk32/{k}.png'): continue
    gen5(d+C,2026123401+i,f'bk32/{k}')
