extends Node2D
# 컷신 4컷: 1인칭 눈 깜빡임(흐릿→선명) → 시선을 내려 물에 잠긴 발 → 팔 시계 "위치 불명" → 3인칭 앉은 연구원 → 흰 고양이가 낚싯대를 물고 와 툭 떨어뜨림.
# 360x640 도트 화면을 3배(1080x1920)로 키워 그리고 위아래는 검은 영화 띠. 확대 없이 정수 픽셀 이동만 한다.
const W := 360
const H := 640
const T_TILT := 3.3
const T_ARM := 4.6
const T_TXT := 5.3
const T_FADE := 6.3
const T3 := 6.7
const T4 := 8.2        # 오솔길: 고양이만 걸어옴(연구원 없음)
const T5 := 9.9        # 다시 물가: 고양이가 들어와 낚싯대를 떨어뜨림
const CAT_IN := 10.0
const CAT_STOP := 11.2
const DROP := 11.3
const END := 12.8
const DIAL := Vector2(191, 162)
const ARM_POS := Vector2(0, 190)
const BLINK := [[0.0, 0.0], [0.3, 0.0], [0.75, 0.5], [1.0, 0.5], [1.15, 0.0], [1.4, 0.0], [1.9, 0.9], [2.1, 0.9], [2.25, 0.15], [2.45, 0.15], [2.9, 2.4]]
var t := 0.0
var rng := RandomNumberGenerator.new()
var sv: SubViewport
var stage: Node2D
var font: FontFile
var played := {}
var g1: Node2D
var vil: Sprite2D
var feet: Sprite2D
var armg: Node2D
var hands: Node2D
var s3: Node2D
var res: Sprite2D
var bga: Sprite2D
var bgb: Sprite2D
var sit: Texture2D
var sit2: Texture2D
var cat: Sprite2D
var stick: Sprite2D
var cat_tex := []
var stick_tex := []
var fx: Node2D
var fade: ColorRect
var next_slosh := 3.5
var stick_y := 0.0
var stick_vy := 0.0
var stick_state := 0   # 0 입에 물림, 1 떨어지는 중, 2 바닥

func _ready() -> void:
	rng.seed = 140
	font = load("res://font/neodgm.ttf").duplicate(true)
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	RenderingServer.set_default_clear_color(Color.BLACK)
	sv = SubViewport.new(); sv.size = Vector2i(W, H); sv.transparent_bg = false
	sv.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(sv)
	var view := Sprite2D.new(); view.texture = sv.get_texture(); view.centered = false
	view.scale = Vector2(3, 3); view.position = Vector2(0, 240); view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(view)
	stage = Node2D.new(); sv.add_child(stage)
	var black := ColorRect.new(); black.color = Color.BLACK; black.size = Vector2(W, H); stage.add_child(black)
	g1 = Node2D.new(); stage.add_child(g1)
	vil = _spr(g1, "res://img/eye.png", "res://mosaic.gdshader", Vector2.ZERO)
	feet = _spr(g1, "res://img/feet.png", "res://wave.gdshader", Vector2(0, 640))
	armg = Node2D.new(); armg.visible = false; stage.add_child(armg)
	var arm := Sprite2D.new(); arm.texture = load("res://img/arm.png"); arm.centered = false; arm.position = ARM_POS; armg.add_child(arm)
	hands = Node2D.new(); hands.position = ARM_POS; hands.draw.connect(_draw_dial); armg.add_child(hands)
	s3 = Node2D.new(); s3.visible = false; stage.add_child(s3)
	bga = _spr(s3, "res://img/village.png", "", Vector2.ZERO)
	bgb = _spr(s3, "res://img/path.png", "", Vector2.ZERO)
	sit = load("res://img/sit.png"); sit2 = load("res://img/sit2.png")
	res = Sprite2D.new(); res.texture = sit; res.centered = false; res.position = Vector2(92, 480); s3.add_child(res)
	for i in 9: cat_tex.append(load("res://img/cat_%d.png" % i)); stick_tex.append(load("res://img/stick_%d.png" % i))
	cat = Sprite2D.new(); cat.texture = cat_tex[0]; cat.centered = false; cat.flip_h = true; cat.visible = false; s3.add_child(cat)
	stick = Sprite2D.new(); stick.texture = stick_tex[0]; stick.centered = false; stick.flip_h = true; stick.visible = false; s3.add_child(stick)
	fx = Node2D.new(); fx.draw.connect(_draw_fx); stage.add_child(fx)
	fade = ColorRect.new(); fade.size = Vector2(W, H); fade.color = Color(0, 0, 0, 1); stage.add_child(fade)
	var a := _play("res://snd/water.ogg", -17.0); a.stream.loop = true

