extends Node2D
# All positions use the immutable plate's native803x1959 coordinate system.
# Deterministic environment motion never consumes the fishing random stream.
var environment: RefCounted
var game: Node2D
var kind := ""
var enabled := true
const POST_ANCHORS := [Vector2(41,918),Vector2(107,927),Vector2(239,926),Vector2(283,909),Vector2(347,910)]
const LIGHT_PANES := [Rect2(152,664,12,23),Rect2(1,656,14,26),Rect2(196,657,3,5),Rect2(204,657,3,5),Rect2(341,668,3,6),Rect2(348,668,3,6),Rect2(363,669,4,6),Rect2(373,669,4,6),Rect2(649,672,3,7),Rect2(656,672,3,7),Rect2(671,672,4,7),Rect2(687,672,4,7)]

func night_alpha() -> float:
	return environment.night_strength()

func cloud_x(index: int,t: float) -> float:
	return fposmod(-80.0+index*290.0+t*(2.1+index*0.65),1100.0)-220.0

func bubble_position(index: int,t: float) -> Vector2:
	var age: float=fposmod(t*(0.028+index*0.001)+index*0.173,1.0)
	return Vector2(235.0+fposmod(index*83.3,485.0)+sin(age*9.0+index)*7.0,lerpf(1730.0,1015.0,age))

func burial(t: float) -> float:
	var cycle: float=fposmod(t,60.0)
	return smoothstep(24.0,29.0,cycle)*(1.0-smoothstep(40.0,45.0,cycle))

func _draw() -> void:
	if not enabled or environment==null or game==null or game.scene!="fish":return
	var scale: Vector2=environment.map_rect.size/environment.SOURCE
	draw_set_transform(environment.map_rect.position,0.0,scale)
	var t: float=environment.elapsed
	var night: float=night_alpha()
	var tint: Color=environment.scenery_tint()
	match kind:
		"moon_glow":
			if night>0.001:
				_glow(Vector2(615,325),Vector2(550,550),Color(0.65,0.77,1.0,night*0.42))
		"clouds":
			for i in 3:
				var size:=Vector2(215 if i!=1 else 280,43 if i!=1 else 65)
				draw_texture_rect(environment.clouds[i],Rect2(Vector2(cloud_x(i,t),160+i*78),size),false,Color(tint.r,tint.g,tint.b,0.6))
		"birds":
			for i in 2:
				var x: float=fposmod(t*(18.0-i*3.0)+i*195.0,1120.0)-180.0
				var p:=Vector2(x,315+i*40+sin(t*0.9+i)*6)
				var flap: float=roundf(sin(t*6.5+i)*4.0)
				draw_polyline(PackedVector2Array([p+Vector2(-8,flap),p,p+Vector2(8,flap)]),Color(0.16,0.24,0.34,0.72*(1.0-night)),2.2)
		"surface_water":_surface(t,night)
		"post_ripples":_posts(t,night)
		"underwater_light":
			# A textured quad gives the shader continuous UV coordinates.
			draw_texture_rect(environment.glow,Rect2(0,1001,803,820),false)
		"fish":_fish(t,night)
		"sand_fish":_sand(t,night)
		"plants":_plants(t,tint)
		"bubbles":
			for i in 11:
				var p:=bubble_position(i,t)
				var radius: float=1.4+float(i%3)*0.6
				draw_arc(p,radius,0,TAU,8,Color(0.67,0.89,0.96,0.22*(1.0-night*0.45)),1.1)
				draw_rect(Rect2(p+Vector2(-1,-radius),Vector2(1.3,1.3)),Color(0.9,0.98,1.0,0.29))
		"village_lights":
			if night>0.001:
				for i in LIGHT_PANES.size():
					var pane: Rect2=LIGHT_PANES[i]
					var flicker: float=0.94+0.04*sin(t*(2.5 if i<2 else 0.13)+i)+0.02*sin(t*4.1+i)
					draw_rect(pane,Color(1,0.73,0.28,night*0.84*flicker))
					_glow(pane.get_center(),Vector2(72,84) if i<2 else Vector2(22,25),Color(1,0.60,0.18,night*0.48*flicker))
		"fireflies":
			if night>0.001:
				for i in 8:
					var p:=Vector2(210+i*72+sin(t*0.31+i*1.7)*18,785+float(i%3)*57+sin(t*0.47+i*2.1)*14)
					var alpha: float=night*pow(maxf(0.0,sin(t*0.72+i*1.9)),2.0)*0.8
					_glow(p,Vector2(15,15),Color(0.92,1.0,0.52,alpha*0.7))
					draw_rect(Rect2(p.round(),Vector2(2,2)),Color(0.95,1,0.57,alpha))

func _glow(p: Vector2,size: Vector2,color: Color) -> void:
	draw_texture_rect(environment.glow,Rect2(p-size*0.5,size),false,color)

