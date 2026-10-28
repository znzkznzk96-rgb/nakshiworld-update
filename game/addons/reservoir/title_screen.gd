extends RefCounted

const SOURCE_RECTS: = {"boat": Rect2(215, 140, 1364, 654), "wave": Rect2(0, 241, 2172, 329), "logo": Rect2(62, 68, 1664, 779), "guardian": Rect2(12, 7, 928, 1651)}
const CYCLE: = 9.2
const STRIKES: = [3.0, 3.43, 4.02]
const POWER: = [0.22, 0.32, 1.0]
const LAYER_NAMES: = ["plate", "clouds_far", "clouds_near", "guardian", "depth_light", "bubbles_far", "waves_far", "boat", "waves_near", "bubbles_near", "rain_far", "rain_near", "lightning", "logo"]
const GUARDIAN_SHADER: = "shader_type canvas_item;\nuniform float flash = 0.0;\nuniform float front = 0.0;\nuniform float time = 0.0;\nvoid fragment(){\n vec2 uv=UV;\n uv.x+=sin(uv.y*9.0+time*.6)*.003*smoothstep(.25,1.0,uv.y);\n vec4 fish=texture(TEXTURE,uv);\n float reveal=1.0-smoothstep(front-.08,front+.14,UV.y);\n float depth=pow(1.0-smoothstep(.08,.82,UV.y),3.0);\n float intensity=clamp(flash*1.9,0.0,1.0)*reveal*depth;\n fish.rgb*=mix(vec3(.025,.045,.07),vec3(1.05,1.15,1.20),clamp(intensity*1.6,0.0,1.0));\n fish.a*=.003+intensity*.98;\n COLOR=fish;\n}"














var root: Node2D
var layers: = {}
var textures: = {}
var guardian: Sprite2D
var logo: Sprite2D
var boat: Sprite2D
var elapsed: = 0.0
var leaving: = false
var rects: = {}
var last_flash: = {}
var wave_region: = Rect2()
func setup(m) -> void :
	for name in ["plate", "guardian", "boat", "logo", "wave"]: textures[name] = load("res://art/title55/%s.png" % name)
	wave_region = SOURCE_RECTS.wave
	textures["storm_cloud"] = load("res://art/atmosphere/cloud_cumulus.png")
	textures["storm_wisp"] = load("res://art/atmosphere/cloud_wisp.png")
	root = Node2D.new();root.name = "LayeredTitle";root.z_index = 40;root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST;m.add_child(root)
	for name in LAYER_NAMES:
		var layer: Node2D
		if name in ["guardian", "boat", "logo"]:
			var sprite: = Sprite2D.new();sprite.texture = textures[name]
			if name != "plate":
				sprite.region_enabled = true;sprite.region_rect = SOURCE_RECTS[name]
			layer = sprite
			if name == "guardian":
				guardian = sprite
				var shader: = Shader.new();shader.code = GUARDIAN_SHADER
				var material: = ShaderMaterial.new();material.shader = shader;guardian.material = material
			elif name == "boat": boat = sprite
			else: logo = sprite
		else:
			layer = Node2D.new();layer.set_script(preload("res://addons/reservoir/title_layer.gd"));layer.screen = self;layer.game = m;layer.kind = name
		layer.name = name
		if name in ["waves_far", "waves_near"]: layer.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		root.add_child(layer);layers[name] = layer
	root.visible = m.title_open or leaving
	update(m, 0)
func dispose() -> void :
	for name in layers:
		var node: Node2D = layers[name]
		if node.get_script() == preload("res://addons/reservoir/title_layer.gd"): node.screen = null;node.game = null
