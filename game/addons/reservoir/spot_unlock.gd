extends RefCounted
# Visual-only state; starts only after the existing purchase has been saved.
const DURATION := 3.15
const RELEASE := 1.22
var elapsed := -1.0
var region := -1
var bloom: Texture2D
func active() -> bool: return elapsed >= 0.0 and elapsed < DURATION
func start(n: int) -> void:
 region=n;elapsed=0.0
 if bloom==null:
  var image:=Image.create(96,96,false,Image.FORMAT_RGBA8)
  for y in 96:
   for x in 96:
    var distance:=Vector2(x-47.5,y-47.5).length()/47.5
    var strength:=pow(maxf(0.0,1.0-distance),2.4)
    # Limited, quiet tonal steps, rather than a solid flash or a moving outline.
    var alpha:=floorf(strength*32.0)/32.0
    image.set_pixel(x,y,Color(1.0,0.69+strength*0.26,0.25+strength*0.62,alpha))
  bloom=ImageTexture.create_from_image(image)
func reset() -> void: elapsed=-1.0;region=-1
func update(dt: float, m=null) -> void:
 if not active(): return
 var before:=elapsed
 elapsed=minf(DURATION,elapsed+maxf(0.0,dt))
 if m!=null:
  for cue in [[0.48,"unlock_chain_pull",-8.0,1.0],[0.82,"unlock_latch",-5.0,1.0],[RELEASE,"unlock_chain_release",-7.0,1.0]]:
   if before<float(cue[0]) and elapsed>=float(cue[0]): m.audio_feedback.sound(m,cue[1],cue[2],cue[3])
func scale_at() -> float:
 if elapsed<RELEASE: return 1.0-0.008*smoothstep(0.75,RELEASE,elapsed)
 var t:=elapsed-RELEASE
 if t<0.28:return lerpf(0.992,1.06,1.0-pow(1.0-t/0.28,3))
 if t<0.65:return lerpf(1.06,0.996,smoothstep(0.28,0.65,t))
 return lerpf(0.996,1.0,smoothstep(0.65,0.9,t))
func glow(m, p: Vector2, size: Vector2, alpha: float) -> void:
 if alpha<=0.001:return
 m._ui_texture_rect(bloom,Rect2(p-size/2,size),false,Color(1,1,1,alpha))
func piece(m, texture: Texture2D, source: Rect2, center: Vector2, size: Vector2, angle: float, color:=Color.WHITE) -> void:
 var points:=PackedVector2Array()
 for v in [Vector2(-0.5,-0.5),Vector2(0.5,-0.5),Vector2(0.5,0.5),Vector2(-0.5,0.5)]:points.append((center+(v*size).rotated(angle)).round())
 var uv:=PackedVector2Array([source.position/texture.get_size(),Vector2(source.end.x,source.position.y)/texture.get_size(),source.end/texture.get_size(),Vector2(source.position.x,source.end.y)/texture.get_size()])
 m._ui_polygon(points,PackedColorArray([color]),uv,texture)
func sparkle(m,p:Vector2,size:float,alpha:float) -> void:
 if size<0.3 or alpha<0.01:return
 var a:=Color(1,0.87,0.53,alpha*0.7)
 m._ui_polygon(PackedVector2Array([p+Vector2(0,-size),p+Vector2(size*0.25,-size*0.25),p+Vector2(size,0),p+Vector2(size*0.25,size*0.25),p+Vector2(0,size),p+Vector2(-size*0.25,size*0.25),p+Vector2(-size,0),p+Vector2(-size*0.25,-size*0.25)]),PackedColorArray([a]))
 m._ui_rect(Rect2(p.round()-Vector2.ONE,Vector2(2,2)),Color(1,0.98,0.86,alpha))