func _surface(t: float,night: float) -> void:
	# The pier occupies x<370,y<930: waves never paint across its wood.
	for i in 45:
		var y: float=730.0+fposmod(i*37.7+t*0.95,259.0)
		var x: float=390.0+fposmod(i*61.3+t*(1.8+i%3),398.0) if y<935 else 8.0+fposmod(i*61.3+t*2.0,780.0)
		var alpha: float=(0.07+0.10*pow(maxf(0,sin(t*0.8+i*2.3)),2))*(1.0-night*0.68)
		draw_rect(Rect2(roundf(x),roundf(y),9+i%5*7,2),Color(0.63,0.89,1.0,alpha))
	# Separate, gently meandering cutaway waterline; static plate has no foam.
	var points:=PackedVector2Array()
	for k in 82:
		points.append(Vector2(float(k)*10,998+sin(t*0.83+k*0.43)*1.4+sin(t*0.37+k*0.12)*0.6))
	draw_polyline(points,Color(0.65,0.95,1.0,0.34*(1.0-night*0.48)),2.0)
	# Night-only reflection lives entirely on the water, below the far shore.
	if night>0.001:
		_glow(Vector2(615,856),Vector2(130,260),Color(0.64,0.76,1.0,night*0.05))
		for i in 43:
			if sin(i*4.71+t*0.08)<-0.45:continue
			var y: float=737+i*5.9
			var span: float=(6+i*0.64)*(0.45+0.55*absf(sin(i*2.73+t*0.17)))
			var drift: float=sin(t*0.9+i*0.93)*13+sin(t*0.33+i*0.19)*9
			var a: float=night*(0.08+0.16*pow(maxf(0,sin(t*0.6+i*1.7)),2))
			draw_rect(Rect2(615+drift-span,y,span*2,1.8),Color(0.79,0.86,1,a))

func _posts(t: float,night: float) -> void:
	for post in POST_ANCHORS.size():
		var anchor: Vector2=POST_ANCHORS[post]
		for wave in 2:
			var phase: float=fposmod(t*0.32+post*0.17+wave*0.5,1.0)
			var radius: float=7+phase*25
			var a: float=sin(phase*PI)*0.40*(1.0-night*0.45)
			# Two disconnected crescent ripples, not the open-water straight strokes.
			for side in [-1.0,1.0]:
				var pts:=PackedVector2Array()
				for j in 10:
					var angle: float=0.18+float(j)/9.0*(PI-0.36)
					pts.append(anchor+Vector2(cos(angle)*radius,sin(angle)*radius*0.20*side+2.0))
				draw_polyline(pts,Color(0.68,0.89,0.96,a),1.7)

func _fish(t: float,night: float) -> void:
	for i in 3:
		var p:=Vector2(435+sin(t*(0.055+i*0.012)+i*2.1)*165,1175+i*160+sin(t*0.45+i)*12)
		var texture: Texture2D=game.fish_s3[[0,2,5][i]]
		var width: float=52+i*9
		var size:=Vector2(width,width*texture.get_height()/texture.get_width())
		var rect:=Rect2(p-size*0.5,size)
		if cos(t*(0.055+i*0.012)+i*2.1)<0:rect.position.x+=size.x;rect.size.x=-size.x
		draw_texture_rect(texture,rect,false,Color(0.60,0.77,0.84,0.48*(1.0-night*0.28)))

func _sand(t: float,night: float) -> void:
	var bury:=burial(t)
	var texture: Texture2D=game.fish_s3[3]
	var width:=61.0
	var h: float=width*texture.get_height()/texture.get_width()
	var p:=Vector2(470+sin(t*0.055)*45,1713)
	var visible_h: float=h*(1.0-bury)
	if visible_h>0.2:
		# A clipped top fraction sinks below the fixed sand plane, never just fades.
		draw_texture_rect_region(texture,Rect2(p.x-width*0.5,p.y-visible_h,width,visible_h),Rect2(0,0,texture.get_width(),texture.get_height()*(1.0-bury)),Color(0.76,0.80,0.69,0.60*(1.0-night*0.35)))
	var moving: bool=(fposmod(t,60.0)>24 and fposmod(t,60.0)<30) or (fposmod(t,60.0)>40 and fposmod(t,60.0)<46)
	if moving:
		for k in 9:
			var age: float=fposmod(t*0.7+k*0.13,1.0)
			draw_rect(Rect2(p+Vector2((k-4)*age*4,-sin(age*PI)*7),Vector2(2,1)),Color(0.91,0.75,0.37,(1-age)*0.5))
	if bury>0.5:
		draw_arc(p,12,PI*1.05,PI*1.95,12,Color(0.55,0.44,0.24,0.22),1.4)

func _plants(t: float,tint: Color) -> void:
	var roots: Array=[Vector2(117,1640),Vector2(690,1660),Vector2(261,1786),Vector2(738,1800)]
	for i in roots.size():
		for blade in 3:
			var anchor: Vector2=roots[i]+Vector2((blade-1)*6,0)
			var height: float=45+float((i*7+blade*13)%39)
			var points:=PackedVector2Array()
			for step in 9:
				var v: float=step/8.0
				var sway: float=sin(t*(0.7+i*0.07)+i*2.0+blade+v)*7*v*v
				points.append(anchor+Vector2((blade-1)*v*9+sway,-height*v))
			var color:=Color(0.30+blade*0.04,0.55+blade*0.06,0.26)*tint
			draw_polyline(points,color,3.0)
			for j in [3,5,7]:
				var p: Vector2=points[j]
				draw_line(p,p+Vector2((-1 if j%2 else 1)*8,-6),color.lightened(0.12),2.0)
