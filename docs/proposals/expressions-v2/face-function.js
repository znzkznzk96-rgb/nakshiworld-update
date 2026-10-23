function faceTexture(name){
 if(name==='neutral')return images.head;
 if(faceCache[name])return faceCache[name];
 const c=document.createElement('canvas');c.width=c.height=160;
 const original=ac;ac=c.getContext('2d');ac.imageSmoothingEnabled=false;ac.drawImage(images.head,0,0);
 const ink='#452c28',skin='#facb93',white='#fff0d5';
 // Retain original eyes for open-eye emotions. No rectangular replacement eye or under-eye bar.
 // Mouth edits stay inside existing skin; nose/cheek/hair/helmet remain untouched.
 px(skin,82,65,3,2);px(skin,84,65,2,1);
 if(name==='blink'||name==='joy'){
  px(skin,76,56,5,7);px(skin,75,58,1,4);
  if(name==='blink'){px(ink,76,59);px(ink,77,60,3);px(ink,80,59);}
  else{px(ink,76,60);px(ink,77,59,3);px(ink,80,60);}
 }else if(name==='strain'){
  // Keep the original eye intact; effort is carried by the lowered brow and clenched mouth.
  px(ink,76,54,2);px(ink,78,55,3);
 }else if(name==='focus'||name==='brace'||name==='cast'){
  // Original iris/white proportions preserved; intent comes from eyebrow and mouth.
  px(ink,76,54,2);px(ink,78,55,3);
 }else if(name==='sad'){
  px(skin,76,54,4);px(ink,76,54);px(ink,77,55,3);
 }else if(name==='surprise'){
  px(skin,76,53,4);px(ink,76,52,4);
 }
 if(name==='joy'){px(ink,82,65,3,2);px('#bd7655',83,67,2);px(white,82,65,2);}
 else if(name==='smile'){px(ink,82,66,2);px(ink,84,65);}
 else if(name==='surprise'){px(ink,83,65,2,3);px('#d68c65',83,66);}
 else if(name==='strain'||name==='cast'){px(ink,82,65,4,2);px(white,83,65,2);}
 else if(name==='sad'){px(ink,82,66,2);px(ink,84,67);}
 else {px(ink,82,66,3);}
 ac=original;faceCache[name]=c;return c;
}
