extends RefCounted
# Presentation only. Deterministic particles never touch catch RNG or save data.
var lantern:AtlasTexture
func active(m)->bool:return m.active_region in [1,2] and m.scene=="fish"
func anchor(m)->Vector2:return Vector2(m.PX+42,m.SURF-8)
func draw(m)->void:
 if not active(m):return
 var night:float=m.environment.night_strength()
 if night<=.00001:return
 if lantern==null:
  lantern=AtlasTexture.new();lantern.atlas=load("res://art/ui/guide_ac/lantern.png");lantern.region=Rect2(85,0,171,280);lantern.filter_clip=true
 var p:Vector2=anchor(m)+Vector2(0,m.oy)
 m._ui_texture_rect(lantern,Rect2(p-Vector2(4.5,7),Vector2(9,14)),false,Color(1,1,1,night))
 var fighting:bool=m.S.get("phase","")=="fight"
 var fish:Vector2=m.S.get("lastF",{}).get("p",Vector2(-1000,-1000))
 var radius:float=maxf(34,float(m.S.get("lastF",{}).get("body_length",48))*.65)
 var color:Color=Color(.42,.88,1.0) if m.active_region==1 else Color(.63,.61,1.0)
 for i in 10:
  var ph:float=fposmod(m.clock*(.025+float(i%3)*.006)+i*.173,1)
  var x:float=25+fposmod(i*39.7+sin(m.clock*.21+i)*9,220)
  var y:float=lerpf(m.uw_bot,m.WATER+12,ph)
  var q:=Vector2(x,y)
  if fighting and q.distance_to(fish)<radius:continue
  var fade:float=sin(ph*PI)*night*(.16+.04*(i%3))
  m._ui_circle(q+Vector2(0,m.oy),2.0 if i%4==0 else 1.25,Color(color,fade*.18))
  m._ui_circle(q+Vector2(0,m.oy),.65,Color(color,fade))
