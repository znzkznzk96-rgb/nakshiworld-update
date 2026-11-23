## 슬롯 기계 한 대(본체+릴+레버+버튼 램프+당첨 연출). 이미지 생성 없이 코드로 연출한다.
## play(결과 3x3)만 부르면 레버 → 램프 → 릴 회전 → 정지 → 당첨 줄 연출까지 진행하고 finished 신호를 낸다.
class_name SlotMachine
extends Node2D

signal finished(info: Dictionary)

const A := "res://assets/"
const GRADES := ["D", "C", "B", "A", "S", "SS", "SSS"]
## 8개 줄(행3·열3·대각2). 각 칸은 [행, 열]
const LINES := [
	[[0,0],[0,1],[0,2]], [[1,0],[1,1],[1,2]], [[2,0],[2,1],[2,2]],
	[[0,0],[1,0],[2,0]], [[0,1],[1,1],[2,1]], [[0,2],[1,2],[2,2]],
	[[0,0],[1,1],[2,2]], [[0,2],[1,1],[2,0]],
]
const BODY_POS := Vector2(2, 8)
const WINDOW_POS := Vector2(36, 107)
const CELL := Vector2(62, 48)
const LAMP_X := [53.5, 91.5, 129.0, 166.5, 204.5]
const LAMP_Y := 272.5
## 레버 당김 프레임(PixelLab 모션에서 고른 것): 내려갈 때 / 올라올 때
const LEVER_DOWN := [0, 1, 2, 3, 5]
const LEVER_UP := [8, 0]

var reels: SlotReels
var lever: Sprite2D
var lamps: Array[Sprite2D] = []
var fx: Control
var _lever_tex := {}
var _lamp_off: Array[Texture2D] = []
var _lamp_on: Array[Texture2D] = []
var _win_cells: Array = []
var _fx_time := 0.0
var _fx_tier := 0
var _dim := false
var _body: Sprite2D
var busy := false

static func _tex(name: String) -> Texture2D:
	return ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(A + name + ".png")))

func _ready() -> void:
	_body = Sprite2D.new()
	_body.texture = _tex("body_empty"); _body.centered = false; _body.position = BODY_POS
	add_child(_body)
	reels = SlotReels.new()
	var syms: Array[Texture2D] = []
	for g in GRADES:
		syms.append(_tex("sym_" + g))
	reels.symbols = syms
	reels.cell_size = CELL
	reels.position = WINDOW_POS
	add_child(reels)
	fx = Control.new()
	fx.position = WINDOW_POS; fx.size = Vector2(CELL.x * 3, CELL.y * 3)
	fx.z_index = 20; fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.draw.connect(_draw_fx)
	add_child(fx)
	for i in 5:
		_lamp_off.append(_tex("btn_off%d" % i)); _lamp_on.append(_tex("btn_on%d" % i))
		var l := Sprite2D.new()
		l.texture = _lamp_off[i]; l.position = Vector2(LAMP_X[i], LAMP_Y)
		add_child(l); lamps.append(l)
	for i in [0,1,2,3,5,8]:
		_lever_tex[i] = _tex("lever_pull_%02d" % i)
	lever = Sprite2D.new()
	lever.texture = _lever_tex[0]; lever.centered = false
	lever.position = Vector2(270 - lever.texture.get_width(), BODY_POS.y + 252 - lever.texture.get_height())
	add_child(lever)

# ---------- 결과 만들기/판정 ----------

## 등급(0=D..6=SSS)으로 3x3 결과를 만든다. 줄 위치는 8곳 중 무작위, 나머지 칸은 더 높은 줄이 생기지 않게 채운다.
static func make_grid(grade: int, rng: RandomNumberGenerator, jackpot := false) -> Array:
	var g: Array = [[-1,-1,-1],[-1,-1,-1],[-1,-1,-1]]
	if jackpot:
		for r in 3:
			for c in 3: g[r][c] = grade
		return g
	var line: Array = LINES[rng.randi() % 8]
	for cell in line: g[cell[0]][cell[1]] = grade
	for tries in 300:
		var h := g.duplicate(true)
		for r in 3:
			for c in 3:
				if h[r][c] == -1: h[r][c] = rng.randi() % 7
		var info := evaluate(h)
		if info.top == grade and info.lines.size() == 1:
			return h
	# 안전망: 줄 밖 6칸을 서로 다른 다른 심볼로 채우면 추가 줄이 생길 수 없다
	var k := 1
	for r in 3:
		for c in 3:
			if g[r][c] == -1:
				g[r][c] = (grade + k) % 7; k += 1
	return g

## 줄 판정: 같은 심볼 3개가 한 줄이면 당첨. top=가장 높은 등급(없으면 -1)
static func evaluate(g: Array) -> Dictionary:
	var out := []
	var top := -1
	for line in LINES:
		var s: int = g[line[0][0]][line[0][1]]
		if s == g[line[1][0]][line[1][1]] and s == g[line[2][0]][line[2][1]]:
			out.append({"cells": line, "sym": s})
			top = maxi(top, s)
	var all_same := true
	for r in 3:
		for c in 3:
			if g[r][c] != g[0][0]: all_same = false
	return {"lines": out, "top": top, "jackpot": all_same}

