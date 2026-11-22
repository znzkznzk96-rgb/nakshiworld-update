from gen5 import *
C=" Cute but cool game pet creature, chibi 2-head-tall, right-facing 3/4 view, full body. True 16-bit pixel art, uniform 1px dark navy outline, 2-3 flat shade colors, no anti-aliasing, no gradients, no noise. Small crisp dark eyes with 1px white highlight, friendly not scary. Lavender, pale white, deep violet and warm gold palette. No halo, no sparkles, no shadow."
J=[("ss_kingfisher","A kingfisher bird spirit: round fluffy lavender-blue body, long pale gold beak, small gold crest feathers, tiny gold anklets."),
("ss_fox","A fox spirit in a pale lavender hooded cape, big pointed ears, a large fluffy tail with a gold star tip, small gold bell."),
("ss_hawk","A hawk spirit: deep violet feathers, crimson crystal wing tips, small curved gold beak, proud confident pose.")]
for i,(k,d) in enumerate(J):
    if os.path.exists(f'bk14/{k}.png'): continue
    gen5(d+C,2026116001+i,f'bk14/{k}')
