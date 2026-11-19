extends Node2D

signal finished(grade: String)

@export_enum("D", "C", "B", "A", "S", "SS", "SSS") var grade: String = "SSS"
@export var reduced_flashes := false
@export var reduced_motion := false

const VIEW := Vector2(270, 480)
const WATER := 270.0
const PROFILES := {
	"D": [Color("#b7ccd6"), 0.32, 0.34, 1.00, 5],
	"C": [Color("#70dfc4"), 0.40, 0.40, 1.02, 8],
	"B": [Color("#76baff"), 0.50, 0.43, 1.04, 14],
	"A": [Color("#c29dff"), 0.58, 0.46, 1.06, 18],
	"S": [Color("#ffb967"), 0.68, 0.50, 1.08, 24],
	"SS": [Color("#e4f5ff"), 0.83, 0.54, 1.11, 33],
	"SSS": [Color("#ffdb65"), 1.00, 0.62, 1.16, 52],
}

@onready var fish: Sprite2D = $Fish
@onready var camera: Camera2D = $Camera2D
@onready var animator: AnimationPlayer = $AnimationPlayer
@onready var glow: Node2D = $Glow
@onready var screen_fx: ShaderMaterial = $HUD/FX.material
@onready var badge: Label = $HUD/Badge

var _running := false
var _serial := 0
var _tween: Tween
var _previous_camera: Camera2D
var _time_owned := false
var _saved_time := 1.0
var _palette := Color.WHITE
var _profile: Array
var _anticipation := 0.0
var _phase := 0.0
var _burst := -1.0
var _aurora := 0.0
var _shake := 0.0
var _silhouette := false

func _ready() -> void:
	glow.draw.connect(_draw_glow)
	_build_animation_library()
	_reset_visuals()

func play(requested_grade: String = "", pet_texture: Texture2D = null) -> void:
	var selected := (grade if requested_grade.is_empty() else requested_grade).strip_edges().to_upper()
	if not PROFILES.has(selected):
		push_warning("Unsupported gacha grade: %s" % selected)
		return
	cancel()
	_serial += 1
	var run := _serial
	_running = true
	grade = selected
	_profile = PROFILES[grade]
	_palette = _profile[0]
	_previous_camera = get_viewport().get_camera_2d()
	camera.enabled = true
	camera.make_current()
	screen_fx.set_shader_parameter("glint", _palette)
	badge.add_theme_color_override("font_color", _palette.lightened(0.24))
	fish.texture = preload("res://Fish.png")
	fish.scale = Vector2.ONE * 2.58
	fish.position = Vector2(110, WATER + 105)
	fish.self_modulate = Color("#101829")
	fish.show()
	_silhouette = true
	
	var t := _new_tween()
	t.tween_property(self, "_anticipation", 1.0, _profile[1])
	t.parallel().tween_property(fish, "position", Vector2(110, WATER + 61), _profile[1])
	await t.finished
	if not _is_current(run): return
	
	if grade == "SSS":
		if not reduced_flashes:
			screen_fx.set_shader_parameter("invert", 0.68)
			await _hold(0.065)
			if not _is_current(run): return
		screen_fx.set_shader_parameter("invert", 0.0)
		screen_fx.set_shader_parameter("blackout", 0.88)
		t = _new_tween()
		t.tween_property(self, "_aurora", 1.0, 0.36)
		t.parallel().tween_method(_set_blackout, 0.88, 0.0, 0.36)
		await t.finished
		if not _is_current(run): return
	
	_silhouette = false
	fish.self_modulate = _palette.lerp(Color.WHITE, 0.42)
	fish.position = Vector2(106, WATER + 20)
	fish.rotation_degrees = -17.0
	_burst = 0.0
	_shake = 7.0 if grade == "SSS" and not reduced_motion else 0.0
	if grade == "SSS":
		# The presentation holds its pose without pausing unrelated game systems.
		camera.zoom = Vector2.ONE * (1.06 if not reduced_motion else 1.0)
		await _hold(0.08)
		if not _is_current(run): return
	
	var apex := Vector2(144, 186 if grade == "SSS" else 216)
	t = _new_tween()
	t.tween_property(fish, "position", apex, _profile[2]).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(fish, "rotation_degrees", 11.0, _profile[2])
	if not reduced_motion:
		t.parallel().tween_property(camera, "zoom", Vector2.ONE * float(_profile[3]), _profile[2])
	await t.finished
	if not _is_current(run): return
	
	_burst = 0.0
	animator.play("impact")
	if grade == "SSS":
		_saved_time = Engine.time_scale
		_time_owned = true
		Engine.time_scale = _saved_time * 0.42
		_shake = 10.0 if not reduced_motion else 0.0
		_tween = create_tween()
		_tween.tween_property(fish, "rotation_degrees", 23.0, 0.16).set_trans(Tween.TRANS_SINE)
		_tween.parallel().tween_property(fish, "position:y", apex.y - 8.0, 0.16)
		await _hold(0.38)
		if not _is_current(run): return
		_tween.kill()
		_restore_time()
	else:
		await _hold(0.16)
		if not _is_current(run): return
	
	if pet_texture != null:
		fish.texture = pet_texture
		fish.scale = Vector2.ONE * 1.58
		fish.rotation = 0.0
		fish.self_modulate = Color.WHITE
	# The SSS result stays airborne throughout the reveal.
	fish.position = Vector2(135, 179 if grade == "SSS" else 223)
	_set_impact(1.0)
	badge.text = grade
	badge.show()
	badge.pivot_offset = badge.size * 0.5
	animator.play("badge")
	t = _new_tween()
	t.tween_property(fish, "position:y", fish.position.y - 7.0, 0.42).set_trans(Tween.TRANS_SINE)
	t.tween_property(fish, "position:y", fish.position.y, 0.42).set_trans(Tween.TRANS_SINE)
	t.tween_interval(0.38)
	await t.finished
	if not _is_current(run): return
	_running = false
	finished.emit(grade)