func _spr(par: Node, path: String, shader: String, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new(); s.texture = load(path); s.centered = false; s.position = pos
	if shader != "":
		var m := ShaderMaterial.new(); m.shader = load(shader); s.material = m
	par.add_child(s); return s

func _play(path: String, db: float, pitch := 1.0) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new(); p.stream = load(path); p.volume_db = db; p.pitch_scale = pitch; add_child(p); p.play()
	if not path.ends_with(".ogg"): p.finished.connect(p.queue_free)
	return p

func _once(key: String, path: String, db: float, pitch := 1.0) -> void:
	if played.has(key): return
	played[key] = true
	_play(path, db, pitch)

func _openness() -> float:
	for i in BLINK.size() - 1:
		var a: Array = BLINK[i]; var b: Array = BLINK[i + 1]
		if t >= a[0] and t < b[0]:
			var k: float = (t - a[0]) / (b[0] - a[0])
			return lerpf(a[1], b[1], k * k * (3.0 - 2.0 * k))
	return 2.4

func _process(delta: float) -> void:
	t += delta
	_scene(delta)
	_audio()
	fx.queue_redraw(); hands.queue_redraw()
	if t >= END + 0.2: get_tree().quit()

func _scene(delta: float) -> void:
	g1.visible = t < T3; armg.visible = t >= T_ARM and t < T3; s3.visible = t >= T3
	# 1샷: 흐릿한 마을이 눈 깜빡임에 따라 선명해짐
	var blk := 16.0
	if t >= 1.2: blk = 10.0
	if t >= 1.9: blk = 5.0
	if t >= 2.4: blk = 2.0
	if t >= 2.5: blk = 1.0
	(vil.material as ShaderMaterial).set_shader_parameter("block", blk)
	(vil.material as ShaderMaterial).set_shader_parameter("dim", 0.25 * clampf(1.0 - t / 2.6, 0, 1))
	# 시선을 아래로: 마을이 위로 밀려 나가고 물에 잠긴 발이 올라옴(정수 픽셀 이동)
	var k := clampf((t - T_TILT) / 0.8, 0, 1)
	g1.position = Vector2(0, -roundf(640.0 * k * k * (3.0 - 2.0 * k)))
	var fm := feet.material as ShaderMaterial
	fm.set_shader_parameter("amp", 1.0); fm.set_shader_parameter("tm", t); fm.set_shader_parameter("seed", 0.0)
	# 팔이 쑥 들어옴
	var ka := clampf((t - T_ARM) / 0.5, 0, 1)
	armg.position = Vector2(roundf(160.0 * pow(1.0 - ka, 3.0)), 0)
	# 3샷: 연구원 숨쉬기, 고양이
	bga.visible = t < T4 or t >= T5; bgb.visible = t >= T4 and t < T5
	res.visible = bga.visible
	if t >= T3:
		res.texture = sit2 if t >= CAT_STOP - 0.4 else sit
		res.position = Vector2(92, 480 + (1 if fmod(t, 1.8) < 0.9 else 0))
		cat.visible = bgb.visible or t >= CAT_IN
		if bgb.visible:   # 오솔길을 가로질러 걸어옴
			var fr2 := int((t - T4) * 9.0) % 9
			cat.texture = cat_tex[fr2]; cat.position = Vector2(roundf(372.0 - 85.0 * (t - T4)), 521)
			stick.visible = true; stick.texture = stick_tex[fr2]; stick.position = cat.position
		var ct := t - CAT_IN
		if t >= CAT_IN:
			var walking := t < CAT_STOP
			var x := 372.0 - 85.0 * ct
			if not walking: x = 372.0 - 85.0 * (CAT_STOP - CAT_IN)
			var fr := int(ct * 9.0) % 9 if walking else 0
			var nod := 2 if (t >= DROP and t < DROP + 0.15) else 0
			cat.texture = cat_tex[fr]; cat.position = Vector2(roundf(x), 521 + nod)
			if stick_state == 0:
				stick.visible = true; stick.texture = stick_tex[fr]; stick.position = cat.position
				if t >= DROP: stick_state = 1; stick_y = cat.position.y; stick_vy = -60.0
			elif stick_state == 1:
				stick_vy += 900.0 * delta; stick_y += stick_vy * delta
				if stick_y >= 542.0:
					stick_y = 542.0
					if absf(stick_vy) > 80.0: stick_vy = -stick_vy * 0.3
					else: stick_state = 2
				stick.position = Vector2(cat.position.x, roundf(stick_y))
			else:
				stick.position = Vector2(cat.position.x, 542)
	var fa := 0.0
	if t < 0.2: fa = 1.0 - t / 0.2
	if t >= T_FADE and t < T3: fa = clampf((t - T_FADE) / 0.35, 0, 1)
	if t >= T3 and t < T3 + 0.4: fa = 1.0 - (t - T3) / 0.4
	for T in [T4, T5]:
		if t >= T - 0.15 and t < T + 0.15: fa = 1.0 - absf(t - T) / 0.15
	if t >= END - 0.5: fa = clampf((t - (END - 0.5)) / 0.5, 0, 1)
	fade.color.a = fa

func _audio() -> void:
	for tt in [0.55, 1.65, 2.5]: if t >= tt: _once("h%f" % tt, "res://snd/heart.wav", -8.0)
	if t >= T_TILT and t < T_FADE and t >= next_slosh:
		next_slosh = t + rng.randf_range(0.45, 0.8)
		_play("res://snd/slosh%d.wav" % rng.randi_range(1, 4), -15.0, rng.randf_range(0.9, 1.15))
	if t >= T_TXT: _once("alert", "res://snd/alert.wav", -8.0)
	if t >= DROP: _once("drop", "res://snd/drop.wav", -4.0)

func _px(c: Vector2, col: Color) -> void:
	fx.draw_rect(Rect2(floorf(c.x), floorf(c.y), 1, 1), col)

func _draw_fx() -> void:
	# 눈꺼풀: 눈 모양으로 열렸다 닫힘
	if t < 2.95:
		var o := _openness()
		for x in W:
			var dx := absf(x + 0.5 - 180.0)
			var hh := o * 340.0 * maxf(0.0, 1.0 - pow(dx / (190.0 + 60.0 * o), 2.0))
			var yt := int(roundf(320.0 - hh)); var yb := int(roundf(320.0 + hh))
			if yt > 0: fx.draw_rect(Rect2(x, 0, 1, yt), Color.BLACK)
			if yb < H: fx.draw_rect(Rect2(x, yb, 1, H - yb), Color.BLACK)
	# 젖은 연구원에서 떨어지는 물방울
	if t >= T3 + 0.3 and t < END and (t < T4 or t >= T5):
		var r := RandomNumberGenerator.new()
		for i in 5:
			r.seed = 40 + i
			var ph := fmod(t * 1.1 + r.randf(), 1.0)
			var x := 118.0 + r.randf() * 70.0; var y0 := 520.0 + r.randf() * 30.0
			fx.draw_rect(Rect2(floorf(x), floorf(y0 + ph * ph * 60.0), 1, 2), Color(0.7, 0.9, 1.0, 1.0 - ph))

func _draw_dial() -> void:
	if t < T_TXT: return
	var c := DIAL
	var dark := Color(0.05, 0.06, 0.07)
	for y in range(-20, 21):
		var hw := int(sqrt(maxf(0.0, 400.0 - y * y)))
		hands.draw_rect(Rect2(c.x - hw, c.y + y, hw * 2, 1), dark)
	var blink_on := fmod(t - T_TXT, 0.7) < 0.5 or t - T_TXT < 0.2
	if blink_on:
		var col := Color(1.0, 0.55, 0.2)
		hands.draw_string(font, Vector2(c.x - 16, c.y - 4), "위치", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)
		hands.draw_string(font, Vector2(c.x - 16, c.y + 13), "불명", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)
