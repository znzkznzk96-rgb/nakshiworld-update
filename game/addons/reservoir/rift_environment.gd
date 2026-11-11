extends RefCounted
# Clean static plate; boat/cloud/light layers intentionally not fabricated.
const SOURCE:=Vector2(1080,2640)
const DECK_Y:=1194.0
const WATER_Y:=1314.0
const SAND_Y:=2420.0
var root:Node2D
var plate:Sprite2D
var native_canvas:CanvasLayer
var map_rect:=Rect2()
func setup(m)->void:
	root=Node2D.new();root.name="RiftBackground";root.z_index=-20;root.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var native:bool=is_instance_valid(m.text_layer) and m.get_viewport() is SubViewport and m.text_layer.get_viewport()!=m.get_viewport()
	if native:
		native_canvas=CanvasLayer.new();native_canvas.name="RiftNativeBackground";native_canvas.layer=-1
		m.text_layer.get_viewport().add_child(native_canvas);native_canvas.add_child(root)
		m.tree_exiting.connect(dispose,CONNECT_ONE_SHOT)
	else:m.add_child(root)
	plate=Sprite2D.new();plate.centered=false;plate.texture=load("res://art/rift/base.png");root.add_child(plate);root.hide()
func layout(m)->void:
	var view:Vector2=m.get_viewport_rect().size
	var scale:float=maxf(view.x/SOURCE.x,view.y/SOURCE.y)
	map_rect=Rect2((view-SOURCE*scale)/2,SOURCE*scale)
	plate.position=map_rect.position;plate.scale=Vector2.ONE*scale
func set_visible(value:bool)->void:
	if is_instance_valid(root):root.visible=value
func dispose()->void:
	if is_instance_valid(native_canvas):native_canvas.queue_free()