func draw(m,s,card:Rect2,h:float) -> void:
 if not active():return
 var t:=elapsed
 var ending:=1.0-smoothstep(2.85,DURATION,t)
 var focus:=smoothstep(0.0,0.28,t)
 var reveal:=smoothstep(RELEASE+0.04,RELEASE+0.52,t)
 var dark:=0.84*focus*ending
 m._ui_rect(Rect2(-m.ox,0,m.VW+2*m.ox,h),Color(0.015,0.025,0.04,dark))
 var z:=scale_at()
 var impact:=maxf(0,1.0-(t-RELEASE)/0.18) if t>=RELEASE else 0.0
 var shake:=Vector2(roundf(sin(t*95)*impact*1.3),roundf(sin(t*71)*impact*1.8))
 var r:=Rect2(card.get_center()-card.size*z/2.0+shake,card.size*z)
 var ih:float=card.size.y-100.0
 var img:=Rect2(r.position+Vector2(8,8)*z,Vector2(208,ih)*z)
 var origin:=img.get_center()
 var flare:=sin(clampf((t-RELEASE)/0.75,0,1)*PI)
 # Bloom behind the card, strongest only at the release, fading to a quiet halo.
 glow(m,origin,Vector2(360,360),flare*0.55*ending)
 m._ui_style_box(m.hud_reference_style,r)
 var src:=Rect2(0,(240-ih)/2,208,ih)
 if region in [2,3]:
  var sz:Vector2=s.images[region].get_size()
  var crop:float=sz.x*ih/208.0
  src=Rect2(0,(sz.y-crop)/2,sz.x,crop)
 var tint:=Color(0.42,0.46,0.5).lerp(Color.WHITE,reveal)
 m._ui_texture_rect_region(s.images[region],img,src,tint)
 # Focus rises from the existing padlock position, keeping the picture unchanged.
 var original:=img.position+Vector2(101,ih*0.35+32)*z
 var lock_center:=original.lerp(origin,focus)+Vector2(0,-2*focus)
 var lock_scale:float=z*lerpf(1.0,1.7,focus)
 var release_age:=maxf(0,t-RELEASE)
 var windup:=smoothstep(0.52,0.79,t)
 var open:=smoothstep(0.82,1.04,t)
 var tension:=smoothstep(0.96,RELEASE,t)
 var lock_alpha:=1.0-smoothstep(RELEASE+0.04,RELEASE+0.28,t)
 # Chain halves swing around their outer anchor under tension, then whip outwards.
 if t<RELEASE+0.4:
  var fly:=1.0-pow(1.0-clampf(release_age/0.4,0,1),2)
  var ca:=1.0-smoothstep(RELEASE+0.16,RELEASE+0.4,t)
  for side in [-1,1]:
   var source:=Rect2(0,19,83,22) if side<0 else Rect2(119,19,89,22)
   var lock_edge:float=lock_center.x+side*17*lock_scale
   var edge:float=img.position.x if side<0 else img.end.x
   var chain_size:=Vector2(absf(lock_edge-edge)+4,22*z)
   var p:=Vector2((lock_edge+edge)/2,lock_center.y-2)
   p+=Vector2(side*(tension*5+fly*150),-fly*22)
   var angle:float=side*(-0.035*windup+0.045*tension+fly*0.55)
   piece(m,s.chains,source,p+Vector2(0,2),chain_size,angle,Color(0,0,0,ca*0.65))
   piece(m,s.chains,source,p,chain_size,angle,Color(1,1,1,ca))
 # Golden light begins in the seam; it is attached to the lock, not the frame.
 var charge:=smoothstep(0.9,RELEASE,t)*(1-smoothstep(RELEASE,RELEASE+0.18,t))
 glow(m,lock_center+Vector2(0,-12)*lock_scale,Vector2(55,48)*lock_scale,charge*0.72)
 if lock_alpha>0.001:
  var recoil:float=sin((t-0.53)*42)*windup*(1-open)*0.035
  var hit:=sin(clampf((t-0.82)/0.14,0,1)*PI)
  var lp:=lock_center+Vector2(roundf(sin(t*48)*windup*(1-open)),hit*3+release_age*release_age*100)
  var angle:float=recoil+release_age*0.65
  var body_center:=lp+Vector2(0,12)*lock_scale
  var shackle_center:=lp+Vector2(-5*open,-19-10*open)*lock_scale
  for shadow in [true,false]:
   var offset:=Vector2(2,4) if shadow else Vector2.ZERO
   var col:=Color(0,0,0,lock_alpha*0.55) if shadow else Color(1,1,1,lock_alpha)
   piece(m,s.chains,Rect2(83,25,36,39),body_center+offset,Vector2(36,39)*lock_scale,angle,col)
   piece(m,s.chains,Rect2(83,0,36,25),shackle_center+offset,Vector2(36,25)*lock_scale,angle-0.12*open,col)
  if charge>0.02:
   glow(m,lp+Vector2(0,-6)*lock_scale,Vector2(30,15)*lock_scale,charge)
   m._ui_rect(Rect2((lp+Vector2(-11,-5)*lock_scale).round(),Vector2(22,1)*lock_scale),Color(1,0.96,0.74,charge))
 # One coherent release: soft hot center, broad tapered shafts, then falling embers.
 if t>=RELEASE and t<2.45:
  var a:=release_age
  var energy:float=(1-smoothstep(0.03,0.48,a))*ending
  for i in 9:
   var angle:float=-PI+TAU*(i+0.23)/9.0
   var direction:=Vector2(cos(angle),sin(angle))
   var cross:=direction.orthogonal()
   var reach:float=(40+(i%3)*23)*(0.3+minf(a/0.17,1.0))
   var width:float=4+(i%2)*3
   var p:=lock_center
   var col:=Color(1,0.83,0.49,energy*0.18)
   m._ui_polygon(PackedVector2Array([p-cross*2,p+direction*reach-cross*width,p+direction*(reach+18),p+direction*reach+cross*width,p+cross*2]),PackedColorArray([col,Color(1,0.8,0.45,0),Color(1,0.8,0.45,0),Color(1,0.8,0.45,0),col]))
  glow(m,lock_center,Vector2(175,175),energy*1.0)
  glow(m,lock_center,Vector2(75,75),energy*1.0)
  for i in 22:
   var delay:float=(i%4)*0.018
   var age:float=maxf(0,a-delay)
   var angle:float=TAU*(float(i)*0.618034)
   var dir:=Vector2(cos(angle),sin(angle))
   var speed:float=45+(i%5)*18
   var travel:float=(1.0-exp(-age*3.0))*speed
   var p:=lock_center+dir*travel+Vector2(0,age*age*38)
   var alpha:float=(1-smoothstep(0.38,1.15,age))*minf(age*35,1.0)
   var side:float=2 if i%4 else 3
   var c:=Color(1,0.72,0.27,alpha) if i%3 else Color(1,0.96,0.73,alpha)
   if i%3==0:
    glow(m,p,Vector2(14,14),alpha*0.4)
    sparkle(m,p,side+1,alpha)
   else:
    var v:=Vector2(0,-3-age*4)
    m._ui_line((p+v).round(),p.round(),Color(1,0.75,0.3,alpha*0.3),1)
    m._ui_rect(Rect2(p.round(),Vector2(side,side)),c)
 # A few restrained glints on the old metal corners; no chasing outlines or bolt.
 if t>=1.65:
  for i in 4:
   var age:=t-1.65-i*0.13
   var envelope:float=sin(clampf(age/0.48,0,1)*PI)*ending
   var p:Vector2=[img.position+Vector2(3,3),Vector2(img.end.x-3,img.position.y+3),img.end-Vector2(3,3),Vector2(img.position.x+3,img.end.y-3)][i]
   glow(m,p,Vector2(27,27),envelope*0.4)
   sparkle(m,p,6*envelope,envelope)
 var ready:=smoothstep(1.78,2.05,t)
 var text_color:=Color("d3c3a2").lerp(Color("fff0d1"),reveal)
 m._text(s.NAMES[region],Vector2(135,r.position.y+(ih+28)*z),12,text_color,true,204)
 if t>=1.78:
  var y:float=r.position.y+(ih+47)*z+4*(1-ready)
  m._text("낚시터 해금",Vector2(135,y),12,Color(1,0.87,0.55,ready),true,180)
  for side in [-1,1]:sparkle(m,Vector2(135+side*67,y-4),3.5,ready*ending)
 elif t>=0.3:
  m._text("봉인을 해제하는 중",Vector2(135,r.position.y+(ih+47)*z),8,Color("c7bda9"),true,180)
 var button:=Rect2(r.position+Vector2(12,card.size.y-42)*z,Vector2(200,29)*z)
 m._ui_style_box(m.sb_primary if ready>0.5 else m.sb_btn,button)
 m._text("입장하기" if ready>0.5 else "해금 중",button.get_center()+Vector2(0,5),11,Color("fff0d1") if ready>0.5 else Color("73654e"),true,188)