func cancel() -> void:
	_serial += 1
	_running = false
	_restore_time()
	if _tween != null:
		var interrupted := _tween
		_tween = null
		if interrupted.is_running():
			interrupted.kill()
			interrupted.finished.emit()
	if is_node_ready():
		_restore_camera()
		_reset_visuals()

func _exit_tree() -> void:
	_restore_time()
	_restore_camera()

func _restore_time() -> void:
	if _time_owned:
		Engine.time_scale = _saved_time
		_time_owned = false

func _restore_camera() -> void:
	if is_instance_valid(camera):
		camera.enabled = false
	if is_instance_valid(_previous_camera) and _previous_camera.is_inside_tree():
		_previous_camera.make_current()
	_previous_camera = null

func _reset_visuals() -> void:
	animator.stop()
	fish.hide()
	badge.hide()
	badge.scale = Vector2.ONE
	camera.zoom = Vector2.ONE
	camera.offset = Vector2.ZERO
	_anticipation = 0.0
	_aurora = 0.0
	_shake = 0.0
	_burst = -1.0
	_silhouette = false
	for key in ["flash", "blackout", "invert"]:
		screen_fx.set_shader_parameter(key, 0.0)
	screen_fx.set_shader_parameter("wave", -1.0)

func _is_current(run: int) -> bool:
	return _running and _serial == run and is_inside_tree()

func _hold(seconds: float) -> Signal:
	return get_tree().create_timer(seconds, false, false, true).timeout

func _new_tween() -> Tween:
	_tween = create_tween().set_ignore_time_scale(true)
	return _tween

func _set_blackout(amount: float) -> void:
	screen_fx.set_shader_parameter("blackout", amount)

func _set_impact(progress: float) -> void:
	var strength := 0.0 if reduced_flashes else (0.58 if grade == "SSS" else 0.16)
	screen_fx.set_shader_parameter("flash", strength * pow(1.0 - progress, 5))
	screen_fx.set_shader_parameter("wave", progress if grade in ["S", "SS", "SSS"] and progress < 1.0 else -1.0)

func _build_animation_library() -> void:
	var library := AnimationLibrary.new()
	var impact := Animation.new()
	impact.length = 0.62
	var cue := impact.add_track(Animation.TYPE_METHOD)
	impact.track_set_path(cue, NodePath("."))
	for step in range(17):
		var progress := step / 16.0
		impact.track_insert_key(cue, progress * 0.60, {"method": &"_set_impact", "args": [progress]})
	library.add_animation("impact", impact)
	var stamp := Animation.new()
	stamp.length = 0.25
	var scale_track := stamp.add_track(Animation.TYPE_VALUE)
	stamp.track_set_path(scale_track, NodePath("HUD/Badge:scale"))
	stamp.track_insert_key(scale_track, 0.0, Vector2.ONE * 1.65)
	stamp.track_insert_key(scale_track, 0.11, Vector2.ONE * 0.91)
	stamp.track_insert_key(scale_track, 0.23, Vector2.ONE)
	library.add_animation("badge", stamp)
	animator.add_animation_library("", library)
	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE

