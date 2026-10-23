extends Node2D

const ART_SIZE := Vector2(841, 1870)
const EFFECT_NAMES := ["Title", "Water", "SleepingCat", "Lanterns", "Stars"]
const MOTION_SHADER = preload("res://addons/reservoir/update_motion.gdshader")
var materials: Array[ShaderMaterial] = []
var effect_nodes: Array[Sprite2D] = []
var time_override := -1.0
var elapsed := 0.0

func setup(texture: Texture2D) -> void:
	var base := Sprite2D.new()
	base.name = "OriginalB"
	base.centered = false
	base.texture = texture
	base.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(base)
	for index in EFFECT_NAMES.size():
		var layer := Sprite2D.new()
		layer.name = EFFECT_NAMES[index]
		layer.centered = false
		layer.texture = texture
		layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var shader_material := ShaderMaterial.new()
		shader_material.shader = MOTION_SHADER
		shader_material.set_shader_parameter("effect", index)
		layer.material = shader_material
		materials.append(shader_material)
		effect_nodes.append(layer)
		add_child(layer)
	fit()
	get_viewport().size_changed.connect(fit)

func fit() -> void:
	var size := get_viewport_rect().size
	var factor := maxf(size.x / ART_SIZE.x, size.y / ART_SIZE.y)
	scale = Vector2.ONE * factor
	position = (size - ART_SIZE * factor) * 0.5

func advance(delta: float) -> void:
	elapsed += delta
	var clock := time_override if time_override >= 0.0 else elapsed
	for shader_material in materials:
		shader_material.set_shader_parameter("clock", clock)

func set_effect_enabled(index: int, enabled: bool) -> void:
	effect_nodes[index].visible = enabled
