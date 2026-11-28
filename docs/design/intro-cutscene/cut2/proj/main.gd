extends Node2D
# 컷신 2컷: 문이 끼익 열림 → 타일 방 입장·문 닫힘 → 형광등 → 시계 시점(바늘 폭주·팔 사라짐·물 차오름) → 마지막 불꽃.
# 360x640 도트 화면을 3배(1080x1920)로 키워 그리고 위아래는 검은 영화 띠. 확대 없이 정수 픽셀 이동만 한다.
const W := 360
const H := 640
const T1 := 3.4        # 1샷(복도) 끝
const T2 := 7.0        # 2샷(타일 방) 끝
const END := 15.0
const CAP := "이상현상인가?"
var t := 0.0
var rng := RandomNumberGenerator.new()
var sv: SubViewport
var stage: Node2D
var font: FontFile
var hum: AudioStreamPlayer
var played := {}
var cap: Control
var fade: ColorRect
var flash: ColorRect

# 1샷
var s1: Node2D
var wide: Node2D
var bg1: Sprite2D
var res1: Sprite2D
var shadow1: Node2D
var mark1: Node2D
var tex_closed: Texture2D
var tex_open: Texture2D
var look := []
# 2샷
var s2: Node2D
var bg2: Sprite2D
var res2: Sprite2D
var mark2: Node2D
var slab: Node2D
var tilt := []
var walk := []
# 3샷
var s3: Node2D
var pov: Sprite2D
var armg: Node2D

var hands: Node2D
var fx: Node2D
var sec_ang := 0.0
var min_ang := 0.0
var hr_ang := 0.0
var last_tick := -1
var sparks := []
var spark_made := false
var next_water := 0.0
var dust: Node2D
var dust_a := 0.0

const EXCL := ["11", "11", "11", "11", "11", "11", "00", "11", "11"]
const QUES := ["01110", "10001", "00001", "00010", "00100", "00000", "00100"]
const DIAL := Vector2(191, 162)     # 팔 레이어 안에서의 시계판 중심
const ARM_POS := Vector2(0, 190)
# 물이 처음 스며 나오는 줄눈 위치(water_dist에서 뽑음): 기포가 먼저 뽀글 올라옴
const SEEP := [Vector2(7, 1), Vector2(247, 45), Vector2(7, 93), Vector2(7, 101), Vector2(7, 112), Vector2(7, 128), Vector2(321, 159), Vector2(175, 159), Vector2(241, 159), Vector2(7, 171), Vector2(247, 196), Vector2(247, 293), Vector2(122, 333), Vector2(7, 342), Vector2(246, 345), Vector2(133, 347), Vector2(240, 348), Vector2(335, 398), Vector2(272, 398), Vector2(166, 398), Vector2(153, 399), Vector2(348, 399), Vector2(97, 417), Vector2(7, 428), Vector2(153, 452), Vector2(65, 457), Vector2(205, 478), Vector2(149, 479), Vector2(304, 486), Vector2(131, 492), Vector2(222, 492), Vector2(7, 493), Vector2(149, 497), Vector2(209, 524), Vector2(212, 543), Vector2(147, 544), Vector2(344, 545), Vector2(212, 568), Vector2(214, 606), Vector2(215, 611), Vector2(156, 628), Vector2(96, 628), Vector2(256, 628), Vector2(151, 628)]

func _ready() -> void:
	rng.seed = 138
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
	cap = Control.new(); cap.size = Vector2(1080, 2400); cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.draw.connect(_draw_caption); add_child(cap)
	stage = Node2D.new(); sv.add_child(stage)
	var black := ColorRect.new(); black.color = Color.BLACK; black.size = Vector2(W, H); stage.add_child(black)
	_build_shot1(); _build_shot2(); _build_shot3()
	dust = Node2D.new(); dust.draw.connect(_draw_dust); stage.add_child(dust)
	flash = ColorRect.new(); flash.size = Vector2(W, H); flash.color = Color(1, 1, 1, 0); stage.add_child(flash)
	fade = ColorRect.new(); fade.size = Vector2(W, H); fade.color = Color(0, 0, 0, 1); stage.add_child(fade)
	hum = _player("res://snd/hum.ogg", -60.0); hum.stream.loop = true; hum.play()

