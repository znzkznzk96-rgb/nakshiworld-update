extends Node2D
# Independent spatial night glow; no clock, randomness, input, or save ownership.
var profile:int=0
var source_size:=Vector2(1080,2640)
var strength:float=0.0
var field:ColorRect
var shader_material:ShaderMaterial
func _ready()->void:
 name="RegionalNightGlow"
 field=ColorRect.new();field.name="SoftNightGlow";field.size=source_size
 field.mouse_filter=Control.MOUSE_FILTER_IGNORE
 shader_material=ShaderMaterial.new();shader_material.shader=load("res://addons/reservoir/regional_night_glow.gdshader")
 shader_material.set_shader_parameter("profile",profile)
 field.material=shader_material;add_child(field);set_strength(strength)
func set_strength(value:float)->void:
 strength=clampf(value,0,1);visible=strength>0.00001
 if shader_material!=null:shader_material.set_shader_parameter("night_strength",strength)
