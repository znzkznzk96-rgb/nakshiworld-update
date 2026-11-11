extends Node2D
# All geometry uses the half-size 540x1320 production grid, displayed at exact 2x.
var environment:RefCounted
var kind:=""
var cloud:Texture2D
func _draw()->void:
	if environment==null:return
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE*2)
	var t:float=environment.elapsed
	if kind=="sky":
		for i in 66:
			var p:=Vector2(fposmod(i*137.7,536),fposmod(i*79.3,470))
			var a:float=(.24+.20*sin(t*.6+i))*clampf((490-p.y)/200,0,1)
			draw_rect(Rect2(p,Vector2.ONE*(2 if i%11==0 else 1)),Color(.72,.55,1,a))
	elif kind=="clouds":
		if cloud==null:cloud=load("res://art/rift/cloud_bank.png")
		# Separate cloud banks drift slowly without wrapping visibly within the shot.
		var positions:Array=[Vector2(-120,74),Vector2(155,203),Vector2(322,320),Vector2(-142,356)]
		for i in 4:
			var w:float=[365,310,300,325][i]
			var p:Vector2=positions[i]+Vector2(sin(t*.028+i*1.7)*22,sin(t*.05+i)*2)
			var h:float=w*cloud.get_height()/cloud.get_width()
			draw_texture_rect(cloud,Rect2(p,Vector2(w,h)),false,Color(.90,.74,1,[.90,.85,.77,.60][i]))
	elif kind=="reflection":
		# Distant sunset and its broken perspective reflection stop at the waterline.
		for r in range(18,1,-2):draw_circle(Vector2(315,546),r,Color(1,.62,.44,.015))
		for i in 62:
			var y:float=548+i*1.7
			var width:float=8+i*.82
			var x:float=315+sin(i*1.83+t*.8)*(3+i*.11)
			var a:float=(.13+.12*sin(i*2.7+t))*clampf(1.0-i/72.0,0,1)
			draw_line(Vector2(x-width,y),Vector2(x+width,y),Color(1,.42,.69,a),1 if i%3 else 2,false)
		for band in 9:
			var y:float=550+band*11.0
			var points:=PackedVector2Array()
			for x in range(-4,549,4):points.append(Vector2(x,y+roundf(sin(x*.028+t*.7+band*.8)*(2+band*.45)+sin(x*.069-t*.5+band)*1.2)))
			draw_polyline(points,Color(.77,.44,1,.13+band*.009),1,false)
	elif kind=="cliffs":
		# Edge-only fissures leave the central fight space clear.
		var paths:Array=[PackedVector2Array([Vector2(0,838),Vector2(16,844),Vector2(31,835),Vector2(45,838),Vector2(58,828)]),PackedVector2Array([Vector2(0,1005),Vector2(20,1010),Vector2(37,1002),Vector2(51,1006)]),PackedVector2Array([Vector2(512,792),Vector2(522,802),Vector2(533,798),Vector2(540,805)]),PackedVector2Array([Vector2(518,973),Vector2(526,982),Vector2(533,977),Vector2(540,983)]),PackedVector2Array([Vector2(486,1154),Vector2(498,1160),Vector2(515,1154),Vector2(526,1166),Vector2(540,1161)])]
		for i in paths.size():crack(paths[i],t,i+3,.65)
func crack(points:PackedVector2Array,t:float,index:int,width:float)->void:
	var strength:float=.65+.12*sin(t*.55+index*1.9)+.06*sin(t*1.1+index)
	draw_polyline(points,Color(.57,.12,.96,.08*strength),width*14,false)
	draw_polyline(points,Color(.80,.23,1,.20*strength),width*6,false)
	draw_polyline(points,Color(.95,.35,1,.75*strength),width*2.4,false)
	draw_polyline(points,Color(.20,.81,1,.95*strength),width*1.15,false)
	draw_polyline(points,Color(.74,.98,1,.90*strength),maxf(.7,width*.42),false)
