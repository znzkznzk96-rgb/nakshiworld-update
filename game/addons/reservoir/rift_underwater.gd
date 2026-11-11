extends Node2D
# Decorative only: no capture targets, collision, sonar, RNG, economy or save state.
var environment:RefCounted
var kind:=""
const CLEAR_CENTER:=Rect2(160,800,220,370)
func safe_position(p:Vector2)->Vector2:
	if CLEAR_CENTER.has_point(p):p.x=118 if p.x<270 else 422
	return p
func bubble_position(i:int,t:float)->Vector2:
	var x:float=(70 if i%2==0 else 466)+sin(i*2.17+t*.37)*18+(i%3)*8
	return Vector2(x,1238-fposmod(i*43.7+t*(6+i%5),555))
func _draw()->void:
	if environment==null:return
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE*2)
	var t:float=environment.elapsed
	if kind=="fish":draw_schools(t)
	elif kind=="bubbles":
		for i in 28:
			var p:=bubble_position(i,t);var r:float=1.0+(i%4)*.45
			var a:float=.34+.12*sin(t*.6+i)
			draw_arc(p,r,0,TAU,12,Color(.78,.48,1,a),.7,false)
			draw_line(p+Vector2(-r*.4,-r*.6),p+Vector2(0,-r*.75),Color(.91,.76,1,a+.18),.8,false)
	elif kind=="motes":
		for i in 38:
			var p:=safe_position(Vector2(fposmod(i*163.1+sin(t*.13+i)*7,520)+10,690+fposmod(i*89.3-t*.8,530)))
			var a:float=.12+.11*sin(t*.8+i*2.7)
			draw_rect(Rect2(p.round(),Vector2.ONE*(1 if i%6 else 2)),Color(.75,.53,1,a))
	elif kind=="kelp":draw_plants(t)
	elif kind=="jellies":
		for i in 3:
			var p:=Vector2([95,447,125][i]+sin(t*.18+i)*9,[865,1018,1168][i]+sin(t*.4+i)*6)
			var radius:float=[6,8,5][i]*(1+sin(t*1.2+i)*.08)
			var bell:=PackedVector2Array()
			for j in 9:
				var angle:float=PI+j*PI/8;bell.append(p+Vector2(cos(angle)*radius,sin(angle)*radius*.6))
			draw_colored_polygon(bell,Color(.55,.35,.88,.23));draw_polyline(bell,Color(.84,.66,1,.32),.8,false)
			for strand in 4:
				var pts:=PackedVector2Array()
				for j in 7:pts.append(p+Vector2((strand-1.5)*radius*.4+sin(t*.9+j*.55+strand)*1.8,j*2.2))
				draw_polyline(pts,Color(.73,.46,.95,.19),.7,false)
func draw_schools(t:float)->void:
	var art=environment.game.rift_art
	for school in 3:
		var origin:=Vector2([240,440,86][school]+sin(t*.055+school)*24,[740,916,1107][school]+sin(t*.13+school)*5)
		for i in [10,7,6][school]:
			var p:=safe_position(origin+Vector2((i%5-2)*14,(i/5)*16+sin(i*2.8+t*.8)*4))
			var sp:int=[60,61,63][school];var src:Rect2=art.source_rect(sp,t+i*.13)
			var length:float=12+(i%3)*3;var size:Vector2=src.size*length/src.size.x
			var direction:float=-1 if cos(t*.055+school)>0 else 1
			draw_set_transform(p.round()*2,0,Vector2(-direction*2,2))
			draw_texture_rect_region(art.texture(sp),Rect2(-size/2,size),src,Color(.90,.76,1,.48 if school==0 else .38))
			draw_set_transform(Vector2.ZERO,0,Vector2.ONE*2)
func draw_plants(t:float)->void:
	var anchors:Array=[Vector2(14,810),Vector2(28,1000),Vector2(520,891),Vector2(527,1118),Vector2(60,1242),Vector2(470,1244)]
	for n in anchors.size():
		var anchor:Vector2=anchors[n]
		for branch in 4:
			var height:float=18+fposmod(n*17+branch*13,32)
			var pts:=PackedVector2Array()
			for j in 8:
				var k:float=j/7.0;pts.append(anchor+Vector2((branch-1.5)*k*9+sin(t*.4+n+branch+k*2)*k*3,-k*height))
			draw_polyline(pts,Color(.41,.25,.63,.70),1.2,false)
			for j in [2,4,6]:
				var p:Vector2=pts[j];var side:float=-1 if (j+branch)%3 else 1
				draw_colored_polygon(PackedVector2Array([p,p+Vector2(side*6,-3),p+Vector2(side*3,2)]),Color(.57,.34,.77,.57))
		for crystal in 3:
			var p:Vector2=anchor+Vector2((crystal-1)*5,1);var height:float=6+crystal*3
			draw_colored_polygon(PackedVector2Array([p+Vector2(-2,0),p+Vector2(-2,-height+2),p+Vector2(0,-height),p+Vector2(2,-height+3),p+Vector2(2,0)]),Color(.52,.34,.76,.63))
			draw_line(p,p+Vector2(0,-height+1),Color(.78,.58,.98,.43),.8,false)
