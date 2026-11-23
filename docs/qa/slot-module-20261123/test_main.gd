## 시험용 장면: 만들어 둔 파츠(본체·심볼·레버·버튼)를 붙여 릴 모듈이 돌고 멎는지 확인한다.
extends Node2D

const A := "res://assets/"
# 등급 순서 D C B A S SS SSS -> 심볼 파일
const GRADE_SYMBOLS := ["D", "C", "B", "A", "S", "SS", "SSS"]

var reels: SlotReels
var lever: Sprite2D
var lamps: Array[Sprite2D] = []
var lever_up_tex: Texture2D
var lever_down_tex: Texture2D
var spin_count := 0

func _tex(name: String) -> Texture2D:
	return ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(A + name + ".png")))

func _ready() -> void:
	var body := Sprite2D.new()
	body.texture = _tex("body_empty"); body.centered = false; body.position = Vector2(2, 8)
	add_child(body)
	reels = SlotReels.new()
	var syms: Array[Texture2D] = []
	for g in GRADE_SYMBOLS:
		syms.append(_tex("sym_" + g))
	reels.symbols = syms
	reels.position = Vector2(2 + 34, 8 + 99)
	add_child(reels)
	reels.spin_finished.connect(_on_finished)
	for i in 5:
		var l := Sprite2D.new()
		l.texture = _tex("btn_off%d" % i)
		l.position = Vector2([53.5, 91.5, 129.0, 166.5, 204.5][i], 272.5)
		add_child(l); lamps.append(l)
	lever_up_tex = _tex("lever_up"); lever_down_tex = _tex("lever_down")
	lever = Sprite2D.new()
	lever.texture = lever_up_tex; lever.centered = false
	lever.position = Vector2(270 - lever_up_tex.get_width(), 8 + 252 - lever_up_tex.get_height())
	add_child(lever)

func pull() -> void:
	if reels.spinning:
		return
	spin_count += 1
	lever.texture = lever_down_tex
	for i in 5:
		lamps[i].texture = _tex("btn_on%d" % i)
	# 결과는 먼저 정한다: 여기서는 시험용으로 임의 3x3
	var res: Array = []
	for r in 3:
		res.append([randi() % 7, randi() % 7, randi() % 7])
	reels.spin(res)

func _on_finished(result: Array) -> void:
	lever.texture = lever_up_tex
	for i in 5:
		lamps[i].texture = _tex("btn_off%d" % i)
	print("SPIN_DONE ", result)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		if reels.spinning:
			reels.skip()
		else:
			pull()
