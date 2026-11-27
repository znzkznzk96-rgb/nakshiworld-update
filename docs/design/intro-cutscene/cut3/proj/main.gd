extends Node2D
# 컷신 3컷: 바닥이 깨져 수면이 되고(차원이 열림) → 소용돌이 속으로 → 낚시월드 저수지 위로 떨어져 첨벙, 암전.
# 360x640 도트 화면을 3배(1080x1920)로 키워 그리고 위아래는 검은 영화 띠. 확대 없이 정수 픽셀 이동만 한다.
const W := 360
const H := 640
const T_A2 := 1.9      # 부츠 가라앉는 수면
const T_B := 3.5       # 소용돌이
const T_C := 5.3       # 저수지 낙하
const T_SPLASH := 7.4
const END := 8.9
const CB := Vector2(180, 308)    # 소용돌이 중심
const CM := Vector2(180, 322)    # 저수지 달 반사 중심(첨벙 지점)
var t := 0.0
var rng := RandomNumberGenerator.new()
var sv: SubViewport
var stage: Node2D
var played := {}
var a1: Sprite2D
var a2: Sprite2D
var sb: Sprite2D
var sc: Sprite2D
var fall: Sprite2D
var falls := []
var fall_tex := []
const FALL_SZ := [112, 96, 82, 70, 58, 48, 40, 34]
var fx: Node2D
var flash: ColorRect
var fade: ColorRect
var next_slosh := 0.5
var ring_t := -1.0

func _ready() -> void:
	rng.seed = 139
	RenderingServer.set_default_clear_color(Color.BLACK)
	sv = SubViewport.new(); sv.size = Vector2i(W, H); sv.transparent_bg = false
	sv.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(sv)
	var view := Sprite2D.new(); view.texture = sv.get_texture(); view.centered = false
	view.scale = Vector2(3, 3); view.position = Vector2(0, 240); view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(view)
	stage = Node2D.new(); sv.add_child(stage)
	var black := ColorRect.new(); black.color = Color.BLACK; black.size = Vector2(W, H); stage.add_child(black)
	a1 = _spr("res://img/a1.png", true); a2 = _spr("res://img/a2.png", true); sb = _spr("res://img/b.png", true); sc = _spr("res://img/c.png", true)
	(sc.material as ShaderMaterial).set_shader_parameter("area", Vector3(180, 322, 136))
	for i in 4: falls.append(load("res://img/d%d.png" % i))
	for p in 2:   # 멀어질수록 작아지도록 크기별 도트 그림을 미리 만든다(가장 가까운 점 방식, 보간 없음)
		var row := []
		for sz in FALL_SZ:
			var im: Image = (falls[1 + p] as Texture2D).get_image(); im.resize(sz, sz, Image.INTERPOLATE_NEAREST)
			row.append(ImageTexture.create_from_image(im))
		fall_tex.append(row)
	fall = Sprite2D.new(); fall.texture = falls[0]; fall.centered = false; fall.visible = false; stage.add_child(fall)
	fx = Node2D.new(); fx.draw.connect(_draw_fx); stage.add_child(fx)
	flash = ColorRect.new(); flash.size = Vector2(W, H); flash.color = Color(1, 1, 1, 0); stage.add_child(flash)
	fade = ColorRect.new(); fade.size = Vector2(W, H); fade.color = Color(0, 0, 0, 1); stage.add_child(fade)
	var h := _play("res://snd/hum.ogg", -26.0, 1.0); h.stream.loop = true

func _spr(path: String, shaded: bool) -> Sprite2D:
	var s := Sprite2D.new(); s.texture = load(path); s.centered = false; s.visible = false
	if shaded:
		var m := ShaderMaterial.new(); m.shader = load("res://wave.gdshader"); s.material = m
	stage.add_child(s); return s

func _play(path: String, db: float, pitch := 1.0) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new(); p.stream = load(path); p.volume_db = db; p.pitch_scale = pitch; add_child(p); p.play()
	if not path.ends_with(".ogg"): p.finished.connect(p.queue_free)
	return p

func _once(key: String, path: String, db: float, pitch := 1.0) -> void:
	if played.has(key): return
	played[key] = true
	_play(path, db, pitch)

func _process(delta: float) -> void:
	t += delta
	_scene()
	_audio()
	fx.queue_redraw()
	if t >= END + 0.2: get_tree().quit()

