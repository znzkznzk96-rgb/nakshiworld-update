extends Node2D
# 게임용 사본: docs/design/intro-cutscene/install_into_game.py 가 만든다. 직접 고치지 말고 시안을 고친 뒤 다시 돌린다.
var done := false
# 컷신 1컷: 형광등 점등 → 헤드램프 → 수첩 손글씨. 360x640 도트 화면을 3배로 키워 1080x1920에 그리고 위아래는 검은 영화 띠.
const W := 360
const H := 640
const LIGHT_Y := [75, 156, 199, 230, 248, 259, 266, 271, 275]
const LIGHT_T := [0.60, 1.02, 1.36, 1.62, 1.82, 1.98, 2.10, 2.20, 2.28]
const GLYPH_T := 0.17
const WRITE_START := 4.25
var t := 0.0
var sv: SubViewport
var stage: Node2D
var wide: Node2D
var close: Node2D
var bg: Sprite2D
var researcher: Sprite2D
var hand: Sprite2D
var fade: ColorRect
var shadow: Node2D
var look := []
const LOOK_START := 1.15
const LOOK_FRAME := 0.2
var ink: Node2D
var font: FontFile
var hum: AudioStreamPlayer
var played := {}
var dust: Node2D
var dust_a := 0.0

func _ready() -> void:
	font = load("res://font/neodgm.ttf").duplicate(true)
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	sv = SubViewport.new(); sv.size = Vector2i(W, H); sv.transparent_bg = false
	sv.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(sv)
	var view := Sprite2D.new(); view.texture = sv.get_texture(); view.centered = false
	view.scale = Vector2(3, 3); view.position = Vector2(0, 240); view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(view)
	stage = Node2D.new(); sv.add_child(stage)
	var black := ColorRect.new(); black.color = Color.BLACK; black.size = Vector2(W, H); stage.add_child(black)
	# 넓은 화면
	wide = Node2D.new(); stage.add_child(wide)
	bg = Sprite2D.new(); bg.texture = load("res://art/intro/cut1/img/corridor.png"); bg.centered = false
	var mat := ShaderMaterial.new(); mat.shader = load("res://art/intro/cut1/corridor.gdshader")
	var rr := PackedFloat32Array()
	for i in LIGHT_Y.size(): rr.append(0.85 if i == 0 else (300.0 - LIGHT_Y[i]) / 300.0)
	mat.set_shader_parameter("rr", rr); bg.material = mat; wide.add_child(bg)
	researcher = Sprite2D.new(); researcher.texture = load("res://art/intro/cut1/img/look_0.png"); researcher.centered = false
	researcher.position = Vector2(59, 339)
	shadow = Node2D.new(); shadow.draw.connect(_draw_shadow); wide.add_child(shadow)
	wide.add_child(researcher)
	for i in 9: look.append(load("res://art/intro/cut1/img/look_%d.png" % i))
	dust = Node2D.new(); dust.draw.connect(_draw_dust); stage.add_child(dust)
	# 클로즈업
	close = Node2D.new(); close.visible = false; stage.add_child(close)
	var nb := Sprite2D.new(); nb.texture = load("res://art/intro/cut1/img/notebook_bg.png"); nb.centered = false; close.add_child(nb)
	ink = Node2D.new(); ink.draw.connect(_draw_ink); close.add_child(ink)
	hand = Sprite2D.new(); hand.texture = load("res://art/intro/cut1/img/hand.png"); hand.centered = false
	hand.position = HAND_HOME; close.add_child(hand)
	fade = ColorRect.new(); fade.size = Vector2(W, H); fade.color = Color(0, 0, 0, 0); stage.add_child(fade)
	hum = _player("res://art/intro/cut1/snd/hum.ogg", -60.0); hum.stream.loop = true; hum.play()

