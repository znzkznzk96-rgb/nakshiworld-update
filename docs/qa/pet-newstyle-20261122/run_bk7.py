from gen5 import *
T=" Cute chibi game pet sprite, big head small body, 2-head-tall, right-facing 3/4 view, full body standing centered, clean simple pixel art, flat 3-tone shading, single dark outline, no ground shadow, no glow, no particles."
C=" Not a normal animal: a Backrooms anomaly creature, still small and pet-like, chibi 2-head-tall, right-facing 3/4 view, full body centered, clean pixel art, flat 3-tone shading, single dark outline, no ground shadow, no particles."
J={
"cd_duck":"A small duck wearing a worn yellow rubber swim ring."+T,
"b_turtle":"A small turtle with a taped cardboard box on its shell, faded yellow wallpaper stripes on the shell."+T,
"a_hedgehog":"A hedgehog with spines made of peeling yellow wallpaper strips and a small green exit-sign badge on its chest."+T,
"s_hamster":"A hamster-like creature whose whole body is stitched damp brown carpet, button eyes, one short fluorescent tube sticking out of its back, wallpaper patch ears."+C,
"ss_fox":"A fox-like creature whose body is a hollow of black shadow wrapped in torn yellow wallpaper, tail of three bent fluorescent tubes, glowing green exit-sign eyes, sharp ear spikes, eerie and ornate."+C,
"sss_wolf":"A wolf-like overlord creature of pure black shadow, cape of torn yellow wallpaper with gold trim, crown of fluorescent tubes, pale hollow eyes, horns of bent pipes, the most majestic and imposing design, slightly larger than other pets."+C,
}
for k,d in J.items():
    for v,seed in (('1',2026112601),('2',2026112702)):
        out=f'bk7/{k}_{v}'
        if os.path.exists(out+'.png'): continue
        gen5(d,seed+hash(k)%97,out)
