extends RefCounted

var valley = preload("res://addons/reservoir/valley_environment.gd").new()
var active_region := 0
var scene_visible := true
var backplate: Sprite2D
var material: ShaderMaterial
var texture: Texture2D
var elapsed: = 0.0
var scenery_softness: = 1.0
var day_seconds: = 0.0
var bottom: = 447.0
var extra: = 0.0
var canvas_height: = 585.0
var layer: Node2D
var front: Sprite2D
var water_layers: Array[Node2D] = []
var light_layer: Node2D
var moon: Sprite2D
var atmosphere_layers: Array[Node2D] = []
const DAY_LENGTH: = 1200.0

func setup(m) -> void :
	backplate = m.bg_node
	texture = load("res://art/bg/reservoir_outlined_base.png")
	moon = Sprite2D.new()
	moon.texture = load("res://art/bg/moon_round.png")
	moon.z_index = -8
	moon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	m.add_child(moon)
	material = ShaderMaterial.new()
	material.shader = load("res://addons/reservoir/reservoir.gdshader")
	layer = Node2D.new()
	layer.set_script(load("res://addons/reservoir/decorative_layer.gd"))
	layer.environment = self;layer.game = m;layer.z_index = -2
	m.add_child(layer)
	front = Sprite2D.new();front.centered = false;front.z_index = -1
	front.texture = texture
	front.material = material.duplicate()
	front.material.set_shader_parameter("foreground", true)
	m.add_child(front)
	light_layer = Node2D.new()
	light_layer.set_script(load("res://addons/reservoir/light_layer.gd"))
	light_layer.environment = self;light_layer.game = m;light_layer.z_index = -5
	m.add_child(light_layer)
	for near in [false, true]:
		var water: = Node2D.new()
		water.set_script(load("res://addons/reservoir/water_layer.gd"))
		water.environment = self;water.game = m;water.foreground = near
		water.z_index = 1 if near else -4
		m.add_child(water);water_layers.append(water)
	for vegetation in [false, true]:
		var animated: = Node2D.new()
		animated.set_script(load("res://addons/reservoir/atmosphere.gd"))
		animated.environment = self;animated.game = m;animated.plants = vegetation
		animated.z_index = -1 if vegetation else -9
		m.add_child(animated);animated.setup();atmosphere_layers.append(animated)

	valley.setup(m)

func layout(m) -> void :
	active_region = m.active_region
	bottom = m.uw_bot;extra = m.oy;canvas_height = m.get_viewport_rect().size.y
	valley.layout(m)
	if m.get_viewport() is SubViewport: m.get_viewport().transparent_bg = active_region == 1
	if active_region == 1:
		m.bg_node.hide();show_scene(scene_visible);return
	m.bg_node.visible = scene_visible
	show_scene(scene_visible)
	var w: float = 270.0 + 2.0 * m.ox + 4.0
	m.bg_node.texture = texture
	m.bg_node.material = material
	m.bg_node.position = Vector2( - m.ox - 2.0, 0)
	m.bg_node.scale = Vector2(w / 941.0, canvas_height / 1671.0)
	material.set_shader_parameter("canvas_width", w)
	material.set_shader_parameter("canvas_height", canvas_height)
	material.set_shader_parameter("side", m.ox + 2.0)
	material.set_shader_parameter("sky_extra", extra)
	material.set_shader_parameter("bottom", bottom)
	front.position = m.bg_node.position;front.scale = m.bg_node.scale
	for key in ["canvas_width", "canvas_height", "side", "sky_extra", "bottom"]:
		front.material.set_shader_parameter(key, material.get_shader_parameter(key))

	moon.scale = Vector2.ONE
	moon.position = Vector2(231, roundf(maxf(m.top_y + 86.0, (235.0 + extra) * 215.0 / 610.0)))
	update(0.0)

func update(dt: float) -> void :
	valley.update(dt)
	elapsed += dt
	day_seconds += dt
	var night: = clampf((absf(hour() - 12.0) - 5.0) / 5.0, 0.0, 1.0)
	moon.modulate = Color(1, 1, 1, lerpf(0.62, 0.95, night))
	material.set_shader_parameter("hour", hour())
	material.set_shader_parameter("elapsed", elapsed)
	material.set_shader_parameter("scenery_softness", scenery_softness)
	if front:
		front.material.set_shader_parameter("hour", hour())
		front.material.set_shader_parameter("elapsed", elapsed)
		front.material.set_shader_parameter("scenery_softness", scenery_softness)
	if layer: layer.queue_redraw()
	for water in water_layers: water.queue_redraw()
	if light_layer: light_layer.queue_redraw()
	for animated in atmosphere_layers: animated.queue_redraw()

