extends RefCounted
# Approved clean plate only. Future clouds/plants/water effects are not baked in here.
const SOURCE := Vector2(801,1962)
const PLATE_PATH := "res://art/bg/tile_sea_approved_20261107.png"
const DECK_Y := 887.0
const WATER_Y := 977.0
const SAND_Y := 1790.0
var root: Node2D
var plate: Sprite2D
var native := false
var native_canvas: CanvasLayer
var map_rect := Rect2()
func setup(m) -> void:
	root=Node2D.new();root.name="TileSeaBackground";root.z_index=-20
	root.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	native=is_instance_valid(m.text_layer) and m.get_viewport() is SubViewport and m.text_layer.get_viewport()!=m.get_viewport()
	if native:
		native_canvas=CanvasLayer.new();native_canvas.name="TileSeaNativeBackground";native_canvas.layer=-1
		m.text_layer.get_viewport().add_child(native_canvas);native_canvas.add_child(root)
		m.tree_exiting.connect(dispose,CONNECT_ONE_SHOT)
	else: m.add_child(root)
	plate=Sprite2D.new();plate.centered=false;plate.texture=load(PLATE_PATH)
	root.add_child(plate);root.hide()
func layout(m) -> void:
	var view: Vector2=m.get_viewport_rect().size
	var scale: float=maxf(view.x/SOURCE.x,view.y/SOURCE.y)
	map_rect=Rect2((view-SOURCE*scale)/2.0,SOURCE*scale)
	plate.position=map_rect.position;plate.scale=Vector2.ONE*scale
func set_visible(value: bool) -> void:
	if is_instance_valid(root): root.visible=value
func dispose() -> void:
	if is_instance_valid(native_canvas): native_canvas.queue_free()
