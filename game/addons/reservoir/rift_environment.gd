extends RefCounted
const SOURCE:=Vector2(1080,2640)
const DECK_Y:=1194.0
const WATER_Y:=1314.0
const SAND_Y:=2420.0
const BOB_AMPLITUDE:=1.5
const BOB_PERIOD:=4.2
var root:Node2D
var plate:Sprite2D
var boat:Sprite2D
var glow:Sprite2D
var light:Node2D
var native_canvas:CanvasLayer
var map_rect:=Rect2()
var elapsed:=0.0
var redraw_clock:=0.0
var layers:Dictionary={}
var game:Node2D
func setup(m)->void:
	game=m
	root=Node2D.new();root.name="RiftBackground";root.z_index=-20;root.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var native:bool=is_instance_valid(m.text_layer) and m.get_viewport() is SubViewport and m.text_layer.get_viewport()!=m.get_viewport()
	if native:
		native_canvas=CanvasLayer.new();native_canvas.name="RiftNativeBackground";native_canvas.layer=-1
		m.text_layer.get_viewport().add_child(native_canvas);native_canvas.add_child(root)
		m.tree_exiting.connect(dispose,CONNECT_ONE_SHOT)
	else:m.add_child(root)
	plate=Sprite2D.new();plate.centered=false;plate.texture=load("res://art/rift/base.png");root.add_child(plate)
	glow=Sprite2D.new();glow.centered=false;glow.texture=load("res://art/rift/glow_mask.png")
	var material:=ShaderMaterial.new();material.shader=load("res://addons/reservoir/rift_glow.gdshader");glow.material=material;plate.add_child(glow)
	for kind in ["sky","clouds","reflection","cliffs"]:add_scenery(kind)
	for kind in ["rocks","surface"]:add_layer(kind)
	boat=Sprite2D.new();boat.name="RiftBoat";boat.centered=false;boat.texture=load("res://art/rift/boat.png");plate.add_child(boat)
	var water_material:=ShaderMaterial.new();water_material.shader=load("res://addons/reservoir/rift_boat_water.gdshader");boat.material=water_material
	add_layer("foam")
	light=load("res://addons/reservoir/vertical_water_light.gd").new();light.source_rect=Rect2(0,WATER_Y,1080,1100);light.seed_offset=617.0;plate.add_child(light)
	root.hide()
func add_scenery(kind:String)->void:
	var n=load("res://addons/reservoir/rift_scenery.gd").new();n.name="Rift_scenery_"+kind;n.environment=self;n.kind=kind;plate.add_child(n);layers["scenery_"+kind]=n
func add_layer(kind:String)->void:
	var n=load("res://addons/reservoir/rift_layer.gd").new();n.name="Rift_"+kind;n.environment=self;n.kind=kind;plate.add_child(n);layers[kind]=n
func bob_offset()->float:return BOB_AMPLITUDE*sin(elapsed*TAU/BOB_PERIOD)
func layout(m)->void:
	var view:Vector2=m.get_viewport_rect().size
	var scale:float=maxf(view.x/SOURCE.x,view.y/SOURCE.y)
	map_rect=Rect2((view-SOURCE*scale)/2,SOURCE*scale)
	plate.position=map_rect.position;plate.scale=Vector2.ONE*scale
	update(0)
func update(dt:float)->void:
	if is_instance_valid(game):elapsed=game.clock
	if not is_instance_valid(boat):return
	var scale:float=maxf(.001,map_rect.size.x/SOURCE.x)
	boat.position=Vector2(0,DECK_Y-306+bob_offset()/scale)
	boat.material.set_shader_parameter("waterline",(WATER_Y-boat.position.y)/450.0)
	glow.material.set_shader_parameter("elapsed",elapsed)
	light.update_light(elapsed,12)
	if light.shader_material!=null:
		light.shader_material.set_shader_parameter("light_tint",Color(.73,.45,1))
		light.shader_material.set_shader_parameter("light_intensity",.40)
	redraw_clock+=dt
	if dt>0 and redraw_clock<1.0/30:return
	redraw_clock=0
	for n in layers.values():n.queue_redraw()
func set_visible(value:bool)->void:
	if is_instance_valid(root):root.visible=value
func dispose()->void:
	for n in layers.values():n.environment=null
	game=null
	if is_instance_valid(native_canvas):native_canvas.queue_free()