func flash_at(time: float) -> Dictionary:
	var phase: float = fposmod(time, CYCLE)
	var result: Dictionary = {"pulse": 0.0, "glow": 0.0, "reveal": 0.0, "front": 0.0, "age": 100.0, "event": -1, "cycle": floori(time / CYCLE)}
	for i in 3:
		var age: float = phase - STRIKES[i]
		if age < 0 or age > 2.2: continue
		var pulse: float = POWER[i] * exp( - age / (0.075 if i < 2 else 0.14))
		var glow: float = POWER[i] * exp( - age / (0.21 if i < 2 else 0.5))
		var reveal: float = POWER[i] * (1 - exp( - age * 35)) * exp( - age / (0.28 if i < 2 else 0.85))
		if pulse > result.pulse: result.pulse = pulse;result.event = i
		if glow > result.glow: result.glow = glow
		if reveal > result.reveal: result.reveal = reveal;result.front = clampf((age - 0.015) / 0.52, 0, 1)
		result.age = minf(result.age, age)
	return result
func wave_y(x: float, time: float, near: bool = false) -> float:
	var speed: float = 2.55 if near else 1.9
	return sin(x * 0.043 + time * speed) * (11.5 if near else 9.5) + sin(x * 0.091 - time * 3.35) * 3.6
func wave_slope(x: float, time: float) -> float:
	return (wave_y(x + 2, time, true) - wave_y(x - 2, time, true)) / 4
func logo_pose(time: float) -> Vector2:
	var intro: float = clampf(time / 1.2, 0, 1)
	var scale: float = 1.0 + 0.72 * pow(1 - intro, 3)
	var angle: = 0.0
	if time > 1.25:
		var cycle: float = fposmod(time - 1.25, 5.0)
		if cycle < 1.6: angle = sin(cycle * 9) * 0.025 * sin(cycle / 1.6 * PI)
	return Vector2(scale, angle)
func button_alpha(time: float) -> float: return smoothstep(1.5, 3.0, time)
func update(m, dt: float) -> void :
	elapsed += dt
	if not is_instance_valid(root): return
	root.visible = m.title_open or leaving
	if not root.visible: return
	var h: float = m.get_viewport_rect().size.y; var water: float = h * 0.36
	last_flash = flash_at(elapsed)
	var used: Vector2 = guardian.region_rect.size
	guardian.scale = Vector2.ONE * (330.0 / used.x)
	guardian.position = Vector2(139 + sin(elapsed * 0.24) * 1.7, water + 12 + guardian.region_rect.size.y * guardian.scale.y / 2)
	guardian.material.set_shader_parameter("flash", last_flash.reveal)
	guardian.material.set_shader_parameter("front", last_flash.front)
	guardian.material.set_shader_parameter("time", elapsed)
	boat.scale = Vector2.ONE * (76.0 / boat.region_rect.size.x)
	var bx: float = 135 + sin(elapsed * 0.8) * 4.0
	boat.position = Vector2(bx, water + 6 + wave_y(bx, elapsed, true) - boat.region_rect.size.y * boat.scale.y * 0.38)
	boat.rotation = clampf(atan(wave_slope(bx, elapsed)), - 0.24, 0.24)
	boat.modulate = Color.WHITE.lerp(Color(1.2, 1.25, 1.35), last_flash.glow)
	var pose: = logo_pose(elapsed)
	logo.scale = Vector2.ONE * (234.0 / logo.region_rect.size.x) * pose.x
	logo.position = Vector2(135, maxf(m.top_y + 66, h * 0.155))
	logo.rotation = pose.y
	logo.modulate = Color(1, 1, 1, smoothstep(0, 0.4, elapsed))
	for name in layers: layers[name].queue_redraw()
func press(m, p: Vector2) -> void :
	if button_alpha(elapsed) < 0.95: return
	if rects.get("start", Rect2()).grow(4).has_point(p):
		m.title_open = false;m.holding = false;m.play("ui", -6)
		leaving = m.scene != "village"
		if leaving: m.start_trans("village")
		else: root.hide()
