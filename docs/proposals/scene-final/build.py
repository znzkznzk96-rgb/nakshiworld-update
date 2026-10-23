from pathlib import Path
import re,json,base64
s=Path('character_final/delivery/B-character-rods-review.html').read_text()
a=s.index('const raw=')+len('const raw=');b=s.index(';const images=',a);raw=json.loads(s[a:b]);raw['cat']= 'data:image/png;base64,'+base64.b64encode(Path('cat_smooth/frames/look_00.png').read_bytes()).decode()
for k in ['look','hop']:
 for i in range(12):raw['cat_'+k+str(i)]='data:image/png;base64,'+base64.b64encode(Path('cat_smooth/frames/%s_%02d.png'%(k,i)).read_bytes()).decode()
s=s[:a]+json.dumps(raw,separators=(',',':'))+s[b:]
extras=r'''
const CAT_ANCHOR={x:57,ground:570,size:72};
let catFrames={look:[],hop:[]},catParts={},catLast=null;
function catCanvas(w=256,h=256){const c=document.createElement('canvas');c.width=w;c.height=h;c.getContext('2d').imageSmoothingEnabled=false;return c}
function prepareCat(){
 for(const kind of ['look','hop'])for(let i=0;i<12;i++){
  const c=catCanvas(),x=c.getContext('2d');x.drawImage(images['cat_'+kind+i],0,0);let d=x.getImageData(0,0,256,256);
  for(let j=0;j<d.data.length;j+=4)d.data[j+3]=d.data[j+3]<120?0:255;
  x.putImageData(d,0,0);catFrames[kind].push(c);
 }
 const neutral=catFrames.look[0];
 for(const kind of ['look','hop']){catFrames[kind][0]=neutral;catFrames[kind][11]=neutral;}
 // Exact same neutral source provides idle, every action start and every action return.
 const idle=catCanvas();idle.getContext('2d').drawImage(neutral,0,0);catParts.neutral=idle;
 const p=idle.getContext('2d').getImageData(0,0,256,256).data;
 catParts.eyePixels=[];for(let y=117;y<143;y++)for(let x=145;x<195;x++){let j=(y*256+x)*4;if(p[j+3]&&p[j]<65&&p[j+1]<55&&p[j+2]<40)catParts.eyePixels.push([x,y]);}
}
function catAction(t,q){
 if(q.kind==='cast'){let u=clamp((q.local-.85)/1.0);return{kind:'look',frame:Math.min(11,Math.floor(u*12)),u};}
 if(q.kind==='success'){let u=clamp(q.local/1.1);return{kind:'hop',frame:Math.min(11,Math.floor(u*12)),u};}
 return{kind:'idle',frame:0,u:0};
}
function catPose(t,q){
 const action=catAction(t,q),c=catCanvas(),x=c.getContext('2d'),neutral=catParts.neutral;
 if(action.kind==='idle'){
  const phase=t*Math.PI*2/3.6,b=Math.sin(phase)*.85;
  // Tail behind body; original paws/bottom stay fixed. All parts from the NEW neutral.
  x.save();x.translate(88,232);x.rotate(Math.sin(phase*.65)*.045);x.drawImage(neutral,0,160,88,96,-88,-72,88,96);x.restore();
  x.drawImage(neutral,80,225,176,31,80,225,176,31);
  x.drawImage(neutral,80,166,176,59,80,166-b,176,59+b);
  x.drawImage(neutral,88,0,168,176,88,-b,168,176);
  // Local eyelid overlay in the same small dark-eye style; head is never regenerated.
  if(t%4.3>4.16){x.fillStyle='#f9e3a2';for(const [xx,yy] of catParts.eyePixels)x.fillRect(xx,yy-b,1,1);x.fillStyle='#302814';x.fillRect(160,132-b,15,2);}
 }else{x.drawImage(catFrames[action.kind][action.frame],0,0);}
 return{canvas:c,...action};
}
function drawCat(t,q){
 const p=catPose(t,q),x=CAT_ANCHOR.x,y=CAT_ANCHOR.ground-CAT_ANCHOR.size*247/256;
 ctx.fillStyle='rgba(28,33,30,.22)';ctx.fillRect(x+24,CAT_ANCHOR.ground,33,2);
 ctx.drawImage(p.canvas,x,y,CAT_ANCHOR.size,CAT_ANCHOR.size);catLast={...p,canvas:undefined,ground:CAT_ANCHOR.ground,anchorX:x,neutralSource:'cat_look0'};
}
function chairRear(){
 // Warm timber chair, backrest behind actor; seat meets fixed pelvis.
 const r=(x,y,w,h,c)=>{ctx.fillStyle=c;ctx.fillRect(x,y,w,h)};
 r(126,495,7,44,'#4c392e');r(128,496,3,43,'#9e7043');r(124,496,10,4,'#c49b5c');
 r(126,503,13,8,'#67472f');r(127,503,11,2,'#bb8d52');r(128,508,9,1,'#8d6038');
 r(126,519,12,7,'#67472f');r(128,519,9,2,'#bb8d52');
 r(127,537,43,5,'#4f392a');r(128,536,40,3,'#ba8d50');r(130,536,36,1,'#d7b474');
 r(130,542,6,31,'#523b2b');r(131,543,2,29,'#aa7845');r(158,542,6,31,'#523b2b');r(159,543,2,29,'#aa7845');
 r(133,561,28,4,'#65472f');r(133,561,27,1,'#b3854c');
}
function chairFront(){
 const r=(x,y,w,h,c)=>{ctx.fillStyle=c;ctx.fillRect(x,y,w,h)};
 // Only the exposed front rail outside the seated pelvis is in front of the actor.
 r(126,539,12,4,'#74502f');r(127,539,10,1,'#d0a366');r(126,543,5,30,'#6e4d30');r(127,544,2,28,'#b0834e');
}
'''
s=s.replace('function draw(t,forced=null,zoom=false){',extras+'\nfunction draw(t,forced=null,zoom=false){')
s=s.replace('ctx.clearRect(0,0,540,1320);ctx.drawImage(images.background,0,0,540,1320);ctx.drawImage(images.cat,58,506,64,64);', 'ctx.clearRect(0,0,540,1320);ctx.drawImage(images.background,0,0,540,1320);chairRear();drawCat(t,q);')
s=s.replace(" ctx.fillStyle='#69482c';ctx.fillRect(133,539,30,6);ctx.fillRect(135,545,6,25);ctx.fillRect(155,545,6,25);",'')
s=s.replace('ctx.drawImage(actor,...pos);','ctx.drawImage(actor,...pos);chairFront();')
s=s.replace('drawImage(cv,90,365,180,300','drawImage(cv,48,365,180,300')
s=s.replace('B · EXPRESSIONS / TORSO / ROD SKINS','B · CHAIR / UNIFIED CAT / RODS')
s=s.replace('REAR ARM > BODY / HEAD > FRONT ARM','CHAIR + CAT ON INDEPENDENT LAYERS')
s=s.replace('window.ready=true;requestAnimationFrame(frame)','prepareCat();window.ready=true;requestAnimationFrame(frame)')
s=s.replace('낚시월드 · 표정·상체·낚싯대 검토본','낚시월드 · 의자·캐릭터·고양이 통합 검토본')
Path('scene_final/NAKSHIWORLD_SCENE_FINAL.html').write_text(s)
Path('scene_final/scene-functions.js').write_text(extras)
print('Unified cat / chair HTML built')
