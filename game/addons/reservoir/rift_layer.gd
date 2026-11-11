extends Node2D
var environment:RefCounted
var kind:=""
var clouds:Array[Texture2D]=[]
func _draw()->void:
	if environment==null:return
	var t:float=environment.elapsed
	if kind=="clouds":
		if clouds.is_empty():
			for n in ["cloud_wisp","cloud_cumulus","cloud_far"]:clouds.append(load("res://art/atmosphere/%s.png"%n))
		for i in 4:
			var w:float=[350,280,410,240][i]
			var tex:Texture2D=clouds[i%3];var h:float=w*tex.get_height()/tex.get_width()
			var x:float=fposmod(i*311+t*(3.0+i),1500)-400
			draw_texture_rect(tex,Rect2(x,100+i*118,w,h),false,Color(.75,.43,.95,.48))
	elif kind=="rocks":
		for i in 4:
			var center:=Vector2([180,760,950,520][i],[210,190,420,600][i]+sin(t*.75+i)*9)
			var points:=PackedVector2Array()
			for v in [Vector2(-17,-24),Vector2(11,-30),Vector2(24,-2),Vector2(7,29),Vector2(-21,12)]:points.append(center+v*(1.0+i*.12))
			draw_colored_polygon(points,Color("3c275f"));draw_polyline(PackedVector2Array([points[0],points[1],points[2]]),Color("9766b7"),2,false)
			draw_polyline(PackedVector2Array([center+Vector2(6,-26),center+Vector2(-3,-1),center+Vector2(6,22)]),Color(.67,.32,1,.65),2,false)
	elif kind=="surface":
		for band in 6:
			var pts:=PackedVector2Array()
			for x in range(0,1097,16):pts.append(Vector2(x,environment.WATER_Y+band*9+roundf(sin(x*.018+t*1.8+band)*3+cos(x*.031-t*.9)*2)))
			draw_polyline(pts,Color(.72,.45,.96,.44 if band==0 else .12),2,false)
	elif kind=="foam":
		var x:float=environment.map_rect.size.x/environment.SOURCE.x
		var b:float=environment.bob_offset()/maxf(.001,x)
		for i in 9:
			var p:=Vector2(i*40,environment.WATER_Y+sin(t*2+i*.8)*3)
			draw_line(p,p+Vector2(19+sin(t+i)*6,0),Color(.88,.74,1,.34),2,false)
		# Light is attached to the boat, with the same displacement as its deck.
		var lamp:=Vector2(125,environment.DECK_Y-306+167+b)
		for r in [35.0,22.0,11.0]:draw_circle(lamp,r,Color(1,.65,.30,.025),false,-1,false)