func _build_shot1() -> void:
	s1 = Node2D.new(); stage.add_child(s1)
	wide = Node2D.new(); wide.position = Vector2(-12, -26); s1.add_child(wide)
	tex_closed = load("res://img/corridor.png"); tex_open = load("res://img/corridor_open.png")
	bg1 = Sprite2D.new(); bg1.texture = tex_closed; bg1.centered = false; wide.add_child(bg1)
	shadow1 = Node2D.new(); shadow1.draw.connect(_draw_shadow); wide.add_child(shadow1)
	for i in 9: look.append(load("res://img/look_%d.png" % i))
	res1 = Sprite2D.new(); res1.texture = look[0]; res1.centered = false; res1.position = Vector2(59, 339)
	res1.modulate = Color(0.86, 0.84, 0.78); wide.add_child(res1)
	mark1 = Node2D.new(); mark1.draw.connect(_draw_mark1); wide.add_child(mark1)

func _build_shot2() -> void:
	s2 = Node2D.new(); s2.position = Vector2(-12, -24); stage.add_child(s2)
	bg2 = Sprite2D.new(); bg2.texture = load("res://img/room.png"); bg2.centered = false
	var m := ShaderMaterial.new(); m.shader = load("res://room.gdshader"); bg2.material = m; s2.add_child(bg2)
	for i in 9:
		tilt.append(load("res://img/s_tilt_%d.png" % i)); walk.append(load("res://img/s_walk_%d.png" % i))
	slab = Node2D.new(); slab.draw.connect(_draw_slab); s2.add_child(slab)
	res2 = Sprite2D.new(); res2.texture = tilt[0]; res2.centered = false; s2.add_child(res2)
	mark2 = Node2D.new(); mark2.draw.connect(_draw_mark2); s2.add_child(mark2)

func _build_shot3() -> void:
	s3 = Node2D.new(); stage.add_child(s3)
	pov = Sprite2D.new(); pov.texture = load("res://img/plate.png"); pov.centered = false
	var m := ShaderMaterial.new(); m.shader = load("res://pov.gdshader")
	m.set_shader_parameter("water_tex", load("res://img/plate_water.png")); m.set_shader_parameter("water_dist", load("res://img/water_dist.png")); pov.material = m; s3.add_child(pov)
	armg = Node2D.new(); s3.add_child(armg)
	var arm := Sprite2D.new(); arm.texture = load("res://img/arm.png"); arm.centered = false; arm.position = ARM_POS; armg.add_child(arm)
	hands = Node2D.new(); hands.position = ARM_POS; hands.draw.connect(_draw_hands); armg.add_child(hands)
	fx = Node2D.new(); fx.draw.connect(_draw_fx); s3.add_child(fx)

