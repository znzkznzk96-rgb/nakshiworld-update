extends Node2D
# 컷신 5컷(마지막): 거대한 달 앞 부두 끝, 낚싯대를 멘 연구원과 흰 고양이 실루엣 → 자막 "여기선… 어떻게 탈출해야 하지…?"
# → 카메라가 위로 올라가며(시차 이동) 달이 화면을 채우고 밝아짐 → "낚시월드" 로고 → 암전.
# 360x640 도트 화면을 3배(1080x1920)로 키워 그리고 위아래는 검은 영화 띠. 확대 없이 정수 픽셀 이동만 한다.
const W := 360
const H := 640
const CAP := "여기선… 어떻게 탈출해야 하지…?"
const CAP_T := 2.2
const TILT_T := 4.5
const LOGO_T := 5.0
const FADE_T := 6.3
const END := 7.0
const FG_Y := 400
var t := 0.0
var sv: SubViewport
var stage: Node2D
var font: FontFile
var played := {}
var bg: Sprite2D
var fg: Sprite2D
var res: Sprite2D
var cat: Sprite2D
var logo: Sprite2D
var cap: Control
var fade: ColorRect
var res_tex := []
var cat_tex := []

func _ready() -> void:
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
	bg = _spr("res://img/bg.png", "res://moon.gdshader")
	for i in 8: res_tex.append(load("res://img/res_%d.png" % i)); cat_tex.append(load("res://img/cat_%d.png" % i))
	fg = _spr("res://img/fg.png", "")
	cat = _spr("res://img/cat_0.png", "res://sil.gdshader")
	res = _spr("res://img/res_0.png", "res://sil.gdshader")
	logo = _spr("res://img/logo.png", ""); logo.modulate.a = 0.0
	fade = ColorRect.new(); fade.size = Vector2(W, H); fade.color = Color(0, 0, 0, 1); stage.add_child(fade)
	var w := _play("res://snd/wind.wav", -10.0)
	var a := _play("res://snd/water.ogg", -24.0); a.stream.loop = true

func _spr(path: String, shader: String) -> Sprite2D:
	var s := Sprite2D.new(); s.texture = load(path); s.centered = false
	if shader != "":
		var m := ShaderMaterial.new(); m.shader = load(shader); s.material = m
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
	# 카메라 틸트 업: 앞 부두와 인물이 아래로 빠지며 달이 화면을 채움(배경은 화면 크기 그대로)
	var k := clampf((t - TILT_T) / 1.6, 0, 1); k = k * k * (3.0 - 2.0 * k)
	var dy := roundf(380.0 * k)
	fg.position = Vector2(0, FG_Y + dy)
	var fi := int(t * 6.0) % 8
	res.texture = res_tex[fi]; res.position = Vector2(180, FG_Y + 92 - 118 + dy)
	cat.texture = cat_tex[int(t * 5.0) % 8]; cat.position = Vector2(244, FG_Y + 90 - 61 + dy)   # 연구원 옆 부두 위
	var bm := bg.material as ShaderMaterial
	bm.set_shader_parameter("tm", t)
	bm.set_shader_parameter("moon", Vector3(180, 180, 168))
	bm.set_shader_parameter("boost", 1.0 + 0.4 * clampf((t - TILT_T) / 1.2, 0, 1))
	# 로고: 달 한가운데로 천천히 떠오름
	var la := clampf((t - LOGO_T) / 0.6, 0, 1)
	logo.modulate.a = la
	logo.position = Vector2(70, roundf(210.0 - 8.0 * la))
	if t >= LOGO_T: _once("chime", "res://snd/chime.wav", -6.0)
	var fa := 1.0 - clampf(t / 0.6, 0, 1)
	if t >= FADE_T: fa = clampf((t - FADE_T) / 0.6, 0, 1)
	fade.color.a = fa
	cap.queue_redraw()
	if t >= END + 0.2: get_tree().quit()

# 자막(검은 띠 안, 1080 기준 3배 글자). 2컷과 같은 방식
func _draw_caption() -> void:
	if t < CAP_T or t >= TILT_T + 0.6: return
	var n := mini(int((t - CAP_T) / 0.1) + 1, CAP.length())
	if not played.has("b%d" % n):
		played["b%d" % n] = true
		if CAP[n - 1] != " " and CAP[n - 1] != "…": _play("res://snd/blip.wav", -12.0)
	var full := font.get_string_size(CAP, HORIZONTAL_ALIGNMENT_LEFT, -1, 48)
	var a := 1.0 - clampf((t - TILT_T) / 0.6, 0, 1)
	cap.draw_string(font, Vector2(roundf((1080.0 - full.x) / 2.0), 2290.0), CAP.substr(0, n), HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Color(1.0, 0.98, 0.88, a))