func show_scene(is_fishing: bool) -> void :
	scene_visible = is_fishing
	valley.set_visible(is_fishing and active_region == 1)
	is_fishing = is_fishing and active_region == 0
	if is_instance_valid(backplate): backplate.visible = is_fishing
	layer.visible = is_fishing
	front.visible = is_fishing
	for water in water_layers: water.visible = is_fishing
	light_layer.visible = is_fishing
	moon.visible = is_fishing
	for animated in atmosphere_layers: animated.visible = is_fishing

func hour() -> float:
	return fposmod(8.0 + day_seconds * 24.0 / DAY_LENGTH, 24.0)

func clock_label() -> String:
	var h: = hour()
	var hh: = int(h)
	return "%d일째 %s %02d:%02d" % [1 + int((day_seconds / DAY_LENGTH) + 8.0 / 24.0), "AM" if hh < 12 else "PM", 12 if hh % 12 == 0 else hh % 12, int((h - hh) * 60.0)]

func set_hour(h: float) -> void :
	day_seconds = fposmod(h - 8.0, 24.0) / 24.0 * DAY_LENGTH
	update(0)

func ambience(m) -> void :
	var t: = elapsed
	var daylight: = 1.0 - clampf((absf(hour() - 12.0) - 5.0) / 5.0, 0.0, 1.0)

	if daylight > 0.2:
		for i in 2:
			var x: = fposmod(t * 6.0 + i * 28.0, 470.0) - 100.0
			var y: = 82.0 + i * 4.0 + sin(t * 0.17 + i) * 3.0
			var flap: = roundf(sin(t * 4.0 + i) * 2.0)
			m.draw_polyline(PackedVector2Array([Vector2(x - 2, y + flap), Vector2(x, y), Vector2(x + 2, y + flap)]), Color(0.12, 0.23, 0.33, daylight * 0.5), 1.0)

	for i in 16:
		var x: = 14.0 + fposmod(i * 43.7 + sin(t * 0.13 + i) * 6.0, 240.0)
		var y: = 285.0 + fposmod(i * 17.3 - t * (0.6 + i * 0.025), maxf(10.0, bottom - 295.0))
		m.draw_rect(Rect2(roundf(x), roundf(y), 1, 1), Color(0.72, 0.86, 0.87, 0.12 + daylight * 0.12))

func decorative_fish(m, painter: Node2D) -> void :

	for i in 4:
		var cycle: = fposmod(elapsed + i * 18.0, 68.0)
		var bury: = smoothstep(43.0, 46.0, cycle) * (1.0 - smoothstep(54.0, 58.0, cycle)) if i == 3 else 0.0
		var x: = 112.0 + (sin(elapsed * (0.045 + i * 0.009) + i * 1.9) + 1.0) * 64.0
		var y: = lerpf(300.0, bottom - 34.0, float(i) / 3.0) + sin(elapsed * 0.7 + i) * 2.0
		if i == 3:
			x = 178.0 + sin(elapsed * 0.06) * 43.0
			y = bottom - 8.0 + bury * 9.0
		var tx: Texture2D = m.fish_s3[[0, 2, 5, 3][i]]
		var sz: = tx.get_size()
		var alpha: = 0.42
		var face: = cos(elapsed * (0.045 + i * 0.009) + i * 1.9)
		var r: = Rect2(Vector2(roundf(x - sz.x * 0.5), roundf(y - sz.y * 0.5)), sz)
		if face < 0: r.position.x += sz.x;r.size.x = - sz.x
		if i == 3:

			var visible_height: = clampf(bottom - 3.0 - r.position.y, 0.0, sz.y)
			if visible_height > 0.0:
				var clipped: = Rect2(r.position, Vector2(r.size.x, visible_height))
				painter.draw_texture_rect_region(tx, clipped, Rect2(Vector2.ZERO, Vector2(sz.x, visible_height)), Color(0.72, 0.84, 0.86, alpha))
		else:
			painter.draw_texture_rect(tx, r, false, Color(0.72, 0.84, 0.86, alpha))
		if i == 3 and ((cycle > 43.0 and cycle < 47.5) or (cycle > 54.0 and cycle < 59.0)):
			for k in 6:
				var age: = fposmod(elapsed * 0.7 + k * 0.16, 1.0)
				painter.draw_rect(Rect2(roundf(x + (k - 2.5) * age * 4), roundf(bottom - 3.0 - age * 7), 1, 1), Color(0.8, 0.69, 0.39, 0.4 * (1.0 - age)))
