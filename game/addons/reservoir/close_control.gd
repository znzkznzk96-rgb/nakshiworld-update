extends RefCounted
const SIZE:=Vector2(22,23)
const ART=preload("res://art/shop_repair/header.png")
static func draw(m,box:Rect2)->void:
 var r:=Rect2(box.position.round(),SIZE)
 var mouse:Vector2=m.get_viewport().get_mouse_position()-Vector2(m.ox,0)
 var pressed:bool=Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and r.grow(3).has_point(mouse)
 if pressed:r.position.y+=1
 var src:Vector2=ART.get_size();var edge:float=24;var border:float=4
 var xs:Array=[0.0,edge,src.x-edge,src.x];var ys:Array=[0.0,edge,src.y-edge,src.y]
 var dx:Array=[r.position.x,r.position.x+border,r.end.x-border,r.end.x];var dy:Array=[r.position.y,r.position.y+border,r.end.y-border,r.end.y]
 for iy in 3:
  for ix in 3:
   m._ui_texture_rect_region(ART,Rect2(dx[ix],dy[iy],dx[ix+1]-dx[ix],dy[iy+1]-dy[iy]),Rect2(xs[ix],ys[iy],xs[ix+1]-xs[ix],ys[iy+1]-ys[iy]),Color(.85,.85,.85) if pressed else Color.WHITE)
 var origin:Vector2=(r.get_center()-Vector2(5,5)).floor()
 var points:Array[Vector2i]=[Vector2i(0,0),Vector2i(4,0),Vector2i(1,1),Vector2i(3,1),Vector2i(2,2),Vector2i(1,3),Vector2i(3,3),Vector2i(0,4),Vector2i(4,4)]
 for p in points:m._ui_rect(Rect2(origin+Vector2(p)*2+Vector2.ONE,Vector2(2,2)),Color("392316"))
 for p in points:m._ui_rect(Rect2(origin+Vector2(p)*2,Vector2(2,2)),Color("fff0cc"))
