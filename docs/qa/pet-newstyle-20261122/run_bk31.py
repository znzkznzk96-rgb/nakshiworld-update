import sys,os
exec(open('run3.py').read().split("for k,pid in enumerate")[0])
import gen5 as G
E1="Keep the exact same body, pose, wings, armor and gold details, 1px outline and flat shading. Change only the face, keep it a solid black void face but with these eyes: "
ED={"r3":("bk30/m3_f.png",E1+"two narrow glowing red slit eyes and a small jagged fang grin."),
    "r6":("bk30/m6_f.png",E1+"two closed happy arc eyes and tiny pink blush dots.")}
for k,(src,d) in ED.items():
    out=f'bk31/{k}'
    if os.path.exists(out+'.png'): continue
    assert len(d)<=500
    o,a,b=gen(open(src,'rb').read(),d,2026123200+int(k[-1]),out); print(k,a,'->',b,flush=True)
C=" Chibi 16-bit pixel art character sprite, big head, small body, right-facing 3/4, 1px navy outline, 2-3 flat shades, no gradients, no noise, no glow, no halo, no shadow. Face is a solid black void with the described eyes. Palette lavender, white, violet, gold."
J={
"r1":"Bell angel: gold bell-shaped gown with a ribbon hem, three stacked layers of white feathered wings on each side, gold harp in hand. Face: big gentle round white eyes.",
"r2":"Sun angel: long white robe, a gold sunburst plate behind its back, three stacked layers of white and gold wings on each side, gold scepter. Face: sleepy half-lidded white eyes.",
"r4":"Jester demon: three stacked layers of dark wings on each side with red crystal ribs, gold bell-tipped horns, tattered cape, red crystal scepter. Face: red slit eyes and a wide jagged grin.",
"r5":"Moon spirit: deep violet gown with gold moon marks, three stacked layers of violet butterfly wings on each side with gold crescents, gold crescent crown, long ribbons, holds a small lantern. Face: closed happy arc eyes."}
for i,(k,d) in enumerate(J.items()):
    if os.path.exists(f'bk31/{k}.png'): continue
    G.gen5(d+C,2026123301+i,f'bk31/{k}')
