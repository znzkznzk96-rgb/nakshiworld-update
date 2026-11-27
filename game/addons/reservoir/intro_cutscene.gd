extends CanvasLayer
# 첫 실행 컷신(5컷). 컷 그림·연출은 art/intro/cutN/main.gd, 이 파일은 순서·화면 맞춤·컷별 건너뛰기만 맡는다.
# 컷 하나는 1080x2400(가운데 1080x1920 그림, 위아래 검은 띠) 기준으로 그려지고, 화면에 맞게 통째로 줄여 가운데 둔다.
signal finished

const CUTS := ["res://art/intro/cut1/main.gd", "res://art/intro/cut2/main.gd", "res://art/intro/cut3/main.gd", "res://art/intro/cut4/main.gd", "res://art/intro/cut5/main.gd"]
const SIZE := Vector2(1080, 2400)
const SKIP_HIDE_LAST := 4.5   # 마지막 컷은 달이 밝아지면 건너뛰기 버튼을 숨긴다

var idx := -1
var cut: Node2D
var holder: Node2D
var bg: ColorRect
var input: Control
var font: FontFile
var skip_rect := Rect2()

func _ready() -> void:
	layer = 120
	font = load("res://font/neodgm.ttf").duplicate(true)
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.oversampling = 1.0
	bg = ColorRect.new(); bg.color = Color.BLACK; bg.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(bg)
	holder = Node2D.new(); holder.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; add_child(holder)
	input = Control.new(); input.mouse_filter = Control.MOUSE_FILTER_STOP   # 컷신 중 게임 입력을 막는다
	input.gui_input.connect(_on_input); input.draw.connect(_draw_skip); add_child(input)
	_fit()
	_next()

func _fit() -> void:
	var vs := get_viewport().get_visible_rect().size
	# 가로 폭에 맞추면 도트가 정수 배율이 된다(270폭 → 1080폭 폰에서 3배). 세로가 모자라면 빈 위쪽 띠부터 잘라낸다.
	var s := vs.x / SIZE.x
	var pos := ((vs - SIZE * s) / 2.0).floor()
	if SIZE.y * s > vs.y:
		pos.y = floorf(vs.y - SIZE.y * s)
		if (SIZE.y - 240.0) * s > vs.y:   # 그림까지 잘리는 아주 짧은 화면만 통째로 줄인다
			s = minf(vs.x / SIZE.x, vs.y / SIZE.y); pos = ((vs - SIZE * s) / 2.0).floor()
	holder.scale = Vector2(s, s)
	holder.position = pos
	bg.size = vs; input.size = vs
	var w := 62.0; var h := 18.0
	var area_end := holder.position + SIZE * s
	skip_rect = Rect2(area_end.x - w - 6.0, area_end.y - h - 8.0, w, h)

func _next() -> void:
	if is_instance_valid(cut): cut.queue_free()
	idx += 1
	if idx >= CUTS.size():
		finished.emit(); queue_free(); return
	cut = Node2D.new(); cut.set_script(load(CUTS[idx])); holder.add_child(cut)

func _skip_visible() -> bool:
	if not is_instance_valid(cut): return false
	return idx < CUTS.size() - 1 or float(cut.get("t")) < SKIP_HIDE_LAST

func _process(_dt: float) -> void:
	_fit()
	if is_instance_valid(cut) and cut.get("done"): _next()
	input.queue_redraw()

func _on_input(e: InputEvent) -> void:
	var pressed: bool = (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) or (e is InputEventScreenTouch and e.pressed)
	if pressed and _skip_visible() and skip_rect.grow(6).has_point(e.position): _next()
	input.accept_event()

func _draw_skip() -> void:
	if not _skip_visible(): return
	input.draw_string(font, Vector2(skip_rect.position.x, skip_rect.end.y - 5), "건너뛰기 >>", HORIZONTAL_ALIGNMENT_RIGHT, skip_rect.size.x, 12, Color(0.8, 0.8, 0.8, 0.85))
