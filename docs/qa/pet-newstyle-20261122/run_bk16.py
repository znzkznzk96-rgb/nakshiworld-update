from gen5 import *
C=" Mythical hooded spirit like a floating hooded fox spirit: big round head under a hood, tiny body, round black void face with two small white dot eyes, cute and cool, right-facing 3/4, full body. 16-bit pixel art, 1px navy outline, 2-3 flat shades, no gradients, no noise. No halo, no sparkles, no shadow."
J=[("ss_kingfisher_1",2026118001,"Kingfisher spirit: sky-blue and lavender hooded body, long gold beak jutting from the hood, small blue wing cape, gold feather crest on the hood."),
("ss_kingfisher_2",2026118002,"Kingfisher spirit: floating teal-lavender hooded cloak with orange belly patch, long gold beak jutting from the hood, two small fins like wings."),
("ss_hawk_1",2026118003,"Hawk spirit: deep violet hooded body with a pointed hawk-feather hood crest, red crystal wing cape, small gold hooked beak under the void face, red gem on chest."),
("ss_hawk_2",2026118004,"Hawk spirit: floating dark violet hooded cloak with big red crystal wings spread behind, gold talon feet, small red gem pendant.")]
for k,seed,d in J:
    if os.path.exists(f'bk16/{k}.png'): continue
    gen5(d+C,seed,f'bk16/{k}')