func _player(path: String, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new(); p.stream = load(path); p.volume_db = db; add_child(p); return p

func _once(key: String, path: String, db: float, pitch := 1.0) -> void:
	if played.has(key): return
	played[key] = true
	var p := _player(path, db); p.pitch_scale = pitch; p.play()
	p.finished.connect(p.queue_free)

## 등 하나의 점등 곡선: 탕 켜짐 → 한 번 깜빡 → 안정
func _light(dt: float) -> float:
	if dt < 0.0: return 0.0
	if dt < 0.05: return 1.15
	if dt < 0.11: return 0.15
	if dt < 0.16: return 0.9
	if dt < 0.20: return 0.4
	return 1.0

func _process(delta: float) -> void:
	t += delta
	# 웅웅 소리: 첫 등과 함께 커지고 끝에서 아주 미세하게 흔들림
	hum.volume_db = lerpf(-60.0, -16.0, clampf((t - 0.2) / 0.8, 0, 1)) if t < 1.2 else -16.0
	hum.pitch_scale = 1.0 - (0.03 * sin((t - 7.0) * 18.0) if t > 7.0 else 0.0)
	var on := PackedFloat32Array()
	for i in LIGHT_T.size():
		on.append(_light(t - LIGHT_T[i]))
		if t >= LIGHT_T[i]: _once("l%d" % i, "res://art/intro/cut1/snd/light_on.ogg", -2.0 - i * 2.6, 1.0 + i * 0.03)
	bg.material.set_shader_parameter("on", on)
	# 카메라: 정수 픽셀로 아주 천천히 위로 흘림(확대 없음)
	wide.position = Vector2(-12, -roundf(lerpf(44.0, 26.0, clampf(t / 4.0, 0, 1))))
	# 연구원: 등 뒤에서 비치는 빛이라 어두운 실루엣, 헤드램프가 켜지면 살짝 드러남
	# 둘러보기: 불이 켜지기 시작하면 고개를 들어 먼 쪽을 보고 옆을 살핀 뒤 돌아온다. 그 전엔 숨 쉬듯 1픽셀만
	var lf := int((t - LOOK_START) / LOOK_FRAME)
	researcher.texture = look[lf] if lf >= 0 and lf < look.size() else look[0]
	researcher.position = Vector2(59, 339 + (1 if fmod(t, 2.4) < 1.2 else 0))
	shadow.queue_redraw()
	dust_a = clampf((t - 1.6) / 1.0, 0, 1) if t < 3.85 else 0.0
	dust.queue_redraw()
	# 연구원: 첫 등이 켜질 때 어둠에서 드러나고, 불이 다 켜지면 앞쪽 빛을 받아 조금 더 밝아진다
	var near: float = clampf(on[0], 0, 1)
	researcher.modulate = Color(0.03, 0.03, 0.04).lerp(Color(0.62, 0.60, 0.56), near).lerp(Color(0.86, 0.84, 0.78), clampf((t - 2.3) / 0.6, 0, 1))
	# 3.85초: 짧은 암전 컷 → 클로즈업
	wide.visible = t < 3.85
	close.visible = t >= 3.97
	fade.color = Color(0, 0, 0, 0)   # 2컷으로 검정 없이 바로 이어짐(문 끼익 소리로 전환)   # 겹친 그림이 비치지 않게 검은 막으로 어둡게
	close.position = Vector2(0, roundf(lerpf(14.0, 0.0, clampf((t - 3.97) / 3.4, 0, 1))))
	var head := _write_head()
	hand.position = _hand_pos(head)
	if head.x >= 0.0 and head.x < _total_glyphs() and head.y < 1.0:
		_once("s%d" % int(head.x), "res://art/intro/cut1/snd/scribble.ogg", -8.0, randf_range(0.95, 1.12))
	ink.queue_redraw()
	# 수첩에 비친 형광등 빛이 숨 쉬듯 아주 조금 출렁임
	var br := 1.0 + floorf(sin(t * 2.2) * 3.0) / 100.0
	close.modulate = Color(br, br, br)
	if t > 7.0: done = true

## 발밑 그림자: 머리 위 형광등 빛이라 발 바로 아래 납작하게, 불이 켜진 만큼 진해진다
func _draw_shadow() -> void:
	var on0: float = clampf(_light(t - LIGHT_T[0]), 0, 1)
	if on0 <= 0.0: return
	var c := Vector2(193, 574)
	# 바깥 옅은 타원 + 안쪽 진한 타원(도트 경계 그대로)
	for layer in [[54.0, 8.0, 0.30], [38.0, 5.0, 0.30]]:
		var rx: float = layer[0]; var ry: float = layer[1]
		for dy in range(-int(ry), int(ry) + 1):
			var hw := roundf(rx * sqrt(1.0 - pow(dy / (ry + 0.5), 2)))
			shadow.draw_rect(Rect2(c.x - hw, c.y + dy, hw * 2, 1), Color(0.06, 0.045, 0.02, layer[2] * on0))

const HAND_HOME := Vector2(200, 300)
const PEN_TIP := Vector2(223, 364)

## 펜 끝이 지금 쓰는 글자 위치를 따라가게 손 위치를 정한다(정수 픽셀)
func _hand_pos(head: Vector2) -> Vector2:
	var g := _glyphs()
	var target := PEN_TIP
	if head.x < 0.0:
		var k := clampf((t - (WRITE_START - 0.35)) / 0.35, 0, 1)
		var first: Vector2 = INK_AT[0] + Vector2(g[0][1], 13)
		target = PEN_TIP.lerp(first, k * k * (3.0 - 2.0 * k))
	elif head.x >= g.size():
		var last = g[g.size() - 1]
		target = INK_AT[last[0]] + Vector2(last[2] + 2, 13)
		# 다 쓰고 나면 펜을 떼고 손이 원래 자리로 천천히 돌아온다
		var t_end := WRITE_START + g.size() * (GLYPH_T + GLYPH_PAUSE)
		var k := clampf((t - t_end - 0.25) / 0.6, 0, 1)
		target = target.lerp(PEN_TIP + Vector2(6, 4), k * k * (3.0 - 2.0 * k))
	else:
		var cur = g[int(head.x)]
		var f: float = head.y
		target = INK_AT[cur[0]] + Vector2(lerpf(cur[1], cur[2], f), 13 + roundf(sin(t * 38.0) * 1.0) if f < 1.0 else 13)
		# 줄이 바뀌는 사이(쉬는 시간)에 다음 글자 시작점으로 미끄러짐
		if f >= 1.0 and int(head.x) + 1 < g.size():
			var nxt = g[int(head.x) + 1]
			var k := clampf(((t - WRITE_START) / (GLYPH_T + GLYPH_PAUSE) - head.x - GLYPH_T / (GLYPH_T + GLYPH_PAUSE)) / (GLYPH_PAUSE / (GLYPH_T + GLYPH_PAUSE)), 0, 1)
			target = target.lerp(INK_AT[nxt[0]] + Vector2(nxt[1], 13), k)
	return (HAND_HOME + target - PEN_TIP).round()

var ink_tex := []
var ink_meta := []
const INK_AT := [Vector2(190, 294)]
const GLYPH_PAUSE := 0.06

func _glyphs() -> Array:
	if ink_tex.is_empty():
		ink_meta = JSON.parse_string(FileAccess.get_file_as_string("res://art/intro/cut1/img/ink.json"))
		for i in ink_meta.size(): ink_tex.append(load("res://art/intro/cut1/img/ink%d.png" % i))
	var out := []
	for li in ink_meta.size():
		for g in ink_meta[li]: out.append([li, float(g[0]), float(g[1])])
	return out

## 지금 쓰고 있는 글자 번호와 진행률(-1이면 아직)
func _write_head() -> Vector2:
	var k := (t - WRITE_START) / (GLYPH_T + GLYPH_PAUSE)
	if k < 0.0: return Vector2(-1, 0)
	var i := floorf(k)
	var f := clampf((k - i) * (GLYPH_T + GLYPH_PAUSE) / GLYPH_T, 0, 1)
	return Vector2(i, f)

func _total_glyphs() -> int:
	return _glyphs().size()

func _draw_ink() -> void:
	var head := _write_head()
	if head.x < 0.0: return
	var g := _glyphs()
	# 줄별로 지금까지 쓴 오른쪽 끝을 구해 그 폭만큼만 보여 준다(왼쪽부터 쓱)
	var reach := []
	for li in ink_tex.size(): reach.append(-1.0)
	for i in g.size():
		if i > head.x: break
		var f: float = 1.0 if i < head.x else head.y
		reach[g[i][0]] = maxf(reach[g[i][0]], lerpf(g[i][1], g[i][2], f))
	for li in ink_tex.size():
		if reach[li] <= 0.0: continue
		var tex: Texture2D = ink_tex[li]
		var w: float = minf(ceilf(reach[li]), tex.get_width())
		ink.draw_texture_rect_region(tex, Rect2(INK_AT[li], Vector2(w, tex.get_height())), Rect2(0, 0, w, tex.get_height()))

## 먼지 레이어: 형광등 빛 속을 천천히 떠도는 1도트 먼지(불이 다 켜지면 보임)
func _draw_dust() -> void:
	if dust_a <= 0.01: return
	var r := RandomNumberGenerator.new()
	for i in 34:
		r.seed = 300 + i
		var x := fposmod(r.randf() * W + t * r.randf_range(-3.0, 3.0) + sin(t * 0.7 + i) * 4.0, W)
		var y := fposmod(r.randf() * H + t * r.randf_range(2.0, 6.0), H)
		var a := (0.35 + 0.35 * sin(t * r.randf_range(1.0, 2.5) + i)) * dust_a
		dust.draw_rect(Rect2(floorf(x), floorf(y), 1, 1), Color(1.0, 0.98, 0.85, a))