func _rain(n: Node2D, h: float, near: bool) -> void :
	var count: int = 52 if near else 82
	var water: float = h * 0.36
	for i in count:
		var depth: float = 0.65 + fposmod(i * 0.618, 1) * 0.35
		var yy: float = fposmod(i * 31.7 + elapsed * (108 if near else 66) * depth, water + 23) - 15
		var xx: float = fposmod(i * 47.3 - elapsed * (39 if near else 24), 304) - 18
		var len: float = (9 if near else 5) * depth
		var col: = Color(0.63, 0.79, 0.88, (0.26 if near else 0.14) + float(last_flash.glow) * 0.1)
		n.draw_line(Vector2(roundf(xx), roundf(yy)), Vector2(roundf(xx - 2), roundf(yy + len)), col, 1)

	for i in 14:
		var age: float = fposmod(elapsed * 1.9 + i * 0.31, 1)
		var x: float = fposmod(i * 53.2 + 17, 270)
		var y: float = water + wave_y(x, elapsed, near) + i % 3 * 3
		n.draw_line(Vector2(x - age * 4, y), Vector2(x + age * 4, y), Color(0.65, 0.83, 0.9, (1 - age) * 0.18), 1)
func _waves(n: Node2D, h: float, near: bool) -> void :
	var water: float = h * 0.36 + (6 if near else -6)
	var tx: Texture2D = textures.wave
	var size: Vector2 = tx.get_size()
	var shift: float = elapsed * (19 if near else -10)
	var v0: float = wave_region.position.y / size.y
	var v1: float = wave_region.end.y / size.y
	var tint: = Color(0.88, 0.97, 1, 1) if near else Color(0.37, 0.65, 0.78, 1)
	tint = tint.lerp(Color(1.2, 1.3, 1.4), float(last_flash.glow) * 0.45)
	var colors: = PackedColorArray([tint, tint, tint, tint])
	for x in range(-12, 285, 3):
		var y0: float = roundf(water + wave_y(x, elapsed, near))
		var y1: float = roundf(water + wave_y(x + 3, elapsed, near))
		var height: float = 22 if near else 25
		var points: = PackedVector2Array([Vector2(x, y0), Vector2(x + 3, y1), Vector2(x + 3, y1 + height), Vector2(x, y0 + height)])
		var u0: float = (x + shift) / 320.0; var u1: float = (x + 3 + shift) / 320.0
		n.draw_polygon(points, colors, PackedVector2Array([Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1)]), tx)
func _clouds(n: Node2D, h: float, near: bool) -> void :
	var tint: = Color(0.12, 0.17, 0.29, 0.94) if near else Color(0.19, 0.25, 0.38, 0.85)
	tint = tint.lerp(Color(0.64, 0.74, 0.9, 0.95), float(last_flash.glow) * (0.48 if near else 0.68))
	var texture: Texture2D = textures.storm_cloud if near else textures.storm_wisp
	for i in 7:
		var x: float = fposmod(i * 93.0 + elapsed * (3.5 if near else 1.4), 490) - 180
		var y: float = -9 + i % 4 * minf(28, h * 0.04) + (14 if near else 0)
		n.draw_texture(texture, Vector2(roundf(x), roundf(y)), tint)
func _bubbles(n: Node2D, h: float, near: bool) -> void :
	var water: float = h * 0.36 + 27
	var area: float = h - water - 18
	for i in (13 if near else 22):
		var y: float = water + fposmod(i * 31.4 - elapsed * (10 if near else 5.2), area)
		var x: float = fposmod(i * 69.4 + sin(elapsed * 0.8 + i) * 3, 258) + 6
		var radius: float = (1.5 if near else 0.8) + i % 3 * 0.3
		var alpha: float = (0.19 if near else 0.09) + float(last_flash.glow) * 0.08
		n.draw_arc(Vector2(roundf(x), roundf(y)), radius, 0, TAU, 8, Color(0.4, 0.78, 0.88, alpha), 1)
		if near: n.draw_rect(Rect2(roundf(x) - 1, roundf(y) - radius, 1, 1), Color(0.75, 0.94, 1, alpha))