func _mat(s: Sprite2D, amp: float, glitch: float, hue: float, white: float) -> void:
	var m := s.material as ShaderMaterial
	m.set_shader_parameter("amp", amp); m.set_shader_parameter("tm", t); m.set_shader_parameter("glitch", glitch)
	m.set_shader_parameter("seed", floorf(t * 18.0)); m.set_shader_parameter("hue", hue); m.set_shader_parameter("white", white)

func _scene() -> void:
	a1.visible = t < T_A2; a2.visible = t >= T_A2 and t < T_B; sb.visible = t >= T_B and t < T_C; sc.visible = t >= T_C
	var sh := 0
	if t < T_A2:
		_mat(a1, 1.0 + 1.0 * clampf((t - 0.8) / 1.1, 0, 1), clampf((t - 1.4) / 0.5, 0, 1) * 0.2, 0.0, 0.0)
		if t > 0.35 and t < 0.65: sh = 3
		elif t > 1.1: sh = 1
	elif t < T_B:
		var k := clampf((t - T_A2) / (T_B - T_A2), 0, 1)
		_mat(a2, 2.0, clampf((t - (T_B - 0.7)) / 0.6, 0, 1) * 0.2, k * 0.3, 0.0)
		sh = 1
	elif t < T_C:
		_mat(sb, 0.0, 0.0, 0.8 * sin((t - T_B) * 2.2), 0.0)
		sh = 0
	else:
		_mat(sc, 1.5, 0.0, 0.0, 0.0)
		sh = 0 if t < T_SPLASH else (3 if t < T_SPLASH + 0.25 else 0)
	var off := Vector2.ZERO
	if sh > 0: off = Vector2(rng.randi_range(-sh, sh), rng.randi_range(-sh, sh))
	for n in [a1, a2, sb, sc]: n.position = off
	# 떨어지는 연구원
	fall.visible = t >= T_C + 0.1 and t < T_SPLASH
	if fall.visible:
		var k := clampf((t - (T_C + 0.1)) / (T_SPLASH - T_C - 0.1), 0, 1)
		var si := mini(int(pow(k, 0.8) * FALL_SZ.size()), FALL_SZ.size() - 1)
		var sz: int = FALL_SZ[si]
		fall.texture = fall_tex[int(t * 2.5) % 2][si]
		fall.position = Vector2(CM.x - sz / 2, roundf(lerpf(-30.0, CM.y, pow(k, 1.2)) - sz / 2))
	# 흰빛: 장면 전환 직전 번쩍 올라갔다 사라짐
	var f := 0.0
	for T in [T_A2, T_B, T_C]:
		var pre := 0.5 if T == T_B else 0.3
		if t < T and t > T - pre: f = maxf(f, (t - (T - pre)) / pre)
		elif t >= T and t < T + 0.35: f = maxf(f, 1.0 - (t - T) / 0.35)
	if t >= T_SPLASH and t < T_SPLASH + 0.15: f = maxf(f, 0.6 * (1.0 - (t - T_SPLASH) / 0.15))
	flash.color.a = f
	var fa := 1.0 - clampf(t / 0.4, 0, 1)
	if t > T_SPLASH + 0.2: fa = clampf((t - T_SPLASH - 0.2) / 1.0, 0, 1)
	fade.color.a = fa

func _audio() -> void:
	if t >= 0.35: _once("crack", "res://snd/crack.wav", -6.0)
	if t >= T_A2 - 0.8: _once("sweep", "res://snd/sweep.wav", -4.0)
	if t >= T_B: _once("vortex", "res://snd/vortex.wav", -4.0)
	if t >= T_C: _once("rush", "res://snd/rush.wav", -4.0)
	if t >= T_SPLASH: _once("splash", "res://snd/splash.wav", 0.0)
	if t >= 0.6 and t < T_B and t >= next_slosh:
		next_slosh = t + rng.randf_range(0.28, 0.5)
		_play("res://snd/slosh%d.wav" % rng.randi_range(1, 4), -9.0, rng.randf_range(0.9, 1.15))

func _px(c: Vector2, col: Color) -> void:
	fx.draw_rect(Rect2(floorf(c.x), floorf(c.y), 1, 1), col)

