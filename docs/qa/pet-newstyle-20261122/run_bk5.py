from gen5 import *
S=" Pixel art game pet sprite, chibi 2-head-tall, right-facing 3/4 view, full body, clean flat shading with 2-3 tones, small dark eyes with white highlight, no glow, no sparkles, no particles, no ground shadow."
J=[
("cd_duck",2026112411,"A plain cream-white duck with orange bill and feet wearing a worn yellow rubber-duck swim ring. Simple standing pose, one prop only."+S),
("b_turtle",2026112412,"A teal turtle with a cardboard box backpack strapped on and a faded yellow wallpaper stripe pattern on its shell. Simple pose, one prop and one accent color."+S),
("a_hedgehog",2026112413,"A hedgehog whose spines are strips of peeling yellowed wallpaper, with a damp brown carpet belly and a small green exit-sign badge on its chest."+S),
("s_hamster",2026112414,"A Backrooms creature that is a hamster remade as a monster: body of damp brown carpet fabric with yellow wallpaper patches and stitched seams, a pale fluorescent tube lodged on its back like a spine drawn as a solid bar, round ears like torn wallpaper."+S),
("ss_fox",2026112415,"A Backrooms entity shaped like a fox: slim body of black void with torn yellow wallpaper skin, tail made of three bent fluorescent tubes drawn as solid pale bars, hollow eyes, exit-sign green accents on paws and ears, more menacing and ornate than a pet."+S),
("sss_wolf",2026112416,"A large imposing Backrooms entity wolf creature filling the frame: body of shadow with rusted pipes and torn wallpaper cape, a crown of fluorescent tubes as solid pale bars, long jaw, pale hollow eyes, ornate gold-yellow armor trim, the most powerful and majestic design."+S),
]
for n,seed,d in J:
    if os.path.exists(f'bk5/{n}.png'): continue
    gen5(d,seed,f'bk5/{n}')
