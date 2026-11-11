extends Node2D
# Native animated polygon art on the half-resolution production grid, exact 2x.
var environment:RefCounted
var outlines:Array=[]
var fill_material:ShaderMaterial
var opening_areas:Array[float]=[]
func _ready()->void:
	scale=Vector2.ONE*2
	fill_material=ShaderMaterial.new();fill_material.shader=load("res://addons/reservoir/rift_tear.gdshader")
	make_tear(PackedVector2Array([Vector2(-20,274),Vector2(30,264),Vector2(68,249),Vector2(104,238),Vector2(141,225),Vector2(175,207),Vector2(209,202),Vector2(239,180),Vector2(272,167),Vector2(304,145),Vector2(335,115),Vector2(366,94),Vector2(398,61),Vector2(433,43),Vector2(474,24),Vector2(514,7),Vector2(560,-18)]),[2,5,12,7,16,5,10,18,7,13,19,9,13,6,14,8,2])
	make_tear(PackedVector2Array([Vector2(-20,397),Vector2(26,385),Vector2(62,375),Vector2(97,359),Vector2(126,338),Vector2(155,309),Vector2(192,300),Vector2(229,297),Vector2(265,293),Vector2(301,281),Vector2(339,270),Vector2(377,261),Vector2(412,239),Vector2(447,229),Vector2(488,223),Vector2(524,213),Vector2(560,204)]),[2,7,13,6,17,8,13,20,8,12,7,17,9,13,6,10,2],40.0)
func make_tear(center:PackedVector2Array,widths:Array,shift_y:float=0)->void:
	var upper:=PackedVector2Array();var lower:=PackedVector2Array()
	for i in range(center.size()-1):
		var tangent:Vector2=(center[i+1]-center[i]).normalized()
		var normal:=Vector2(-tangent.y,tangent.x)
		var steps:int=maxi(2,ceili(center[i].distance_to(center[i+1])/6.0))
		for j in steps:
			var k:float=j/float(steps)
			var p:Vector2=center[i].lerp(center[i+1],k)+Vector2(0,shift_y)
			var width:float=lerpf(float(widths[i]),float(widths[i+1]),k)
			var rough:float=sin(i*11.7+j*7.31)*1.6
			var tooth:float=3.2 if (i*3+j)%9==0 else 0
			upper.append((p+normal*maxf(1,width+rough+tooth)).round())
			lower.append((p-normal*maxf(1,width*.76-rough*.9-tooth*.3)).round())
	var last:Vector2=center[-1]+Vector2(0,shift_y)
	upper.append(last+Vector2(0,2));lower.append(last-Vector2(0,2))
	var polygon:=upper.duplicate()
	for i in range(lower.size()-1,-1,-1):polygon.append(lower[i])
	var shape:=Polygon2D.new();shape.polygon=polygon;shape.material=fill_material;add_child(shape)
	outlines.append(polygon);opening_areas.append(absf(signed_area(polygon)))
func signed_area(p:PackedVector2Array)->float:
	var result:=0.0
	for i in p.size():result+=p[i].cross(p[(i+1)%p.size()])
	return result*.5
func sync(t:float)->void:
	if fill_material!=null:fill_material.set_shader_parameter("elapsed",t)
	queue_redraw()
func _draw()->void:
	if environment==null:return
	var strength:float=.80+.10*sin(environment.elapsed*.65)
	for polygon in outlines:
		var edge:PackedVector2Array=polygon.duplicate();edge.append(edge[0])
		draw_polyline(edge,Color(.60,.14,.98,.08*strength),15,false)
		draw_polyline(edge,Color(.85,.18,.99,.20*strength),8,false)
		draw_polyline(edge,Color(1,.42,.97,.85*strength),3.5,false)
		draw_polyline(edge,Color(.65,.98,1,.96*strength),1.6,false)
