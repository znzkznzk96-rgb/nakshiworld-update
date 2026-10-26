extends RefCounted
# Static plate and independently animated layers; world clock/save format unchanged.
const DAY_LENGTH := 1200.0
const SOURCE := Vector2(803,1959)
const DECK_Y := 846.0
const WATER_Y := 998.0
const SAND_Y := 1750.0
const LAYER_ORDER := {
	"moon_glow":-29,"clouds":-27,"birds":-25,"surface_water":-22,
	"post_ripples":-21,"underwater_light":-19,"fish":-17,
	"sand_fish":-16,"plants":-14,"bubbles":-13,
	"chimney_smoke":-24,"village_lights":-12,"lamp_light":-11,"fireflies":-10
}
var valley = preload("res://addons/reservoir/valley_environment.gd").new()
var active_region := 0
var scene_visible := true
var backplate: Sprite2D
var material: ShaderMaterial
var texture: Texture2D
var elapsed := 0.0
var scenery_softness := 1.0
var day_seconds := 0.0
var bottom := 447.0
var extra := 0.0
var canvas_height := 585.0
var layer: Node2D
var front: Sprite2D
var water_layers: Array[Node2D] = []
var light_layer: Node2D
var moon: Sprite2D
var atmosphere_layers: Array[Node2D] = []
var layers: Dictionary = {}
var map_rect := Rect2()
var glow: GradientTexture2D
var clouds: Array[Texture2D] = []
var game: Node2D
var redraw_clock := 0.0

func setup(m) -> void:
	game=m;backplate=m.bg_node
	texture=load("res://art/bg/reservoir_layers/base.png")
	material=ShaderMaterial.new();material.shader=load("res://addons/reservoir/reservoir_plate.gdshader")
	backplate.z_index=-30;backplate.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	moon=Sprite2D.new();moon.name="ReservoirMoon";moon.z_index=-28
	moon.texture=load("res://art/bg/reservoir_layers/moon.png")
	moon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var moon_material:=ShaderMaterial.new();moon_material.shader=load("res://addons/reservoir/reservoir_moon.gdshader");moon.material=moon_material
	m.add_child(moon)
	front=Sprite2D.new();front.name="ReservoirTerrainOcclusion";front.centered=false;front.z_index=-26
	front.texture=texture;front.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	front.material=material.duplicate();front.material.set_shader_parameter("terrain_only",true);m.add_child(front)
	var gradient:=Gradient.new()
	gradient.offsets=PackedFloat32Array([0.0,0.25,0.6,1.0])
	gradient.colors=PackedColorArray([Color(1,1,1,0.6),Color(1,1,1,0.32),Color(1,1,1,0.07),Color(1,1,1,0)])
	glow=GradientTexture2D.new();glow.gradient=gradient;glow.width=128;glow.height=128
	glow.fill=GradientTexture2D.FILL_RADIAL;glow.fill_from=Vector2(0.5,0.5);glow.fill_to=Vector2(0.5,0)
	for name in ["cloud_wisp","cloud_cumulus","cloud_far"]:
		clouds.append(load("res://art/atmosphere/%s.png"%name))
	for kind in LAYER_ORDER:
		var node:=Node2D.new();node.name="Reservoir_"+kind
		node.set_script(load("res://addons/reservoir/reservoir_layer.gd"));node.environment=self;node.game=m;node.kind=kind
		node.z_index=LAYER_ORDER[kind];node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		if kind=="underwater_light":
			var rays:=ShaderMaterial.new();rays.shader=load("res://addons/reservoir/reservoir_rays.gdshader");node.material=rays
		m.add_child(node);layers[kind]=node
	layer=layers.fish;light_layer=layers.underwater_light
	water_layers.assign([layers.surface_water,layers.post_ripples,layers.bubbles])
	atmosphere_layers.assign([layers.clouds,layers.plants,layers.birds,layers.fireflies])
	valley.setup(m)

func layout(m) -> void:
	active_region=m.active_region;bottom=m.uw_bot;extra=m.oy;canvas_height=m.get_viewport_rect().size.y
	valley.layout(m)
	if m.get_viewport() is SubViewport: m.get_viewport().transparent_bg=active_region==1
	var view: Vector2=m.get_viewport_rect().size
	# Uniform cover; never independent X/Y stretching.
	var scale: float=maxf(view.x/SOURCE.x,view.y/SOURCE.y)
	map_rect=Rect2((view-SOURCE*scale)*0.5,SOURCE*scale)
	backplate.texture=texture;backplate.material=material;backplate.position=map_rect.position;backplate.scale=Vector2.ONE*scale
	front.position=backplate.position;front.scale=backplate.scale
	moon.position=point(Vector2(615,325));moon.scale=Vector2.ONE*(342.0*scale/moon.texture.get_width())
	show_scene(scene_visible);update(0.0)

func point(source: Vector2) -> Vector2:
	return map_rect.position+source*map_rect.size/SOURCE

func source_rect(source: Rect2) -> Rect2:
	return Rect2(point(source.position),source.size*map_rect.size/SOURCE)

func night_strength() -> float:
	var h:=hour()
	return smoothstep(17.0,20.0,h) if h>=12.0 else 1.0-smoothstep(5.0,8.0,h)

func actor_tint() -> Color:
	# The nearby lantern illuminates the rig and cat, not only the plate behind them.
	return scenery_tint().lerp(Color(1.0,0.84,0.60),night_strength()*0.86)

func scenery_tint() -> Color:
	var tint:=Color.WHITE.lerp(Color(0.28,0.36,0.59),night_strength())
	var dusk: float=smoothstep(16.0,18.5,hour())*(1.0-smoothstep(19.0,21.0,hour()))
	return tint.lerp(Color(1.02,0.72,0.64),dusk*0.25)

func update(dt: float) -> void:
	valley.update(dt);elapsed+=dt;day_seconds+=dt
	if not scene_visible or active_region!=0: return
	var night:=night_strength()
	moon.modulate=Color(1,1,1,lerpf(0.7,1.0,night))
	for mat in [material,front.material]:
		mat.set_shader_parameter("hour",hour());mat.set_shader_parameter("night",night)
	light_layer.material.set_shader_parameter("elapsed",elapsed)
	light_layer.material.set_shader_parameter("night",night)
	# Environment motion30Hz, independent of gameplay RNG/physics.
	redraw_clock+=dt
	if dt>0.0 and redraw_clock<1.0/30.0: return
	redraw_clock=0.0
	for kind in layers: layers[kind].queue_redraw()

func show_scene(is_fishing: bool) -> void:
	scene_visible=is_fishing;valley.set_visible(is_fishing and active_region==1)
	var show: bool=is_fishing and active_region==0
	if is_instance_valid(backplate):backplate.visible=show
	front.visible=show;moon.visible=show
	for kind in layers:layers[kind].visible=show

func hour() -> float:
	return fposmod(8.0+day_seconds*24.0/DAY_LENGTH,24.0)

func clock_label() -> String:
	var h:=hour();var hh:=int(h)
	return "%d일째 %s %02d:%02d"%[1+int(day_seconds/DAY_LENGTH+8.0/24.0),"AM" if hh<12 else "PM",12 if hh%12==0 else hh%12,int((h-hh)*60.0)]

func set_hour(h: float) -> void:
	day_seconds=fposmod(h-8.0,24.0)/24.0*DAY_LENGTH;update(0.0)

func dispose() -> void:
	for kind in layers:
		layers[kind].environment=null;layers[kind].game=null
	layers.clear();game=null
