from pathlib import Path
s=Path('scene_final/NAKSHIWORLD_SCENE_FINAL.html').read_text()
a=s.index('function chairRear(){');b=s.index('function draw(t,forced=null,zoom=false){',a)
fn=r'''function repairFrontPost(){
 // Compose the unoccupied adjacent pier/water strip over only the central foreground post.
 // Source background bytes stay untouched; this is a local scene composition patch.
 const sx=images.background.width/540,sy=images.background.height/1320;
 for(let x=151;x<179;x+=14)ctx.drawImage(images.background,134*sx,545*sy,14*sx,110*sy,x,545,14,110);
}
function chairRear(){
 const r=(x,y,w,h,c)=>{ctx.fillStyle=c;ctx.fillRect(x,y,w,h)};
 // Actual fixed lower-body seat contact is y547, not the former y536 through the hip.
 // All stool structure stays behind the character, and feet stop on top of the deck.
 r(135,551,5,17,'#4c392c');r(136,552,2,15,'#aa7a47');
 r(157,551,5,17,'#4c392c');r(158,552,2,15,'#aa7a47');
 r(138,560,21,3,'#6c4b2f');r(139,560,19,1,'#b58a50');
 r(131,548,35,5,'#4b3527');r(132,547,33,3,'#bc8f52');r(133,547,31,1,'#d9b577');
}
function chairFront(){ /* No backrest or foreground legs/rail over the actor. */ }
'''
s=s[:a]+fn+s[b:]
s=s.replace('ctx.drawImage(images.background,0,0,540,1320);chairRear();','ctx.drawImage(images.background,0,0,540,1320);repairFrontPost();chairRear();')
s=s.replace('B · CHAIR / UNIFIED CAT / RODS','B · STOOL / SEAT CONTACT / CAT')
Path('scene_stool/NAKSHIWORLD_SCENE_STOOL.html').write_text(s)
Path('scene_stool/stool-functions.js').write_text(fn)
