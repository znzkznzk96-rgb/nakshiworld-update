extends Node2D
var kind := ""
var valley
var cloud: Texture2D
var cloud_material: ShaderMaterial
func _ready() -> void:
	if kind == "drifting_clouds":
		cloud=load("res://art/atmosphere/cloud_cumulus.png")
		cloud_material=ShaderMaterial.new();cloud_material.shader=load("res://addons/reservoir/valley_clouds.gdshader")
		cloud_material.set_shader_parameter("cloud_tex",cloud);material=cloud_material
func _draw() -> void:
	if valley == null: return
	var r: Rect2=valley.map_rect
	var t: float=valley.elapsed
	var top: float=r.position.y+r.size.y*0.22
	var surface: float=r.position.y+r.size.y*0.545
	var front: float=r.position.y+r.size.y*0.565
	var center: float=r.position.x+r.size.x*0.81
	var width: float=r.size.x*0.074
	match kind:
		"drifting_clouds":
			cloud_material.set_shader_parameter("elapsed",t)
			draw_texture_rect(valley.plate.texture,r,false)
		"reverse_waterfall":
			draw_rect(Rect2(center-width/2,top,width,surface-top),Color(0.32,0.92,0.90,0.58))
			draw_rect(Rect2(center-width*0.37,top,width*0.65,surface-top),Color(0.46,0.98,0.94,0.42))
			for j in 6:
				var x: float=roundf(center-width/2+j*width/5)
				draw_line(Vector2(x,top),Vector2(x,surface),Color(0.83,1.0,0.97,0.22),1)
			for j in 32:
				var y: float=valley.waterfall_y(t,j)
				var x: float=roundf(center-width*0.42+fposmod(j*5.7,width*0.84))
				var length: float=minf(3+j%5,surface-y)
				draw_rect(Rect2(x,floorf(y),1 if j%3 else 2,length),Color(0.91,1.0,1.0,0.6 if j%3 else 0.86))
			# Thin ripples mark suction at the foot; no falling drops or spray.
			for j in 3:
				var phase: float=fposmod(t*0.4+j/3.0,1.0)
				draw_arc(Vector2(center,surface),width*(1.0-phase)+2,0,PI,20,Color(0.77,1.0,0.98,phase*0.35),1)
		"underwater_light":
			for j in 4:
				var x: float=r.position.x+r.size.x*(0.28+j*0.14)+sin(t*0.2+j)*2
				var depth: float=r.end.y-front
				draw_colored_polygon(PackedVector2Array([Vector2(x,front+1),Vector2(x+2,front+1),Vector2(x+24,front+depth*0.88),Vector2(x+13,front+depth*0.88)]),Color(0.45,0.95,0.88,0.035+sin(t*0.35+j)*0.012))
		"surface_reflection":
			for j in 21:
				var x: float=r.position.x+r.size.x*(0.44+fposmod(j*0.093+t*0.003,0.54))
				var y: float=surface+fposmod(j*2.3,front-surface+1)
				draw_rect(Rect2(floorf(x),floorf(y),3+j%5,1),Color(0.62,1.0,0.96,0.13+0.07*sin(t+j)))
