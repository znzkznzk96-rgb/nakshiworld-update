extends RefCounted
# Selected plate is immutable; atmosphere and upward water are separate nodes.
var root: Node2D
var plate: Sprite2D
var layers: Dictionary = {}
var elapsed := 0.0
var map_rect := Rect2()
var native := false
var native_canvas: CanvasLayer
var night_glow:Node2D
func setup(m) -> void:
	root = Node2D.new();root.name = "ValleyLayers";root.z_index = -20
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Render scenery at output resolution, behind the transparent game viewport.
	# CanvasLayer order (not a negative z inside the UI canvas) prevents occlusion.
	native = is_instance_valid(m.text_layer) and m.get_viewport() is SubViewport and m.text_layer.get_viewport() != m.get_viewport()
	if native:
		native_canvas = CanvasLayer.new()
		native_canvas.name = "ValleyNativeBackground"
		native_canvas.layer = -1
		m.text_layer.get_viewport().add_child(native_canvas)
		native_canvas.add_child(root)
		m.tree_exiting.connect(dispose, CONNECT_ONE_SHOT)
	else:
		m.add_child(root)
	plate = Sprite2D.new();plate.centered=false;plate.texture=load("res://art/bg/valley_selected_1080x2640.png")
	root.add_child(plate);layers.plate=plate
	var tone:=ShaderMaterial.new();tone.shader=load("res://addons/reservoir/valley_moon_tone.gdshader");plate.material=tone
	for kind in ["drifting_clouds","reverse_waterfall","surface_reflection"]:
		var layer := Node2D.new()
		layer.set_script(load("res://addons/reservoir/valley_layer.gd"));layer.kind=kind;layer.valley=self
		root.add_child(layer);layers[kind]=layer
	var light=load("res://addons/reservoir/vertical_water_light.gd").new()
	light.name="ValleyVerticalWaterLight"
	light.source_rect=Rect2(0,1492,1080,1009)
	plate.add_child(light);layers.underwater_light=light
	var life := Node2D.new()
	life.set_script(load("res://addons/reservoir/valley_life.gd"));life.valley=self
	root.add_child(life);layers.life=life
	night_glow=load("res://addons/reservoir/regional_night_glow.gd").new()
	night_glow.profile=0;night_glow.source_size=Vector2(1080,2640);plate.add_child(night_glow)
	root.hide()
func layout(m) -> void:
	var view: Vector2 = m.get_viewport_rect().size
	var scale: float = maxf(view.x/1080.0,view.y/2640.0)
	map_rect=Rect2((view-Vector2(1080,2640)*scale)/2.0,Vector2(1080,2640)*scale)
	plate.position=map_rect.position;plate.scale=Vector2.ONE*scale
	for kind in layers:
		if kind != "plate": layers[kind].queue_redraw()
func update(dt: float) -> void:
	elapsed += dt
	if not is_instance_valid(root) or not root.visible: return
	for kind in layers:
		if kind != "plate": layers[kind].queue_redraw()
func update_atmosphere(night:float) -> void:
	plate.material.set_shader_parameter("night_strength",night)
	night_glow.set_strength(night)
	var tint:=Color.WHITE.lerp(Color(0.42,0.59,0.88),night)
	for kind in ["reverse_waterfall","surface_reflection","life"]:
		layers[kind].modulate=tint
	var cloud:Node2D=layers.drifting_clouds
	if cloud.material!=null:cloud.material.set_shader_parameter("atmosphere_tint",tint)
func set_visible(value: bool) -> void:
	if is_instance_valid(root): root.visible=value
func waterfall_y(time: float, index: int) -> float:
	var top: float=map_rect.position.y+map_rect.size.y*0.22
	var base: float=map_rect.position.y+map_rect.size.y*0.545
	return base-fposmod(time*28.0+index*17.1,base-top)
func dispose() -> void:
	for kind in layers:
		if kind not in ["plate","underwater_light"] and is_instance_valid(layers[kind]): layers[kind].valley=null
	if is_instance_valid(native_canvas): native_canvas.queue_free()
	layers.clear()