# ---------- 진행 ----------

func play(grid: Array) -> void:
	if busy: return
	busy = true
	_win_cells = []; _dim = false
	fx.queue_redraw()
	var info := evaluate(grid)
	var top: int = info.top
	# 예고: 높은 등급일수록 마지막 릴을 더 뜸 들인다(결과는 이미 정해져 있음)
	reels.runtime = 1.0
	reels.reel_delay = 0.25 + (0.3 if top >= 4 else 0.0) + (0.4 if top >= 6 else 0.0)
	await _pull_lever()
	_start_lamp_chase()
	reels.spin(grid)
	await reels.spin_finished
	_stop_lamp_chase()
	await _win_show(info)
	busy = false
	finished.emit(info)

func skip() -> void:
	if reels.spinning: reels.skip()

func _pull_lever() -> void:
	for f in LEVER_DOWN:
		lever.texture = _lever_tex[f]; await get_tree().create_timer(0.05).timeout
	for f in LEVER_UP:
		lever.texture = _lever_tex[f]; await get_tree().create_timer(0.06).timeout

var _chase := false
func _start_lamp_chase() -> void:
	_chase = true
	_chase_loop()
func _stop_lamp_chase() -> void:
	_chase = false
	for i in 5: lamps[i].texture = _lamp_off[i]
func _chase_loop() -> void:
	var k := 0
	while _chase:
		for i in 5: lamps[i].texture = _lamp_on[i] if i == k % 5 else _lamp_off[i]
		k += 1
		await get_tree().create_timer(0.09).timeout

func _lamps_all(on: bool) -> void:
	for i in 5: lamps[i].texture = _lamp_on[i] if on else _lamp_off[i]

## 등급별 당첨 연출. 큰 등급일수록 단계가 늘어난다.
func _win_show(info: Dictionary) -> void:
	var top: int = info.top
	_fx_tier = top
	if top < 0: return
	var cells: Array = []
	for l in info.lines:
		for c in l.cells:
			if not (c in cells): cells.append(c)
	_win_cells = cells
	_dim = top >= 2
	_fx_time = 0.0
	var dur: float = [0.6, 0.8, 1.1, 1.3, 1.8, 2.3, 3.2][top]
	# 버튼 램프: 등급이 높을수록 점멸이 많고 빠름
	var blinks: int = [1, 2, 3, 4, 6, 8, 12][top]
	if top >= 5: _shake(top)
	var t := 0.0
	var step: float = dur / (blinks * 2)
	for b in blinks * 2:
		_lamps_all(b % 2 == 0)
		fx.queue_redraw()
		await get_tree().create_timer(step).timeout
	_lamps_all(false)
	if info.jackpot:
		await _jackpot()
	_dim = false
	fx.queue_redraw()

func _shake(top: int) -> void:
	var amp := 2.0 if top == 5 else 3.0
	var tw := create_tween()
	for i in 8:
		tw.tween_property(self, "position", Vector2(randf_range(-amp, amp), randf_range(-amp, amp)), 0.04)
	tw.tween_property(self, "position", Vector2.ZERO, 0.04)

func _jackpot() -> void:
	for i in 10:
		_lamps_all(i % 2 == 0); await get_tree().create_timer(0.08).timeout
	_lamps_all(false)

func _process(delta: float) -> void:
	if not _win_cells.is_empty():
		_fx_time += delta
		fx.queue_redraw()

## 당첨 칸 테두리·반짝임을 코드로 그린다(정수 좌표, 도트 느낌).
func _draw_fx() -> void:
	if _win_cells.is_empty(): return
	if _dim:
		for r in 3:
			for c in 3:
				if not ([r, c] in _win_cells):
					fx.draw_rect(Rect2(c * CELL.x, r * CELL.y, CELL.x, CELL.y), Color(0, 0, 0, 0.5))
	var gold := Color(1.0, 0.82, 0.25)
	var pulse := int(_fx_time * 10.0) % 2 == 0
	var col := gold if pulse else Color(1, 1, 1)
	for cell in _win_cells:
		var x: float = cell[1] * CELL.x
		var y: float = cell[0] * CELL.y
		fx.draw_rect(Rect2(x, y, CELL.x, CELL.y), Color(col.r, col.g, col.b, 0.14 + (0.1 if pulse else 0.0)))
		var t := 2 if _fx_tier >= 4 else 1
		fx.draw_rect(Rect2(x, y, CELL.x, t), col); fx.draw_rect(Rect2(x, y + CELL.y - t, CELL.x, t), col)
		fx.draw_rect(Rect2(x, y, t, CELL.y), col); fx.draw_rect(Rect2(x + CELL.x - t, y, t, CELL.y), col)
		if _fx_tier >= 4:
			# 반짝이 점: 시간에 따라 칸 안에서 위치가 바뀜
			for k in 3:
				var sx := x + 6 + fmod(_fx_time * 37.0 + k * 19.0 + cell[0] * 11.0, CELL.x - 12)
				var sy := y + 5 + fmod(_fx_time * 23.0 + k * 13.0 + cell[1] * 7.0, CELL.y - 10)
				fx.draw_rect(Rect2(int(sx), int(sy), 2, 2), Color(1, 1, 0.8))
