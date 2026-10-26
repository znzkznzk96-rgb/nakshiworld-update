extends RefCounted
# Selected plate is immutable; atmosphere and upward water are separate nodes.
var root: Node2D
var plate: Sprite2D
var layers: Dictionary = {}
var elapsed := 0.0
var map_rect := Rect2()
var native := false
func setup(m) -> void:
	root = Node2D.new();root.name = "ValleyLayers";root.z_index = -20
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	native = is_instance_valid(m.text_layer)
	if native: m.text_layer.get_parent().add_child(root)
	else: m.add_child(root)
	plate = Sprite2D.new();plate.centered=false;plate.texture=load("res://art/bg/valley_selected_1080x2640.png")
	root.add_child(plate);layers.plate=plate
	for kind in ["drifting_clouds","reverse_waterfall","underwater_light","surface_reflection"]:
		var layer := Node2D.new()
		layer.set_script(load("res://addons/reservoir/valley_layer.gd"));layer.kind=kind;layer.valley=self
		root.add_child(layer);layers[kind]=layer
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
func set_visible(value: bool) -> void:
	if is_instance_valid(root): root.visible=value
func waterfall_y(time: float, index: int) -> float:
	var top: float=map_rect.position.y+map_rect.size.y*0.22
	var base: float=map_rect.position.y+map_rect.size.y*0.545
	return base-fposmod(time*28.0+index*17.1,base-top)
func dispose() -> void:
	for kind in layers:
		if kind != "plate" and is_instance_valid(layers[kind]): layers[kind].valley=null
	if native and is_instance_valid(root): root.queue_free()
	layers.clear()
