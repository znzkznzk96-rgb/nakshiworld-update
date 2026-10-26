from pathlib import Path
s=Path('character_work/base.html').read_text()
s=s.replace('낚시월드 · 캐스팅 탄성 / 휨 4단계','낚시월드 · 표정·상체·낚싯대 검토본')
s=s.replace('</nav></div><p>','</nav><nav id="rod-controls">'+''.join('<button id="rod%d">%s</button>'%(i,n) for i,n in enumerate(['대나무','카본','원투','선상','심해','은하']))+'</nav></div><p>')
a=s.index('<p>');b=s.index('</p>',a);s=s[:a]+'<p>표정·상체 반응과 상점 기준 낚싯대 6종 검토본. 낚싯대를 선택하면 같은 동작에서 외형만 바뀝니다. 감기 버튼을 누르고 떼어 비교할 수 있습니다. 실제 게임 적용·배포 전 검토용이며 장력·거리는 시험값입니다.'+s[b:]
s=s.replace("band:0,bandBlend:0", "band:0,bandBlend:0,rod:0")
extras=r'''
const ROD_SKINS=[
 {id:'bamboo',name:'대나무 낚싯대',edge:'#54431c',shaft:'#b88a22',light:'#f5dc58',accent:'#f0bb26',grip:'#77502c'},
 {id:'carbon',name:'카본 낚싯대',edge:'#252c32',shaft:'#374f56',light:'#87b3b4',accent:'#88504e',grip:'#56343b'},
 {id:'surf',name:'원투 낚싯대',edge:'#525d61',shaft:'#d3dfd8',light:'#fff8e4',accent:'#c47456',grip:'#864e3d'},
 {id:'boat',name:'선상 낚싯대',edge:'#213c4a',shaft:'#426a7a',light:'#8fbcc3',accent:'#d6a74e',grip:'#71502e'},
 {id:'deep',name:'심해 낚싯대',edge:'#112622',shaft:'#184e3e',light:'#349977',accent:'#65c7a3',grip:'#614826'},
 {id:'galaxy',name:'은하 낚싯대',edge:'#2c2047',shaft:'#8056a9',light:'#dba7ec',accent:'#7bd8cb',grip:'#4b355e'}
];
function px(c,x,y,w=1,h=1){ac.fillStyle=c;ac.fillRect(x,y,w,h)}
function expressionFor(t,kind,tension,held){
 if(kind==='cast'){let u=t/1.9;return u>.34&&u<.79?'cast':'focus'}
 if(kind==='fight')return tension>.77?'strain':held?'focus':'brace';
 if(kind==='success')return t<.45?'joy':'smile';
 if(kind==='failure')return 'sad';
 if(kind==='capture'||kind==='hook')return 'surprise';
 return t%3.4>3.16?'blink':'neutral';
}
function faceTexture(name){
 if(name==='neutral')return images.head;
 if(faceCache[name])return faceCache[name];
 const c=document.createElement('canvas');c.width=c.height=160;
 const original=ac;ac=c.getContext('2d');ac.imageSmoothingEnabled=false;ac.drawImage(images.head,0,0);
 // Local profile-eye and mouth overlays only; helmet, nose, jaw, hair and alpha remain original.
 px('#facb93',76,56,5,7);px('#facb93',75,58,1,4);
 px('#facb93',82,65,3,2);px('#facb93',84,65,2,1);
 const ink='#452c28',white='#fff0d5',shade='#b67c4b';
 if(['blink','cast','joy'].includes(name)){
  px(ink,76,59,2);px(ink,78,58,2);px(ink,80,59);if(name==='cast')px(ink,76,55,3);
 }else if(name==='strain'){
  px(ink,76,57,2);px(ink,78,58,3);px(ink,77,60,3);px(ink,79,59);px(ink,76,54,2);px(ink,78,55,3);
 }else if(name==='focus'||name==='brace'){
  px(ink,76,57,5);px(white,77,58,3,2);px(ink,79,58,2,3);px(shade,77,61,3);px(ink,76,54,2);px(ink,78,55,3);
 }else if(name==='sad'){
  px(ink,76,58,4);px(white,77,59,2,2);px(ink,79,59,2,2);px(ink,76,54);px(ink,77,55,3);px(shade,76,62,4);
 }else{
  px(ink,76,55,5,5);px(white,76,57,2,4);px(white,78,56);px(ink,79,57,2,5);px(shade,78,62,3);
  px(ink,77,52,3);
 }
 if(name==='joy'){px(ink,82,65,3,2);px('#bd7655',83,67,2);px(white,82,65,2);}
 else if(name==='smile'){px(ink,82,66,2);px(ink,84,65);}
 else if(name==='surprise'){px(ink,83,65,2,3);px('#d68c65',83,66);}
 else if(name==='strain'||name==='cast'){px(ink,82,65,4,2);px(white,83,65,2);}
 else if(name==='sad'){px(ink,82,66,2);px(ink,84,67);}
 else {px(ink,82,66,3);}
 ac=original;faceCache[name]=c;return c;
}
const faceCache={};
function bodyMotion(t,kind,tension,held){
 let angle=0,dx=0,dy=0;
 if(kind==='cast'){
  let keys=[[0,0],[.22,-3],[.5,-7],[.59,-7],[.76,8],[.84,5],[.93,-1],[1,0]],u=clamp(t/1.9),i=0;while(i<keys.length-2&&u>keys[i+1][0])i++;
  angle=lerp(keys[i][1],keys[i+1][1],smooth((u-keys[i][0])/(keys[i+1][0]-keys[i][0])));
 }else if(kind==='fight'){
  const surge=Math.sin(t*3.1)*(.7+1.8*tension);
  angle=held?-3+tension*4+surge:-6+tension*8+surge;
  dy=Math.sin(t*3.1)*.4*tension;
 }else if(kind==='success')angle=-2*Math.sin(Math.PI*clamp(t/1.2));
 else if(kind==='failure'){let settle=1-smooth((t-1.05)/.65);angle=6*smooth(t/.5)*settle;dy=1.1*smooth(t/.5)*settle}
 return {angle,dx,dy,pivot:[75,103]};
}
function upperPoint(p,m){let a=rad(m.angle),x=p[0]-75,y=p[1]-103;return [75+x*Math.cos(a)-y*Math.sin(a)+m.dx,103+x*Math.sin(a)+y*Math.cos(a)+m.dy]}
function paintRod(near,angle,bend){
 const skin=ROD_SKINS[state.rod],dir=[Math.cos(rad(angle)),Math.sin(rad(angle))];
 for(const [color,w] of [[skin.edge,3.6],[skin.shaft,2],[skin.light,.8]]){
  ac.strokeStyle=color;ac.lineWidth=w;ac.lineJoin='round';ac.beginPath();ac.moveTo(near[0]-dir[0]*12,near[1]-dir[1]*12);
  for(let j=0;j<=40;j++)ac.lineTo(...rodPoint(near,angle,bend,j/40));ac.stroke();
 }
 for(let i=0;i<5;i++){
  const u=.18+i*.17,p=rodPoint(near,angle,bend,u),a=rad(angle+bend*Math.pow(clamp((u-.16)/.84),2));
  ac.save();ac.translate(...p);ac.rotate(a);ac.fillStyle=skin.accent;ac.fillRect(-1,-2.2,2,4.4);ac.fillStyle=skin.light;ac.fillRect(0,-3,1,1);ac.restore();
 }
 ac.save();ac.translate(...near);ac.rotate(rad(angle));ac.fillStyle=skin.grip;ac.fillRect(-13,-2,11,4);
 ac.fillStyle=skin.accent;ac.fillRect(-13,-2,2,4);ac.fillRect(-3,-2,1,4);
 if(state.rod>=3){ac.fillStyle=skin.light;ac.fillRect(1,-2,5,1);ac.fillRect(3,1,3,1)}
 if(state.rod===5){ac.fillStyle=skin.accent;ac.fillRect(-8,-1,2,2)}ac.restore();
}
'''
s=s.replace('let lastPose;',extras+'\nlet lastPose;')
s=s.replace('ac.drawImage(images.lower,pad,pad);ac.drawImage(farCanvas,0,0);',"ac.drawImage(images.lower,pad,pad);const motion=bodyMotion(t,kind,tension,held);const expression=expressionFor(t,kind,tension,held);ac.save();ac.translate(pad+75+motion.dx,pad+103+motion.dy);ac.rotate(rad(motion.angle));ac.translate(-pad-75,-pad-103);ac.drawImage(farCanvas,0,0);")
s=s.replace('ac.drawImage(images.head,pad+shiftX,pad+br.headY);','ac.drawImage(faceTexture(expression),pad+shiftX,pad+br.headY);')
a=s.index(" for(const [color,w] of [['#273b36',3]");b=s.index(" if(kind!=='cast')",a);s=s[:a]+' paintRod(near,angle,bend);\n'+s[b:]
s=s.replace('ac.restore();ac.drawImage(nearCanvas,0,0);','ac.restore();ac.drawImage(nearCanvas,0,0);ac.restore();')
s=s.replace('lastPose={tip:[pos[0]+pad+tip[0]+shiftX,pos[1]+pad+tip[1]+br.upperY],','const worldTip=upperPoint([tip[0]+shiftX,tip[1]+br.upperY],motion);lastPose={motion,expression,rod:state.rod,tip:[pos[0]+pad+worldTip[0],pos[1]+pad+worldTip[1]],')
a=s.index('function demoAt(');b=s.index('function text(',a)
s=s[:a]+'''function demoAt(t){
 if(t<3.4)return{kind:'idle',local:t,held:false,tension:0,distance:100,label:'IDLE / BLINK'};
 if(t<5.3)return{kind:'cast',local:t-3.4,held:false,tension:0,distance:100,label:'CAST / TORSO FOLLOW THROUGH'};
 if(t<9.1)return{kind:'cast',local:(t-5.3)/2,held:false,tension:0,distance:100,label:'CAST / HALF SPEED'};
 if(t<12.3)return{kind:'fight',local:t-9.1,held:true,blend:1,tension:.5,distance:65,cycle:(t-9.1)*11,band:1,label:'REEL / FOCUS'};
 if(t<15.5)return{kind:'fight',local:t-12.3,held:false,blend:0,tension:.88,distance:65,cycle:35.2,band:3,label:'RESIST / STRAIN / BODY PULL'};
 if(t<17.5)return{kind:'capture',local:t-15.5,held:false,tension:.5,distance:5,label:'LIFT / SURPRISE'};
 if(t<19.5)return{kind:'success',local:t-17.5,held:false,tension:0,distance:0,label:'SUCCESS / JOY TO SMILE'};
 if(t<21.2)return{kind:'failure',local:t-19.5,held:false,tension:0,distance:100,label:'MISS / DROOP'};
 if(t<22)return{kind:'idle',local:t-21.2,held:false,tension:0,distance:100,label:'RETURN TO IDLE'};
 let band=Math.min(3,Math.floor((t-22)/1.2));return{kind:'fight',local:1,held:true,blend:1,tension:.5,distance:50,cycle:1,band,label:'BEND '+(band+1)+' / 4'};
}
''' +s[b:]
s=s.replace("text('B · ARM DEPTH / BREATHING'", "text('B · EXPRESSIONS / TORSO / ROD SKINS'")
s=s.replace("text(p.cast?p.cast.phase:'BREATHING / FEET AND SEAT FIXED'", "text(ROD_SKINS[state.rod].id.toUpperCase()+' / '+p.expression.toUpperCase()+' / BODY '+p.motion.angle.toFixed(1)+'deg'")
s=s.replace('(now-state.start)%20.3','(now-state.start)%26.8')
s=s.replace('Promise.all(Object.entries(raw)',"for(let i=0;i<6;i++)document.querySelector('#rod'+i).onclick=()=>{state.rod=i};\nPromise.all(Object.entries(raw)")
s=s.replace("ac.fillStyle='#243e45'","ac.fillStyle=ROD_SKINS[state.rod].edge").replace("ac.strokeStyle='#a6c6bd'","ac.strokeStyle=ROD_SKINS[state.rod].accent").replace("ac.strokeStyle='#dcbd77'","ac.strokeStyle=ROD_SKINS[state.rod].light")
Path('character_work/delivery/B-character-rods-review.html').write_text(s)
