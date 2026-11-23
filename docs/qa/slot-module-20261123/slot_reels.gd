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
@export var cell_size := Vector2(50, 48)
## 첫 릴이 도는 시간(초)
@export var runtime := 1.2
## 도는 속도(칸/초). 클수록 빨리 흐른다.
@export var speed := 14.0
## 릴 사이 정지 시간 차(초)
@export var reel_delay := 0.25

var spinning := false
var _strips: Array[Node2D] = []
var _tweens: Array[Tween] = []
var _result: Array = []
var _stopped_count := 0

func _ready() -> void:
	custom_minimum_size = Vector2(cell_size.x * reels, cell_size.y * rows)
	size = custom_minimum_size
	clip_contents = true

## result[행][열] = symbols 인덱스. 결과는 호출하는 쪽(가챠 로직)이 먼저 정해서 넘긴다.
func spin(result: Array) -> void:
	if spinning or symbols.is_empty():
		return
	assert(result.size() == rows and result[0].size() == reels, "result 크기가 rows x reels와 달라요")
	spinning = true
	_result = result
	_stopped_count = 0
	for s in _strips:
		s.queue_free()
	_strips.clear()
	_tweens.clear()
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
			_add_symbol(strip, randi() % symbols.size(), rows + i)
		var travel := fillers * cell_size.y
		strip.position = Vector2(c * cell_size.x, -travel)
		var tw := create_tween()
		tw.tween_property(strip, "position:y", 0.0, duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
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

func _add_symbol(strip: Node2D, idx: int, row_index: int) -> void:
	var sp := Sprite2D.new()
	sp.texture = symbols[idx]
	sp.centered = true
	sp.position = Vector2(cell_size.x * 0.5, cell_size.y * (row_index + 0.5))
	strip.add_child(sp)

func _on_reel_done(c: int) -> void:
	reel_stopped.emit(c)
	_stopped_count += 1
	if _stopped_count >= reels:
		spinning = false
		spin_finished.emit(_result)
