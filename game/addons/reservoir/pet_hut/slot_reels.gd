## 슬롯 릴 모듈 (독립형, 이미지 생성 없음)
## 구조 아이디어(릴 수/칸 수 파라미터 분리, 릴마다 정지 지연, 결과를 먼저 정하고 릴이 거기에 멈춤)는
## CadanoX/Godot-Slot-Machine (MIT, Copyright (c) 2019 Fabian Bolte)를 참고했고, 코드는 Godot 4로 새로 썼다.
class_name SlotReels
extends Control

## 모든 릴이 멈춘 뒤 한 번. result[행][열] = symbols 인덱스
signal spin_finished(result: Array)
## 릴 하나가 멈출 때마다 (연출용: 정지 소리 등)
signal reel_stopped(col: int)

@export var symbols: Array[Texture2D] = []
@export var reels := 3
@export var rows := 3
@export var cell_size := Vector2(62, 48)
## 심볼 그림 배율(1이면 그림 1픽셀이 게임 화면 1칸)
@export var symbol_scale := 1.0
## 첫 릴이 도는 시간(초)
@export var runtime := 1.2
## 도는 속도(칸/초). 클수록 빨리 흐른다.
@export var speed := 14.0
## 릴 사이 정지 시간 차(초)
@export var reel_delay := 0.25
## 마지막 릴을 한 칸씩 기어가듯 멈추게 한다(니어미스 예고 연출)
var crawl_last := false

var spinning := false
var _strips: Array[Node2D] = []
var _tweens: Array[Tween] = []
var _result: Array = []
var _stopped_count := 0
var _blur: Array[Texture2D] = []
## 도는 동안 채움 심볼에 쓰는 세로 번짐 정도(픽셀). 0이면 끔.
@export var blur_radius := 7
## 창 유리 느낌(반사 줄무늬 + 위아래 어두운 띠). 코드로 그려서 이미지 생성이 필요 없다.
@export var glass := true
var _glass: Control

func _ready() -> void:
	custom_minimum_size = Vector2(cell_size.x * reels, cell_size.y * rows)
	size = custom_minimum_size
	clip_contents = true
	if glass:
		_glass = Control.new()
		_glass.size = size
		_glass.z_index = 10
		_glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_glass.draw.connect(_draw_glass)
		add_child(_glass)

## result[행][열] = symbols 인덱스. 결과는 호출하는 쪽(가챠 로직)이 먼저 정해서 넘긴다.
func spin(result: Array) -> void:
	if spinning or symbols.is_empty():
		return
	assert(result.size() == rows and result[0].size() == reels, "result 크기가 rows x reels와 달라요")
	spinning = true
	_result = result
	_stopped_count = 0
	_make_blur()
	for s in _strips:
		s.queue_free()
	_strips.clear()
	_tweens.clear()
	# 처음에 아주 빠르게 돌다가 점점 느려지며 멈춘다
	for c in reels:
		var duration := runtime + c * reel_delay
		var fillers := maxi(int(speed * duration), rows)
		var strip := Node2D.new()
		add_child(strip)
		_strips.append(strip)
		# 결과는 strip 맨 위(0..rows-1), 채움 심볼은 그 아래. strip이 아래로 내려오면 결과가 창에 맞춰 멈춘다.
		for r in rows:
			_add_symbol(strip, result[r][c], r)
		for i in fillers:
			_add_symbol(strip, randi() % symbols.size(), rows + i, true)
		var travel := fillers * cell_size.y
		strip.position = Vector2(c * cell_size.x, -travel)
		var tw := create_tween()
		if crawl_last and c == reels - 1:
			tw.tween_property(strip, "position:y", -cell_size.y, duration * 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tw.tween_property(strip, "position:y", 0.0, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		else:
			tw.tween_property(strip, "position:y", 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.finished.connect(_on_reel_done.bind(c))
		_tweens.append(tw)

## 건너뛰기: 즉시 결과 위치로 맞추고 끝낸다.
func skip() -> void:
	if not spinning:
		return
	for c in _tweens.size():
		var tw := _tweens[c]
		if tw.is_running():
			tw.kill()
			_strips[c].position.y = 0.0
			_on_reel_done(c)

func _add_symbol(strip: Node2D, idx: int, row_index: int, blurred := false) -> void:
	var sp := Sprite2D.new()
	sp.texture = _blur[idx] if blurred and blur_radius > 0 else symbols[idx]
	sp.centered = true
	sp.scale = Vector2(symbol_scale, symbol_scale)
	sp.position = Vector2(cell_size.x * 0.5, cell_size.y * (row_index + 0.5))
	strip.add_child(sp)

func _on_reel_done(c: int) -> void:
	reel_stopped.emit(c)
	_stopped_count += 1
	if _stopped_count >= reels:
		spinning = false
		spin_finished.emit(_result)

## 실제 심볼 그림을 세로로 번지게 해서(코드, 이미지 생성 없음) 도는 동안 쓰는 텍스처를 만든다.
func _make_blur() -> void:
	if blur_radius <= 0 or _blur.size() == symbols.size():
		return
	_blur.clear()
	for t in symbols:
		var src := t.get_image()
		src.convert(Image.FORMAT_RGBA8)
		var w := src.get_width()
		var h := src.get_height()
		var dst := Image.create(w, h, false, Image.FORMAT_RGBA8)
		for x in w:
			for y in h:
				var r := 0.0; var g := 0.0; var b := 0.0; var a := 0.0
				for k in range(-blur_radius, blur_radius + 1):
					var yy := clampi(y + k, 0, h - 1)
					var c := src.get_pixel(x, yy)
					r += c.r * c.a; g += c.g * c.a; b += c.b * c.a; a += c.a
				var n := float(blur_radius * 2 + 1)
				if a > 0.0:
					dst.set_pixel(x, y, Color(r / a, g / a, b / a, a / n))
		_blur.append(ImageTexture.create_from_image(dst))

## 도트 느낌이 나게 그림 1픽셀(폰 화면 3픽셀) 계단으로만 그린다(부드러운 그라데이션 없음).
func _draw_glass() -> void:
	var u := symbol_scale if symbol_scale > 0.0 else 1.0
	var w := int(size.x / u)
	var h := int(size.y / u)
	# 위·아래 어두운 띠 (릴이 둥글게 말린 느낌), 3단계
	for i in 3:
		var a := 0.34 - i * 0.11
		_glass.draw_rect(Rect2(0, i * 3 * u, w * u, 3 * u), Color(0, 0, 0, a))
		_glass.draw_rect(Rect2(0, (h - (i + 1) * 3) * u, w * u, 3 * u), Color(0, 0, 0, a))
	# 비스듬한 반사 줄무늬 두 줄
	for y in h:
		var x1 := int(w * 0.30 - y * 0.55)
		_glass.draw_rect(Rect2(x1 * u, y * u, 7 * u, u), Color(1, 1, 1, 0.13))
		_glass.draw_rect(Rect2((x1 + 12) * u, y * u, 3 * u, u), Color(1, 1, 1, 0.09))
