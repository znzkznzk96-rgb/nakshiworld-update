extends RefCounted
# Presentation only: the caller starts this after the existing atomic unlock/save succeeds.
const DURATION := 2.3
var elapsed := -1.0
var region := -1
func active() -> bool: return elapsed >= 0.0 and elapsed < DURATION
func start(n: int) -> void: region=n;elapsed=0.0
func reset() -> void: elapsed=-1.0;region=-1
func update(dt: float, m=null) -> void:
 if not active(): return
 var before:=elapsed
 elapsed=minf(DURATION,elapsed+maxf(0.0,dt))
 if m!=null:
  for cue in [[0.28,"click",-8.0],[0.62,"tension",-15.0],[0.9,"snap",-9.0],[1.25,"record",-13.0]]:
   if before<float(cue[0]) and elapsed>=float(cue[0]): m.audio_feedback.sound(m,cue[1],cue[2])
func scale_at() -> float:
 if elapsed<0.9: return 1.0
 var t:=clampf((elapsed-0.9)/0.65,0.0,1.0)
 return 1.0+0.065*sin(t*PI)
func draw(m, s, card: Rect2, h: float) -> void:
 if not active(): return
 var t:=elapsed
 var fade:=minf(1.0,t/0.15)*minf(1.0,(DURATION-t)/0.25)
 m._ui_rect(Rect2(-m.ox,0,m.VW+2*m.ox,h),Color(0.025,0.035,0.07,0.78*fade))
 var z:=scale_at()
 var r:=Rect2(card.get_center()-card.size*z/2.0,card.size*z)
 m._ui_style_box(m.hud_reference_style,r)
 var ih:float=card.size.y-100.0
 var img:=Rect2(r.position+Vector2(8,8)*z,Vector2(208,ih)*z)
 var src:=Rect2(0,(240-ih)/2,208,ih)
 if region in [2,3]:
  var sz:Vector2=s.images[region].get_size()
  var crop:float=sz.x*ih/208.0
  src=Rect2(0,(sz.y-crop)/2,sz.x,crop)
 var reveal:=smoothstep(0.9,1.35,t)
 m._ui_texture_rect_region(s.images[region],img,src,Color(0.48,0.53,0.59).lerp(Color.WHITE,reveal))
 var center:=img.get_center()
 # Preserve the original chain and padlock pixels; separate their pieces for motion.
 var cp:=img.position+Vector2(0,ih*0.35)*z
 if t<1.18:
  var pull:=smoothstep(0.48,0.9,t)*12.0+pow(clampf((t-0.9)/0.28,0.0,1.0),0.6)*170.0
  var alpha:=1.0-smoothstep(0.93,1.18,t)
  for piece in [Rect2(0,0,83,64),Rect2(119,0,89,64)]:
   var dir:float=-1.0 if piece.position.x==0 else 1.0
   var dst:=Rect2(cp+Vector2(piece.position.x+dir*pull,0)*z,piece.size*z)
   m._ui_texture_rect_region(s.chains,dst,piece,Color(1,1,1,alpha))
  var jiggle:=roundf(sin(t*65.0)*1.5)*(1.0-smoothstep(0.2,0.4,t))
  var lockpos:=cp+Vector2(83+jiggle,-smoothstep(0.9,1.18,t)*25)*z
  # Body, then original shackle lifted sideways with a visible open gap.
  m._ui_texture_rect_region(s.chains,Rect2(lockpos+Vector2(0,25)*z,Vector2(36,39)*z),Rect2(83,25,36,39),Color(1,1,1,alpha))
  var lift:=smoothstep(0.28,0.46,t)
  m._ui_texture_rect_region(s.chains,Rect2(lockpos+Vector2(-4*lift,-8*lift)*z,Vector2(36,25)*z),Rect2(83,0,36,25),Color(1,1,1,alpha))
 # Pixel rays, broken gold pieces, and a stepped expanding ring.
 if t>=0.9 and t<1.85:
  var age:=t-0.9
  var a:=1.0-smoothstep(0.35,0.95,age)
  for i in 24:
   var angle:=TAU*i/24.0
   var dir:=Vector2(cos(angle),sin(angle))
   var dist:float=14+age*(65+(i%5)*17)
   var p:=center+dir*dist+Vector2(0,age*age*15)
   var color:=Color("ffe9a4") if i%3 else Color("fff9e3")
   color.a=a
   m._ui_rect(Rect2(p.round(),Vector2(3 if i%2 else 2,4 if i%3 else 2)),color)
   if i%2==0:m._ui_line((center+dir*(dist-10)).round(),p.round(),Color(1,0.74,0.3,a*0.6),1)
  var radius:=12+age*95
  for i in 32:
   var p:=center+Vector2(cos(TAU*i/32),sin(TAU*i/32))*radius
   m._ui_rect(Rect2(p.round(),Vector2(3,3)),Color(1,0.85,0.5,a*0.7))
 if t>=0.9 and t<1.15:
  m._ui_rect(img,Color(1,0.9,0.68,(1.0-(t-0.9)/0.25)*0.55))
 # One short purple rupture for the rift; no modification to the underlying art.
 if region==3 and t>=0.9 and t<1.13:
  var pts:=[Vector2(0.5,0),Vector2(0.42,0.2),Vector2(0.56,0.18),Vector2(0.45,0.43),Vector2(0.55,0.4),Vector2(0.48,0.63)]
  for i in range(pts.size()-1):
   var a:Vector2=img.position+pts[i]*img.size;var b:Vector2=img.position+pts[i+1]*img.size
   m._ui_line(a.round(),b.round(),Color("a75bff"),5)
   m._ui_line(a.round(),b.round(),Color("fff2ff"),2)
 # A glint travels around the existing frame, then the entry button breathes.
 if t>=1.15:
  var q:=clampf((t-1.15)/0.8,0.0,1.0)*4
  var corners:=[r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y),r.position]
  for i in 4:
   var f:=clampf(q-i,0,1)
   if f>0:m._ui_line(corners[i],corners[i].lerp(corners[i+1],f),Color(1,0.86,0.49,fade),2)
  var sweep:=clampf((t-1.15)/0.55,0,1)
  if sweep<1:m._ui_rect(Rect2(img.position+Vector2(img.size.x*sweep,0),Vector2(2,img.size.y)),Color(1,0.95,0.76,0.38*fade))
 m._text(s.NAMES[region],Vector2(135,r.position.y+(ih+28)*z),12,Color("fff0d1"),true,204)
 m._text("낚시터 해금!" if t>=1.25 else "봉인을 해제하는 중…",Vector2(135,r.position.y+(ih+47)*z),11,Color("ffe7a0"),true,204)
 var button:=Rect2(r.position+Vector2(12,card.size.y-42)*z,Vector2(200,29)*z)
 m._ui_style_box(m.sb_primary,button)
 m._text("입장하기",button.get_center()+Vector2(0,5),11,Color("fff0d1"),true,188)
 if t>=1.5:
  var a:=sin(clampf((t-1.5)/0.8,0,1)*PI)*0.7
  m._ui_rect(button.grow(2),Color(1,0.88,0.56,a),false,1)
