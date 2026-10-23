extends Node2D
var rig=preload("res://review_aura/rig_review.gd").new()
var environment=preload("res://addons/reservoir/environment.gd").new()
var S: Dictionary={"phase":"idle","t":0.0,"tension":65.0,"netEnd":2.4}
var equipment: Dictionary={"rod_equipped":true}
var preview_enhancement: int=0
var active_region: int=0
var rod_lv: int=5
var clock: float=0
var cat_t: float=0
var fclock: float=0
var holding: bool=false
var result_t: float=0
var PX: float=50
var SURF: float=180
var CATX: float=29
var oy: float=0
var plate: Sprite2D
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	plate=Sprite2D.new();plate.centered=false;plate.z_index=-1
	plate.texture=load("res://art/bg/reservoir_layers/base.png");plate.scale=Vector2.ONE*(270.0/803.0);plate.position=Vector2(0,180-846*(270.0/803.0))
	var mat:=ShaderMaterial.new();mat.shader=load("res://addons/reservoir/reservoir_plate.gdshader");plate.material=mat;add_child(plate)
func pose(time: float,action: String,local: float,night: bool) -> void:
	clock=time;cat_t=time;fclock=local;S.phase=action;S.t=local;S.tension=70+sin(local*3)*16;holding=fposmod(local,1.8)<.9
	environment.day_seconds=(14.0 if night else 2.0)/24*1200
	plate.material.set_shader_parameter("hour",22.0 if night else 10.0);plate.material.set_shader_parameter("night",1.0 if night else 0.0)
	queue_redraw()
func _draw() -> void:rig.draw(self)