func _process(delta: float) -> void:
	_phase += delta
	if _burst >= 0.0:
		_burst += delta
		if _burst > 1.4: _burst = -1.0
	_shake = move_toward(_shake, 0.0, delta * 27.0)
	camera.offset = Vector2(sin(_phase * 119.0), cos(_phase * 133.0)).round() * _shake
	queue_redraw()
	glow.queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-VIEW, VIEW * 3), Color("#131f3b"))
	draw_circle(Vector2(187, 100), 45, Color("#f7df9c"))
	draw_circle(Vector2(173, 111), 8, Color("#e4c980"))
	draw_circle(Vector2(205, 85), 11, Color("#e4c980"))
	for i in range(40):
		draw_rect(Rect2(Vector2(16 + (i * 43) % 236, 38 + (i * 29) % 193), Vector2.ONE * (1 + i % 2)), Color("#566986"))
	draw_rect(Rect2(-VIEW.x, WATER, VIEW.x * 3, VIEW.y), Color("#153f58"))
	draw_rect(Rect2(-VIEW.x, WATER + 95, VIEW.x * 3, VIEW.y), Color("#10293d"))
	draw_line(Vector2(-VIEW.x, WATER), Vector2(VIEW.x * 2, WATER), Color("#589ba5"), 2)
	for i in range(24):
		var x := float(13 + (i * 41) % 230)
		var y := float(277 + (i * 17) % 159)
		draw_line(Vector2(x, y), Vector2(x + 8 + i % 12, y), Color("#28536a"))
	for inset in [0, 5, 10]:
		draw_rect(Rect2(Vector2.ONE * inset, VIEW - Vector2.ONE * inset * 2), [Color("#48312b"), Color("#816047"), Color("#b58b56")][int(inset / 5)], false, 5)
	if _silhouette and _anticipation > 0.0:
		var span := 16.0 + _anticipation * 70.0
		var cracks := PackedVector2Array([Vector2(135-span, WATER+6), Vector2(111, WATER-2), Vector2(130, WATER+2), Vector2(149, WATER-5), Vector2(163, WATER), Vector2(135+span, WATER-4)])
		draw_polyline(cracks, Color(_palette, _anticipation), 2.0)

func _draw_glow() -> void:
	if _aurora > 0.0:
		for i in range(4):
			var band := PackedVector2Array()
			for x in range(0, 271, 9):
				band.append(Vector2(x, 110 + i * 17 + sin(x * 0.022 + _phase * 1.4 + i * 0.5) * 16))
			glow.draw_polyline(band, Color(Color("#71bea7").lerp(_palette, i / 3.0), 0.24 * _aurora), 5.0)
	if _burst >= 0.0 and not _profile.is_empty():
		var age := _burst / 1.4
		var count: int = _profile[4]
		for i in range(count):
			var angle := TAU * i / count
			var direction := Vector2.from_angle(angle)
			var radius := (14.0 + 146.0 * (1.0 - pow(1.0 - age, 2))) * (0.6 + (i % 7) * 0.07)
			var origin := fish.position
			if grade == "C":
				direction = Vector2.from_angle(-PI + PI * i / max(1, count - 1))
			elif grade == "B":
				direction = Vector2.from_angle(TAU * (i % 5) / 5.0)
			elif grade == "A":
				origin.x += -38 if i % 2 == 0 else 38
			elif grade == "S":
				radius *= 0.82 + 0.2 * cos(angle * 5.0)
			elif grade == "SS":
				radius *= 0.72 if i % 2 == 0 else 1.26
			elif grade == "SSS":
				radius *= 1.0 + 0.24 * cos(angle * 5.0)
			var point := origin + direction * radius + Vector2(0, age * age * 40)
			glow.draw_line(point, point - direction * (3.0 + (1.0-age)*8), Color(_palette, (1.0-age)*0.85), 2)
			glow.draw_rect(Rect2(point.round(), Vector2.ONE * (2 + i % 3)), Color(_palette.lightened(0.4), 1.0-age))
	if grade == "SSS" and is_instance_valid(badge) and badge.visible:
		for i in range(12):
			var a := i * TAU / 12 + _phase * 0.8
			var point := fish.position + Vector2(cos(a) * 76, sin(a) * 48)
			glow.draw_rect(Rect2(point.round(), Vector2.ONE * (2 + i % 3)), Color(_palette, 0.53))