func _line(a: Vector2, b: Vector2, col: Color) -> void:
	var x0 := int(a.x); var y0 := int(a.y); var x1 := int(b.x); var y1 := int(b.y)
	var dx := absi(x1 - x0); var dy := -absi(y1 - y0); var sx := 1 if x0 < x1 else -1; var sy := 1 if y0 < y1 else -1
	var e := dx + dy
	for i in 600:
		fx.draw_rect(Rect2(x0, y0, 1, 1), col)
		if x0 == x1 and y0 == y1: break
		var e2 := 2 * e
		if e2 >= dy: e += dy; x0 += sx
		if e2 <= dx: e += dx; y0 += sy

func _circle(c: Vector2, r: int, col: Color) -> void:
	var x := r; var y := 0; var d := 1 - r
	while x >= y:
		for p in [Vector2(x, y), Vector2(y, x), Vector2(-y, x), Vector2(-x, y), Vector2(-x, -y), Vector2(-y, -x), Vector2(y, -x), Vector2(x, -y)]:
			_px(c + p, col)
		y += 1
		if d < 0: d += 2 * y + 1
		else: x -= 1; d += 2 * (y - x) + 1

func _draw_fx() -> void:
	var r := RandomNumberGenerator.new()
	# 물에 잠기는 2샷: 부츠 주변에서 올라오는 거품
	if t >= T_A2 and t < T_B:
		for i in 14:
			r.seed = 500 + i
			var bx := r.randf_range(40, 320); var by0 := r.randf_range(380, 560)
			var ph := fmod(t * r.randf_range(0.6, 1.2) + r.randf(), 1.0)
			var p := Vector2(bx + sin(ph * 9.0 + i) * 3.0, by0 - ph * 220.0)
			var rr := 1 + (i % 2)
			fx.draw_rect(Rect2(floorf(p.x), floorf(p.y), rr, rr), Color(0.85, 1, 1, 1.0 - ph))
	# 소용돌이: 중심에서 퍼지는 빛줄기
	if t >= T_B and t < T_C:
		for i in 44:
			r.seed = 900 + i
			var ang := r.randf() * TAU + (t - T_B) * 0.3
			var ph := fmod((t - T_B) * r.randf_range(0.35, 0.7) + r.randf(), 1.0)
			var p := ph * ph   # 안쪽으로 점점 빨려듦
			var d0 := 20.0 + (1.0 - p) * 360.0; var d1 := d0 + 14.0 + (1.0 - p) * 50.0
			var dir := Vector2(cos(ang), sin(ang) * 1.5)
			var col := Color(0.8, 0.95, 1.0, 0.3 + 0.6 * (1.0 - p))
			_line(CB + dir * d0, CB + dir * d1, col)
			_line(CB + dir * d0 + Vector2(1, 0), CB + dir * d1 + Vector2(1, 0), col)
		# 중심에서 맥박처럼 퍼지는 빛 고리
		for j in 3:
			var q := fmod((t - T_B) * 0.7 + j / 3.0, 1.0)
			_circle(CB, int(8.0 + q * 70.0), Color(1, 0.95, 0.8, 0.8 * (1.0 - q)))
	# 저수지 낙하: 바람줄
	if t >= T_C + 0.2 and t < T_SPLASH:
		var k := (t - T_C) / (T_SPLASH - T_C)
		for i in 6:
			r.seed = 1300 + i
			var x := r.randf_range(0, W); var sp := r.randf_range(600, 1100) * (0.5 + k)
			var y := fmod(r.randf() * 700.0 - t * sp + 1400.0, 700.0) - 30.0
			_line(Vector2(x, y), Vector2(x, y + 10 + 36 * k), Color(0.85, 0.95, 1.0, 0.15 + 0.2 * k))
	# 첨벙: 번지는 물결 고리와 튀는 물방울
	if t >= T_SPLASH:
		var s := t - T_SPLASH
		for j in 4:
			var rr := s * 120.0 - j * 14.0
			if rr > 2.0 and rr < 160.0: _circle(CM, int(rr), Color(0.8, 0.95, 1.0, clampf(1.0 - rr / 150.0, 0.0, 1.0)))
		for i in 24:
			r.seed = 1700 + i
			var ang := r.randf_range(-PI * 0.95, -PI * 0.05); var v := r.randf_range(70, 190)
			var p := CM + Vector2(cos(ang) * v * s, sin(ang) * v * s + 260.0 * s * s)
			if s < 0.9: fx.draw_rect(Rect2(floorf(p.x), floorf(p.y), 2, 2), Color(0.9, 1, 1, 1.0 - s))
