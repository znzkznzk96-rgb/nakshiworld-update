from gen5 import *
C=" Mythical spirit creature, not a real animal, cool but cute chibi, right-facing 3/4, full body. 16-bit pixel art, 1px navy outline, 2-3 flat shades, no gradients, no noise. Round black void face with two small white dot eyes. Lavender, white, violet, gold. No halo, no sparkles, no shadow."
J=[("ss_kingfisher","Kingfisher spirit: lavender hooded cloak body with small wing flaps, long pale gold beak-shaped mask, gold feather crest."),
("ss_fox","Fox spirit: floating pale lavender hooded body with fox ears, big tail of three flame-like streams with gold star tips."),
("ss_hawk","Hawk spirit: round deep violet armored body, crimson crystal wings, pale gold hooked beak-shaped mask, red gem on chest.")]
for i,(k,d) in enumerate(J):
    if os.path.exists(f'bk15/{k}.png'): continue
    gen5(d+C,2026117001+i,f'bk15/{k}')