func _player(path: String, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new(); p.stream = load(path); p.volume_db = db; add_child(p); return p

func _once(key: String, path: String, db: float, pitch := 1.0) -> void:
	if played.has(key): return
	played[key] = true
	_play(path, db, pitch)

func _play(path: String, db: float, pitch := 1.0) -> void:
	var p := _player(path, db); p.pitch_scale = pitch; p.play(); p.finished.connect(p.queue_free)

## 형광등 하나의 점등 곡선(1컷과 같음): 탕 켜짐 → 한 번 깜빡 → 안정
func _light(dt: float) -> float:
	if dt < 0.0: return 0.0
	if dt < 0.05: return 1.0
	if dt < 0.11: return 0.15
	if dt < 0.16: return 0.9
	if dt < 0.20: return 0.4
	return 1.0

func _process(delta: float) -> void:
	t += delta
	s1.visible = t < T1
	s2.visible = t >= T1 and t < T2
	s3.visible = t >= T2
	stage.position = Vector2.ZERO
	if t < 0.2: stage.position = Vector2(0, -1 if int(t * 30.0) % 2 == 0 else 1)   # 컷이 바뀌는 순간 1도트 흔들림
	dust_a = 0.0
	if t < T1: _shot1()
	elif t < T2: _shot2()
	else: _shot3()
	_hum()
	cap.queue_redraw()
	dust.queue_redraw()
	if t > END: get_tree().quit()

func _hum() -> void:
	var v := -16.0
	if t < 0.6: v = lerpf(-60.0, -16.0, t / 0.6)
	if t >= SPIN_END: v = lerpf(-16.0, -24.0, clampf((t - SPIN_END) / 1.0, 0, 1))   # 웅웅을 줄여 철썩 소리가 들리게
	if t >= 14.55: v = -80.0
	hum.volume_db = v
	var p := 1.0
	if t > 8.45: p = lerpf(1.0, 0.45, clampf((t - 8.45) / 3.0, 0, 1))
	hum.pitch_scale = p

# ───────── 1샷: 복도 ─────────
const DOOR_OPEN := 1.1
const ALERT := 1.15

func _shot1() -> void:
	dust_a = 1.0
	if t >= 0.3: _once("creak", "res://snd/creak.wav", -3.0)
	var open := t >= DOOR_OPEN
	bg1.texture = tex_open if open else tex_closed
	if open: _once("open", "res://snd/lamp_click.wav", -4.0, 0.55)
	# 연구원: 숨 쉬듯 1픽셀 → 놀람(움찔·!) → 문 쪽(왼쪽)을 돌아봄
	var yoff := 1 if fmod(t, 2.4) < 1.2 else 0
	var tex: Texture2D = look[0]
	var flip := false
	if t >= ALERT:
		_once("alert", "res://snd/alert.wav", -6.0)
		if t < ALERT + 0.1: yoff = -3
		tex = look[1] if t < 1.45 else look[4]
		flip = true
	res1.texture = tex; res1.flip_h = flip
	res1.position = Vector2(59, 339 + yoff)
	shadow1.queue_redraw(); mark1.queue_redraw()
	# 페이드: 시작은 검은 화면에서 천천히 밝아짐, 끝에서 어두워짐
	var a := 0.0   # 1컷에서 검정 없이 바로 이어짐
	if t > T1 - 0.3: a = clampf((t - (T1 - 0.3)) / 0.3, 0, 1)
	fade.color = Color(0, 0, 0, a)

## 발밑 그림자(1컷과 같은 모양)
func _draw_shadow() -> void:
	var c := Vector2(193, 574)
	for layer in [[54.0, 8.0, 0.30], [38.0, 5.0, 0.30]]:
		var rx: float = layer[0]; var ry: float = layer[1]
		for dy in range(-int(ry), int(ry) + 1):
			var hw := roundf(rx * sqrt(1.0 - pow(dy / (ry + 0.5), 2)))
			shadow1.draw_rect(Rect2(c.x - hw, c.y + dy, hw * 2, 1), Color(0.06, 0.045, 0.02, layer[2]))

func _draw_glyph(canvas: CanvasItem, rows: Array, at: Vector2, sc: int, col: Color) -> void:
	for oy in [-1, 0, 1]:
		for ox in [-1, 0, 1]:
			if ox == 0 and oy == 0: continue
			_glyph_pass(canvas, rows, at + Vector2(ox, oy), sc, Color(0.05, 0.04, 0.03))
	_glyph_pass(canvas, rows, at, sc, col)

func _glyph_pass(canvas: CanvasItem, rows: Array, at: Vector2, sc: int, col: Color) -> void:
	for y in rows.size():
		var r: String = rows[y]
		for x in r.length():
			if r[x] == "1": canvas.draw_rect(Rect2(at + Vector2(x * sc, y * sc), Vector2(sc, sc)), col)

func _draw_mark1() -> void:
	if t < ALERT or t > 2.35: return
	var hop := -2 if int((t - ALERT) * 10.0) % 2 == 0 and t < ALERT + 0.5 else 0
	hop += _pop(t - ALERT)
	_draw_glyph(mark1, EXCL, Vector2(178, 334 + hop), 2, Color(1.0, 0.85, 0.15))

# ───────── 2샷: 타일 방 ─────────
const S2_GLOW := 3.55
const APPEAR := 3.8
const TILT_T := 3.85
const WALK_T := 4.95
const SLAM_T := 5.7
const LIGHT_T := [6.25, 6.45, 6.62]
const FEET_X := 203.0      # 문틀 안 발 위치(배경 좌표)
const FEET_Y0 := 392.0

func _shot2() -> void:
	var amb := 0.0
	for i in LIGHT_T.size():
		amb = maxf(amb, _light(t - LIGHT_T[i]))
		if t >= LIGHT_T[i]: _once("L%d" % i, "res://snd/light_on.wav", -3.0 - i * 2.0, 1.0 + i * 0.06)
	var glow := clampf((t - S2_GLOW) / 0.3, 0, 1)
	if t >= SLAM_T + 0.08: glow = 0.0
	var mat := bg2.material as ShaderMaterial
	mat.set_shader_parameter("amb", amb); mat.set_shader_parameter("glow", glow)
	dust_a = clampf(amb, 0, 1)
	# 연구원
	var feet_y := FEET_Y0
	var tex: Texture2D = tilt[0]
	if t >= TILT_T and t < WALK_T:
		tex = tilt[clampi(int((t - TILT_T) / 0.11), 0, 8)]
	elif t >= WALK_T:
		var k := int((t - WALK_T) / 0.1)
		if k < 7:
			tex = walk[2 + k % 5]
			feet_y = FEET_Y0 + 2 * k
		else:
			tex = walk[8]
			feet_y = FEET_Y0 + 14
	res2.texture = tex
	res2.position = Vector2(FEET_X - 64, feet_y - 118)
	res2.visible = t >= APPEAR
	res2.modulate = Color(0.13, 0.12, 0.10).lerp(Color(0.95, 0.95, 0.92), clampf(amb, 0, 1))
	if t >= TILT_T + 0.15: _once("hmm", "res://snd/hmm.wav", -6.0)
	if t >= SLAM_T + 0.08: _once("slam", "res://snd/slam.wav", -1.0)
	# 문 닫힘 직후 흔들림
	if t >= SLAM_T + 0.08 and t < SLAM_T + 0.4:
		var kk := int((t - SLAM_T - 0.08) / 0.033)
		var amp := 3 if kk < 4 else (2 if kk < 7 else 1)
		stage.position = Vector2(amp if kk % 2 == 0 else -amp, 0)
	slab.modulate = Color(0.1, 0.1, 0.1).lerp(Color(1, 1, 1), clampf(amb, 0, 1))
	slab.queue_redraw(); mark2.queue_redraw()
	var a := 1.0 - clampf((t - T1) / 0.25, 0, 1)
	if t > T2 - 0.12: a = clampf((t - (T2 - 0.12)) / 0.12, 0, 1)
	fade.color = Color(0, 0, 0, a)

## 문이 닫히는 판(코드로 그린 어두운 문짝): 3단계로 쾅
func _draw_slab() -> void:
	if t < SLAM_T: return
	var k := int((t - SLAM_T) / 0.04)
	if k < 0: return
	var wd: int = [22, 43, 64][clampi(k, 0, 2)]
	var x0 := 160; var y0 := 276; var h := 117
	slab.draw_rect(Rect2(x0, y0, wd, h), Color(0.19, 0.24, 0.22))
	slab.draw_rect(Rect2(x0, y0, wd, 1), Color(0.08, 0.1, 0.09))
	slab.draw_rect(Rect2(x0 + wd - 1, y0, 1, h), Color(0.08, 0.1, 0.09))
	if wd >= 64:
		slab.draw_rect(Rect2(x0 + 8, y0 + 10, 48, 38), Color(0.15, 0.19, 0.18))
		slab.draw_rect(Rect2(x0 + 8, y0 + 56, 48, 52), Color(0.15, 0.19, 0.18))
		slab.draw_rect(Rect2(x0 + 52, y0 + 58, 5, 2), Color(0.55, 0.55, 0.45))

## 팝인: 나타날 때 위로 톡 튀었다 내려앉음(정수 도트만, 크기 변화 없음)
func _pop(dt: float) -> int:
	if dt < 0.04: return -5
	if dt < 0.08: return -3
	if dt < 0.12: return 1
	return 0

func _draw_mark2() -> void:
	if t < 4.0 or t > 4.9: return
	var bob := (-1 if int(t * 8.0) % 2 == 0 else 0) + _pop(t - 4.0)
	_draw_glyph(mark2, QUES, Vector2(FEET_X + 8, 262 + bob), 2, Color(1.0, 0.85, 0.15))

# ───────── 3샷: 시계 시점 ─────────
const ARM_IN := 7.05
const TICK_END := 8.45
const SPIN_END := 10.0
const ARM_OUT := 0.55
const WATER_T := 11.0
const LINE_T := 12.6
const ZAP_T := 14.55

func _shot3() -> void:
	var k := clampf((t - ARM_IN) / 0.5, 0, 1)
	armg.position = Vector2(roundf(160.0 * pow(1.0 - k, 3.0)), 0)
	if t >= SPIN_END: armg.position = Vector2(roundf(340.0 * pow(clampf((t - SPIN_END) / ARM_OUT, 0, 1), 3.0)), 0)   # 팔을 뒤로 쑥 뺌
	# 시계 바늘: 처음엔 TIK TIK, 점점 빨라지다 미친 듯이 돈다
	if t < 7.7: sec_ang = 0.0
	elif t < TICK_END:
		var n := int((t - 7.7) / 0.45) + 1
		sec_ang = 6.0 * n
		if n != last_tick:
			last_tick = n; _play("res://snd/tik.wav", -8.0)
	else:
		var u := t - TICK_END
		var v := 160.0 + u * u * 900.0
		sec_ang += v / 30.0 + (rng.randf_range(-9.0, 9.0) if t > 9.2 else 0.0)
		min_ang += v / 30.0 * 0.22
		hr_ang += v / 30.0 * 0.02
		var tk := int(sec_ang / 25.0)
		if tk != last_tick and t < 9.9: last_tick = tk; _play("res://snd/tik.wav", -10.0, rng.randf_range(0.9, 1.3))
	hands.queue_redraw()
	# 형광등 깜빡임(박자 어긋남): 불이 점점 불안해진다
	var br := 1.0
	if t > 8.5:
		var h := fposmod(sin(floorf(t * 14.0) * 12.9898) * 43758.5453, 1.0)
		var lim := 0.78 if t < 13.6 else 0.55
		if h > lim: br = 0.42
	dust_a = br * (1.0 if t < ZAP_T else 0.0)
	var mat := pov.material as ShaderMaterial
	mat.set_shader_parameter("bright", br)
	mat.set_shader_parameter("tm", t)
	mat.set_shader_parameter("grow", smoothstep(0.0, 1.0, clampf((t - WATER_T) / 2.3, 0, 1)))
	var wl := -1.0
	if t >= LINE_T: wl = lerpf(335.0, 585.0, smoothstep(0.0, 1.0, clampf((t - LINE_T) / 1.8, 0, 1)))
	mat.set_shader_parameter("wl", wl)
	# 물 스며드는 소리
	if t >= WATER_T and t < ZAP_T and t >= next_water:
		var busy := clampf((t - WATER_T) / 3.4, 0.0, 1.0)
		next_water = t + rng.randf_range(0.30, 0.55) * lerpf(1.3, 0.55, busy)
		_play("res://snd/slosh%d.wav" % rng.randi_range(1, 4), lerpf(-11.0, -3.0, busy), rng.randf_range(0.85, 1.15))
		if rng.randf() < 0.5: _play("res://snd/water.ogg", -12.0, rng.randf_range(0.8, 1.1))
	# 화면 흔들림: 점점 커진다(정수 픽셀)
	if t > 8.6 and t < ZAP_T:
		var amp := 1 if t < 12.0 else 2
		if int(t * 30.0) % 2 == 0: stage.position = Vector2(rng.randi_range(-amp, amp), rng.randi_range(-amp, amp))
	# 마지막: 형광등이 팍 불꽃 튀며 꺼짐
	if t >= ZAP_T:
		_once("zap", "res://snd/zap.wav", 0.0)
		if not spark_made:
			spark_made = true
			for i in 46:
				sparks.append([Vector2(180 + rng.randf_range(-14, 14), 4.0), Vector2(rng.randf_range(-90, 90), rng.randf_range(-40, 140)), rng.randf_range(0.25, 0.65)])
	fx.queue_redraw()
	var f := 0.0
	if t >= ZAP_T and t < ZAP_T + 0.05: f = 1.0
	elif t >= ZAP_T + 0.05 and t < ZAP_T + 0.12: f = 0.55
	flash.color = Color(1, 1, 1, f)
	var a := 1.0 - clampf((t - T2) / 0.12, 0, 1)
	if t >= ZAP_T + 0.18: a = 1.0
	fade.color = Color(0, 0, 0, a)

func _line(canvas: CanvasItem, a: Vector2, b: Vector2, th: int, col: Color) -> void:
	var x0 := int(roundf(a.x)); var y0 := int(roundf(a.y)); var x1 := int(roundf(b.x)); var y1 := int(roundf(b.y))
	var dx := absi(x1 - x0); var dy := -absi(y1 - y0); var sx := 1 if x0 < x1 else -1; var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		canvas.draw_rect(Rect2(x0, y0, th, th), col)
		if x0 == x1 and y0 == y1: break
		var e2 := 2 * err
		if e2 >= dy: err += dy; x0 += sx
		if e2 <= dx: err += dx; y0 += sy

func _draw_hands() -> void:
	if t < ARM_IN + 0.35: return
	var c := DIAL
	var dark := Color(0.09, 0.08, 0.07)
	var p_hr := c + Vector2(sin(deg_to_rad(hr_ang + 300.0)), -cos(deg_to_rad(hr_ang + 300.0))) * 11.0
	var p_mn := c + Vector2(sin(deg_to_rad(min_ang + 40.0)), -cos(deg_to_rad(min_ang + 40.0))) * 16.0
	var p_sc := c + Vector2(sin(deg_to_rad(sec_ang)), -cos(deg_to_rad(sec_ang))) * 19.0
	_line(hands, c - Vector2(1, 1), p_hr - Vector2(1, 1), 2, dark)
	_line(hands, c - Vector2(1, 1), p_mn - Vector2(1, 1), 2, dark)
	_line(hands, c, p_sc, 1, Color(1.0, 0.8, 0.25))
	hands.draw_rect(Rect2(c.x - 2, c.y - 2, 4, 4), dark)

func _draw_fx() -> void:
	# 스며듦: 물이 번지기 직전부터 줄눈에서 작은 기포가 뽀글뽀글 올라왔다 터짐
	if t >= WATER_T - 0.7 and t < WATER_T + 2.6:
		var fade := 1.0 - clampf((t - (WATER_T + 1.6)) / 1.0, 0, 1)
		for i in SEEP.size():
			var ph := fposmod(t * (0.9 + 0.05 * (i % 7)) + i * 0.37, 1.0)
			if t < WATER_T - 0.7 + (i % 5) * 0.12: continue
			var p: Vector2 = SEEP[i]
			var col := Color(0.85, 1.0, 1.0, (0.9 - ph * 0.6) * fade)
			if ph < 0.75:
				var r := 1 if ph < 0.4 else 2
				fx.draw_rect(Rect2(p.x - r / 2, p.y - r / 2 - int(ph * 3.0), r, r), col)
			else:   # 톡 터짐: 십자 4도트
				for o in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
					fx.draw_rect(Rect2(p.x + o.x, p.y + o.y - 2, 1, 1), col)
	var dt := 1.0 / 30.0
	for s in sparks:
		s[1].y += 300.0 * dt
		s[0] += s[1] * dt
		s[2] -= dt
		if s[2] <= 0.0: continue
		var col := Color(1.0, 0.95, 0.7) if s[2] > 0.3 else Color(1.0, 0.6, 0.15)
		fx.draw_rect(Rect2(floorf(s[0].x), floorf(s[0].y), 2, 2), col)

# ───────── 자막(검은 띠 안, 1080 기준 3배 글자) ─────────
func _draw_caption() -> void:
	if t < 1.7 or t >= T1 - 0.05: return
	var n := mini(int((t - 1.7) / 0.09) + 1, CAP.length())
	if n > 0 and not played.has("b%d" % n):
		played["b%d" % n] = true
		_play("res://snd/blip.wav", -10.0)
	var s := CAP.substr(0, n)
	var full := font.get_string_size(CAP, HORIZONTAL_ALIGNMENT_LEFT, -1, 48)
	cap.draw_string(font, Vector2(roundf((1080.0 - full.x) / 2.0), 2290.0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Color(1.0, 0.98, 0.88))

## 먼지 레이어: 형광등 빛 속을 천천히 떠도는 1도트 먼지(불 밝기만큼 보임)
func _draw_dust() -> void:
	if dust_a <= 0.01: return
	var r := RandomNumberGenerator.new()
	for i in 34:
		r.seed = 300 + i
		var x := fposmod(r.randf() * W + t * r.randf_range(-3.0, 3.0) + sin(t * 0.7 + i) * 4.0, W)
		var y := fposmod(r.randf() * H + t * r.randf_range(2.0, 6.0), H)
		var a := (0.35 + 0.35 * sin(t * r.randf_range(1.0, 2.5) + i)) * dust_a
		dust.draw_rect(Rect2(floorf(x), floorf(y), 1, 1), Color(1.0, 0.98, 0.85, a))
