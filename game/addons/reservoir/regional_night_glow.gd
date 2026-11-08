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

func update_play(m,map_rect:Rect2)->void:
 if shader_material==null or not map_rect.has_area():return
 var pos:Vector2=m.night_play.flame(m)
 shader_material.set_shader_parameter("lantern_uv",(pos-map_rect.position)/map_rect.size)
 shader_material.set_shader_parameter("lantern_span",Vector2(22,17)/map_rect.size)
 var fighting:bool=m.S.get("phase","")=="fight"
 var fish:Vector2=m.S.get("lastF",{}).get("p",Vector2(-1000,-1000))
 shader_material.set_shader_parameter("fight_uv",(fish-map_rect.position)/map_rect.size)
 shader_material.set_shader_parameter("fighting",1.0 if fighting else 0.0)