func _lightning(n: Node2D, h: float) -> void :
	var pulse: float = last_flash.pulse
	if pulse < 0.035: return
	var index: int = maxi(0, int(last_flash.event)); var cycle: int = last_flash.cycle
	var origin: float = 185 + fposmod(cycle * 41 + index * 23, 64)
	var length: float = h * (0.29 if index == 2 else 0.19)
	var points: = PackedVector2Array()
	for k in 12: points.append(Vector2(roundf(origin + sin(k * 2.7 + index) * 8 - k * 2.1), roundf(k * length / 11)))
	n.draw_polyline(points, Color(0.35, 0.65, 1, pulse * 0.28), 5)
	n.draw_polyline(points, Color(0.7, 0.85, 1, pulse * 0.75), 2)
	n.draw_polyline(points, Color(1, 1, 1, pulse), 1)
	for branch in [4, 7]:
		var c: Vector2 = points[branch]
		n.draw_polyline(PackedVector2Array([c, c + Vector2(12, 8), c + Vector2(5, 16), c + Vector2(20, 26)]), Color(0.68, 0.84, 1, pulse * 0.7), 1)
	n.draw_rect(Rect2(0, 0, 270, h * 0.36), Color(0.65, 0.8, 1, pulse * 0.095))
func paint(kind: String, n: Node2D, m) -> void :
	var h: float = m.get_viewport_rect().size.y; var water: float = h * 0.36
	match kind:
		"plate":
			n.draw_rect(Rect2( - m.ox, 0, 270 + m.ox * 2, h), Color("020914"))
			var tx: Texture2D = textures.plate; var size: Vector2 = tx.get_size(); var split: float = roundf(size.y * 0.275)
			n.draw_texture_rect_region(tx, Rect2(0, 0, 270, water), Rect2(0, 0, size.x, split))
			n.draw_texture_rect_region(tx, Rect2(0, water, 270, h - water), Rect2(0, split, size.x, size.y - split))
		"clouds_far": _clouds(n, h, false)
		"clouds_near": _clouds(n, h, true)
		"waves_far": _waves(n, h, false)
		"waves_near": _waves(n, h, true)
		"rain_far": _rain(n, h, false)
		"rain_near": _rain(n, h, true)
		"bubbles_far": _bubbles(n, h, false)
		"bubbles_near": _bubbles(n, h, true)
		"lightning": _lightning(n, h)
		"depth_light":
			var glow: float = last_flash.glow
			if glow > 0.004:
				for i in 17:
					var x: float = 173 + sin(i * 3 + elapsed * 4) * 8
					var y: float = water + i * 2
					n.draw_rect(Rect2(x, y, 32 - i, 1), Color(0.7, 0.92, 1, glow * (1 - i / 17.0) * 0.48))
func draw_ui(m, h: float) -> void :
	var alpha: float = button_alpha(elapsed)
	var button: = Rect2(49, h - m.bot_pad - 107, 172, 34)
	rects.start = button
	if alpha > 0:
		var style: StyleBoxTexture = m.sb_primary.duplicate()
		style.modulate_color = Color(1, 1, 1, alpha)
		m._ui_style_box(style, button)
		var begin: int = m.text_items.size()
		m._text("게임 시작", button.get_center() + Vector2(0, 5), 14, Color(1, 0.96, 0.84, alpha), true, 150, true)
		m._text("화면 속 작은 배에서, 거대한 모험으로", Vector2(135, button.end.y + 20), 9, Color(0.72, 0.84, 0.85, alpha * 0.8), true, 244)
		var blur: float = (1 - alpha) * 1.8
		if blur > 0.05:
			var source: Array = m.text_items.slice(begin)
			for item in source:
				for offset in [Vector2( - blur, 0), Vector2(blur, 0)]:
					var copy: Array = item.duplicate();copy[1] += offset;copy[6].a *= 0.15;m.text_items.append(copy)
	m._text("v" + m._ver_name(), Vector2(135, h - m.bot_pad - 40), 8, Color(0.56, 0.7, 0.74, 0.7), true, 200)
