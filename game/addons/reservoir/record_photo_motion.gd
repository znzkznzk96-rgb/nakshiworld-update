extends RefCounted
# Mat-only deformation of approved frame zero. No record writes or RNG consumption.
const FLAT=[51,56,71]
const CEPH=[64]
const JELLY=[47]
const LONG=[3,13,16,26,53,58,70]
const ROUND=[45,52,72,75]
func profile(sp:int)->String:
 if sp in FLAT:return "flat"
 if sp in CEPH:return "ceph"
 if sp in JELLY:return "jelly"
 if sp in LONG:return "long"
 if sp in ROUND:return "round"
 return "fish"
func strength(sp:int,t:float)->float:
 if t<0:return 0.0
 var phase:=fposmod(t+float(sp%5)*.31,5.2)
 if phase>1.15:return 0.0
 return pow(sin(PI*phase/1.15),2)
func offset(sp:int,p:Vector2,t:float)->Vector2:
 var a:=strength(sp,t)
 if a==0:return Vector2.ZERO
 var wave:=sin(t*22.0+p.x*4.0)
 var edge:=absf(p.y-.5)*2.0
 match profile(sp):
  "flat":return Vector2(0,edge*edge*sin(p.x*13.0-t*17.0)*1.8*a-a*.3)
  "ceph":
   var arms:=pow(1.0-p.x,2)
   return Vector2(sin(t*15)*(.5-p.x)*1.3*a,(arms*sin(t*18+p.x*9)*2.5+(p.y-.5)*sin(t*15)*.9)*a-a*.5)
  "jelly":
   var tentacles:=p.x*p.x
   return Vector2((p.x-.35)*sin(t*12)*1.2*a,((p.y-.5)*(1.0-p.x)*sin(t*12)*2.0+tentacles*sin(t*15-p.x*8)*2.3)*a)
  "long":return Vector2(0,sin(p.x*10-t*18)*sin(PI*p.x)*2.5*a-a*.4)
  "round":return Vector2(0,(edge*edge*wave*.8+p.x*p.x*sin(t*20)*.6)*a)
 return Vector2((p.x-.5)*sin(t*20)*.4*a,(p.x*p.x*wave*2.5+sin(PI*p.x)*sin(t*20)*.65)*a-a*.6)
func mesh(m,sp:int,g:Dictionary,t:float,shadow:bool=false)->void:
 var s:Dictionary=g.source
 var r:Rect2=g.fish_rect
 var size:Vector2=s.texture.get_size()
 var activity:=strength(sp,t)
 var color:=Color(.10,.15,.15,.23-.07*activity) if shadow else Color.WHITE
 if activity==0:
  var src:Rect2=s.source
  var uv:=PackedVector2Array([src.position/size,Vector2(src.end.x,src.position.y)/size,src.end/size,Vector2(src.position.x,src.end.y)/size])
  if not s.left:uv=PackedVector2Array([uv[1],uv[0],uv[3],uv[2]])
  var shift:=Vector2(0,2 if shadow else 0)
  m._ui_polygon(PackedVector2Array([r.position+shift,Vector2(r.end.x,r.position.y)+shift,r.end+shift,Vector2(r.position.x,r.end.y)+shift]),PackedColorArray([color,color,color,color]),uv,s.texture)
  return
 # Fixed UV grid: never refit individual frames or recolor approved pixels.
 for y in 6:
  for x in 14:
   var points:=PackedVector2Array();var uv:=PackedVector2Array()
   for corner in [Vector2(x,y),Vector2(x+1,y),Vector2(x+1,y+1),Vector2(x,y+1)]:
    var p:Vector2=corner/Vector2(14,6)
    var d:=offset(sp,p,t)*(r.size.x/140.0)
    if shadow:d*=.35
    points.append(r.position+p*r.size+d+Vector2(0,2 if shadow else 0))
    var sample:=Vector2(p.x if s.left else 1-p.x,p.y)
    uv.append((s.source.position+sample*s.source.size)/size)
   m._ui_polygon(points,PackedColorArray([color,color,color,color]),uv,s.texture)
func environment(m,area:Rect2,t:float)->void:
 var clock:=maxf(0,t)
 # Only the exposed water wedge; no extra shadows on painted tackle.
 for i in 3:
  var p:Vector2=area.position+area.size*Vector2(.035+i*.019,.24+i*.028)
  var w:=area.size.x*(.022+.005*sin(clock*1.5+i))
  m._ui_line(p,p+Vector2(w,0),Color(.75,.92,.88,.20+.05*sin(clock*2+i)),1)
 # Soft broken foliage silhouettes on the outer dirt, clear of mat and labels.
 for i in 5:
  var p:Vector2=area.position+area.size*Vector2(.31+i*.03,.25+i*.008)
  p.x+=sin(clock*.55+i)*.6
  m._ui_circle(p,area.size.x*.012,Color(.12,.20,.15,.07))
func moisture(m,sp:int,g:Dictionary,t:float)->void:
 var r:Rect2=g.fish_rect
 # Small damp contact marks remain on the mat; airborne droplets only on kicks.
 for i in 4:
  var p:=Vector2(r.position.x+r.size.x*(.22+i*.16),r.end.y+1+(i%2))
  m._ui_line(p,p+Vector2(2+i%2,0),Color(.25,.43,.40,.18),1)
func highlights(m,sp:int,g:Dictionary,t:float)->void:
 var r:Rect2=g.fish_rect
 for normalized in g.source.get("glints",[]):
  var p:Vector2=r.position+normalized*r.size+offset(sp,normalized,t)*(r.size.x/140.0)
  m._ui_rect(Rect2(p.round(),Vector2(1,1)),Color(.92,1,.97,.32))
 var a:=strength(sp,t)
 if a>.25:
  for i in 3:
   var p:=Vector2(r.position.x+r.size.x*(.35+i*.2),r.position.y-1-a*(2+i))
   m._ui_rect(Rect2(p.round(),Vector2(1,2)),Color(.76,.91,.90,.55*a))
