## 슬롯 기계 한 대(본체+릴+레버+버튼 램프+당첨 연출). 이미지 생성 없이 코드로 연출한다.
## play(결과 3x3)만 부르면 레버 → 램프 → 릴 회전 → 정지 → 당첨 줄 연출까지 진행하고 finished 신호를 낸다.
class_name SlotMachine
extends Node2D

signal finished(info: Dictionary)
## 효과음 자리: 게임에서 이 이름에 소리를 연결한다. (lever, spin, reel_stop, win_0..win_6, jackpot, reveal)
signal sfx(name: String)
## 펫 등장 컷신 자리: 게임이 받아서 펫 연출을 재생한다. 끝나면 reveal_done()을 부른다.
signal reveal_requested(grade: int)

const A := "res://assets/slot/"
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
var top_fx: Control
var _parts: Array = []
## PixelLab 모션 프레임(이름 → 텍스처 9장)과 재생 중인 스프라이트 연출
var _fr := {}
var _sprs: Array = []
var _snd := {}
var _players: Array[AudioStreamPlayer] = []
var _bn_t := -1.0
var _rv_t := -1.0
var _rv_grade := 0
var _rv_skip := false
var rv: Control
## 픽셀 한글 폰트(Neo둥근모 v1.600, OFL). 16의 배수(16·32) 크기에서 또렷하다.
var _font: FontFile
## 펫 등장 컷신을 모듈 안에서 보여줄지(게임이 직접 하려면 false로 두고 reveal_requested만 받는다)
var show_reveal := true
## 등급별 펫 후보(0=D..6=SSS)와 이름, 등장 방식. 게임에서는 실제 뽑힌 펫 키를 reveal_pet에 넣는다.
const PETS := {
	0: ["d_chick", "d_frog", "d_mouse"], 1: ["c_mushroom", "c_puffbird", "c_slime"], 2: ["b_hamster", "b_hedgehog", "b_sparrow"],
	3: ["a_fennec", "a_otter", "a_owl"], 4: ["s_fairy", "s_tome", "s_wisp"], 5: ["ss_golem", "ss_knight", "ss_storm"],
	6: ["sss_apostle", "sss_demon", "sss_lunar", "sss_seraph"],
}
const PET_NAME := {
	"d_chick": "병아리", "d_frog": "개구리", "d_mouse": "생쥐", "c_mushroom": "버섯", "c_puffbird": "퍼프버드", "c_slime": "슬라임",
	"b_hamster": "햄스터", "b_hedgehog": "고슴도치", "b_sparrow": "참새", "a_fennec": "사막여우", "a_otter": "수달", "a_owl": "부엉이",
	"s_fairy": "요정", "s_tome": "마도서", "s_wisp": "촛불정령", "ss_golem": "골렘", "ss_knight": "기사",
	"ss_storm": "폭풍룡", "sss_apostle": "별의 사도", "sss_demon": "심연의 악마", "sss_lunar": "달의 여인", "sss_seraph": "세라핌",
}
## 등장 방식: drop 떨어져 튕김 / slam 쾅 내리꽂음(화면 흔들림) / hop 옆에서 점프 / rise 아래서 솟음 / float 위에서 천천히 / roll 옆에서 굴러옴
const PET_ENTRY := {
	"d_chick": "hop", "d_frog": "hop", "d_mouse": "roll", "c_mushroom": "drop", "c_puffbird": "float", "c_slime": "drop",
	"b_hamster": "hop", "b_hedgehog": "roll", "b_sparrow": "float", "a_fennec": "hop", "a_otter": "rise", "a_owl": "float",
	"s_fairy": "float", "s_tome": "rise", "s_wisp": "rise", "ss_golem": "slam", "ss_knight": "slam",
	"ss_storm": "roll", "sss_apostle": "rise", "sss_demon": "slam", "sss_lunar": "float", "sss_seraph": "float",
}
## 펫 속성별 연출 모티프와 색(밝은색, 포인트색). 한 점에서 퍼지는 빛줄기는 쓰지 않는다.
const THEME_COL := {
	"fire": [Color(1, 0.5, 0.15), Color(1, 0.85, 0.3)], "water": [Color(0.4, 0.8, 1.0), Color(0.8, 1, 1)],
	"nature": [Color(0.5, 0.9, 0.4), Color(0.9, 1, 0.6)], "air": [Color(0.9, 0.95, 1.0), Color(1, 1, 0.8)],
	"volt": [Color(0.6, 0.8, 1.0), Color(1, 1, 0.5)], "magic": [Color(0.8, 0.5, 1.0), Color(1, 0.9, 0.5)],
	"earth": [Color(0.75, 0.65, 0.5), Color(0.5, 0.95, 0.9)],
}
const PET_THEME := {
	"d_chick": "air", "d_frog": "water", "d_mouse": "earth", "c_mushroom": "nature", "c_puffbird": "air", "c_slime": "water",
	"b_hamster": "nature", "b_hedgehog": "nature", "b_sparrow": "air", "a_fennec": "earth", "a_otter": "water", "a_owl": "air",
	"s_fairy": "nature", "s_tome": "magic", "s_wisp": "fire", "ss_golem": "earth", "ss_knight": "magic",
	"ss_storm": "volt", "sss_apostle": "magic", "sss_demon": "fire", "sss_lunar": "magic", "sss_seraph": "air",
}
## 뽑기 결과로 보여줄 펫 키(비워 두면 해당 등급에서 무작위)
var reveal_pet := ""
var _rv_pet := ""
const REVEAL_COL := [Color(0.7, 0.7, 0.7), Color(0.4, 0.9, 0.4), Color(0.4, 0.7, 1.0), Color(0.8, 0.5, 1.0), Color(1.0, 0.85, 0.3), Color(1.0, 0.4, 0.6), Color(1, 1, 1)]
var _flash := 0.0
var _spot := 0.0
var _ring := -1.0
var _lever_tex := {}
var _lamp_off: Array[Texture2D] = []
var _lamp_on: Array[Texture2D] = []
var _win_cells: Array = []
var _cell_sym := {}
var _fx_time := 0.0
var _fx_tier := 0
var _dim := false
var _body: Sprite2D
var busy := false

static func _tex(name: String) -> Texture2D:
	return ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(A + name + ".png")))

func _ready() -> void:
	_font = load("res://assets/neodgm.ttf")
	_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	_font.hinting = TextServer.HINTING_NONE
	_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
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
	top_fx = Control.new()
	top_fx.size = Vector2(270, 420); top_fx.z_index = 30; top_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_fx.draw.connect(_draw_top)
	add_child(top_fx)
	for i in 5:
		_lamp_off.append(_tex("btn_off%d" % i)); _lamp_on.append(_tex("btn_on%d" % i))
		var l := Sprite2D.new()
		l.texture = _lamp_off[i]; l.position = Vector2(LAMP_X[i], LAMP_Y)
		add_child(l); lamps.append(l)
	for n in ["burst", "rainbow", "coin", "gem", "shim_S", "shim_SS", "shim_SSS"]:
		var arr: Array[Texture2D] = []
		for i in 9: arr.append(_tex("%s_%02d" % [n, i]))
		_fr[n] = arr
	for g in PETS:
		for k in PETS[g]:
			var parr: Array[Texture2D] = []
			for i in 9: parr.append(_tex("rv_%s_%02d" % [k, i]))
			_fr["rv_" + k] = parr
	_fr["banner"] = [_tex("banner")]
	var snames := ["lever", "spin", "reel_stop", "jackpot", "reveal"]
	for i in 7: snames.append("win_%d" % i)
	for n in snames:
		_snd[n] = load(A + "sfx/" + n + ".wav")
	for i in 6:
		var pl := AudioStreamPlayer.new(); add_child(pl); _players.append(pl)
	sfx.connect(_on_sfx)
	reels.reel_stopped.connect(func(c): sfx.emit("reel_stop"))
	rv = Control.new()
	rv.size = Vector2(270, 420); rv.z_index = 40; rv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rv.draw.connect(_draw_reveal)
	add_child(rv)
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
	_cell_sym.clear()
	for r in 3:
		for c in 3: _cell_sym[r * 3 + c] = grid[r][c]
	# 예고: 높은 등급일수록 마지막 릴을 더 뜸 들인다(결과는 이미 정해져 있음)
	reels.runtime = 1.0
	reels.reel_delay = 0.25 + (0.3 if top >= 4 else 0.0) + (0.4 if top >= 6 else 0.0)
	reels.crawl_last = top >= 4
	sfx.emit("lever")
	await _pull_lever()
	sfx.emit("spin")
	_start_lamp_chase()
	reels.spin(grid)
	await reels.spin_finished
	_stop_lamp_chase()
	await _win_show(info)
	busy = false
	finished.emit(info)

func skip() -> void:
	if reels.spinning: reels.skip()
	if _rv_t >= 0.0: _rv_skip = true

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

## 등급별 당첨 연출. 위 등급일수록 아래 층이 하나씩 더 쌓인다(누적).
##  D~C: 줄 테두리 + 램프  / B: 어두운 배경 + 심볼 팝  / A: 반짝 터짐 + 번쩍
##  S: 파티클 폭죽 + 작은 흔들림  / SS: 정적 → 흰 번쩍 + 금빛 비 + 큰 흔들림  / SSS: 스포트라이트 + 이중 번쩍 + 충격파 + 비 두 배
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
	sfx.emit("win_%d" % top)
	if top >= 5:
		# 정적: 램프를 끄고 화면을 잠깐 멈춘다
		_lamps_all(false)
		_spot = 1.0 if top >= 6 else 0.0
		fx.queue_redraw()
		await get_tree().create_timer(0.35).timeout
	if top >= 3: _flash = 0.25 + 0.15 * (top - 3)
	if top >= 6:
		_ring = 0.0
	if top >= 3: _burst(cells, [0, 0, 0, 6, 12, 18, 26][top])
	if top >= 3: _sprite_show(cells, top)
	if top >= 5: _rain([0, 0, 0, 0, 0, 40, 90][top])
	if top >= 4: _shake(top)
	var dur: float = [0.6, 0.8, 1.1, 1.3, 1.8, 2.3, 3.2][top]
	var blinks: int = [1, 2, 3, 4, 6, 8, 12][top]
	var step: float = dur / (blinks * 2)
	for b in blinks * 2:
		_lamps_all(b % 2 == 0)
		if top >= 6 and b == blinks:
			_flash = 0.7   # 두 번째 번쩍
		fx.queue_redraw()
		await get_tree().create_timer(step).timeout
	_lamps_all(false)
	if info.jackpot:
		sfx.emit("jackpot")
		_rain(60)
		await _jackpot()
	reveal_requested.emit(top)
	if show_reveal: await _reveal(top)
	_spot = 0.0; _ring = -1.0
	_dim = false
	fx.queue_redraw()

func _burst(cells: Array, per_cell: int) -> void:
	for cell in cells:
		var cx: float = WINDOW_POS.x + (cell[1] + 0.5) * CELL.x
		var cy: float = WINDOW_POS.y + (cell[0] + 0.5) * CELL.y
		for i in per_cell:
			var ang := randf() * TAU
			var sp := randf_range(30.0, 90.0)
			_parts.append({"p": Vector2(cx, cy), "v": Vector2(cos(ang), sin(ang)) * sp, "life": randf_range(0.5, 1.0), "g": 60.0, "c": [Color(1, 0.85, 0.3), Color(1, 1, 0.8), Color(1, 0.6, 0.2)][randi() % 3]})

func _rain(n: int) -> void:
	for i in n:
		_parts.append({"p": Vector2(randf_range(6, 264), randf_range(-40, 0)), "v": Vector2(randf_range(-8, 8), randf_range(50, 110)), "life": randf_range(1.2, 2.2), "g": 20.0, "c": [Color(1, 0.85, 0.3), Color(1, 0.95, 0.6)][randi() % 2]})

## PixelLab 모션: 칸마다 폭발, 위 등급일수록 창 한가운데 큰 폭발이 겹치고 보석·동전 비가 내린다.
func _sprite_show(cells: Array, top: int) -> void:
	var ctr := WINDOW_POS + Vector2(CELL.x * 1.5, CELL.y * 1.5)
	var kind := "rainbow" if top >= 5 else "burst"
	var sc: float = [0, 0, 0, 1, 1, 1, 2][top]
	for cell in cells:
		_anim(kind, WINDOW_POS + Vector2((cell[1] + 0.5) * CELL.x, (cell[0] + 0.5) * CELL.y), sc, 12.0, randf() * 0.15)
	if top >= 5: _ring = 0.0
	var n: int = [0, 0, 0, 0, 6, 14, 30][top]
	for i in n:
		_parts.append({"p": Vector2(randf_range(10, 260), randf_range(-60, -10)), "v": Vector2(randf_range(-10, 10), randf_range(60, 130)), "life": randf_range(1.5, 2.6), "g": 30.0, "c": Color.WHITE, "spr": "coin" if i % 2 == 0 else "gem", "ph": randi() % 9})

func _anim(name: String, pos: Vector2, sc: float, fps: float, delay := 0.0) -> void:
	_sprs.append({"n": name, "p": pos, "s": sc, "fps": fps, "t": -delay})

func _shake(top: int) -> void:
	var amp: float = [0, 0, 0, 0, 1.5, 2.5, 3.5][top]
	var tw := create_tween()
	for i in 8:
		tw.tween_property(self, "position", Vector2(randf_range(-amp, amp), randf_range(-amp, amp)), 0.04)
	tw.tween_property(self, "position", Vector2.ZERO, 0.04)

func _on_sfx(n: String) -> void:
	if not _snd.has(n): return
	for pl in _players:
		if not pl.playing:
			pl.stream = _snd[n]; pl.play(); return
	_players[0].stream = _snd[n]; _players[0].play()

## 전체 칸 잭팟: 리본 배너가 튀어나온다.
func _jackpot() -> void:
	_bn_t = 0.0
	for i in 10:
		_lamps_all(i % 2 == 0); await get_tree().create_timer(0.08).timeout
	_lamps_all(false)
	await get_tree().create_timer(1.2).timeout
	_bn_t = -1.0

## 펫 등장 컷신: 어두워지고 → 실루엣(등급 높을수록 길게 뜸 들임) → 번쩍 → 펫마다 다른 방식으로 등장.
func _reveal(top: int) -> void:
	_rv_grade = top; _rv_skip = false; _rv_t = 0.0
	_rv_pet = reveal_pet if reveal_pet != "" else PETS[top][randi() % PETS[top].size()]
	sfx.emit("reveal")
	var dur: float = _rv_start(top) + 1.0 + [1.0, 1.1, 1.2, 1.4, 1.7, 2.0, 2.4][top]
	while _rv_t < dur and not _rv_skip:
		await get_tree().process_frame
	_rv_t = -1.0
	rv.position = Vector2.ZERO
	rv.queue_redraw()

## 번쩍하며 펫이 나타나는 시각(초)
func _rv_start(top: int) -> float:
	return 0.35 + [0.0, 0.0, 0.3, 0.6, 0.9, 1.2, 1.6][top]

## 등장 방식별 위치 오프셋(t = 등장 시작 후 시간)
static func _entry(kind: String, t: float) -> Vector2:
	match kind:
		"drop":
			if t < 0.45: return Vector2(0, -230.0 * (1.0 - pow(t / 0.45, 2.0)))
			var u := t - 0.45
			return Vector2(0, -absf(sin(u * 11.0)) * 26.0 * exp(-u * 5.0))
		"slam":
			if t < 0.25: return Vector2(0, -260.0 * (1.0 - pow(t / 0.25, 2.0)))
			var u := t - 0.25
			return Vector2(0, -absf(sin(u * 14.0)) * 10.0 * exp(-u * 8.0))
		"hop":
			var k := minf(1.0, t / 0.7)
			return Vector2(-150.0 * (1.0 - k), -70.0 * sin(PI * k))
		"rise":
			return Vector2(0, 150.0 * pow(1.0 - minf(1.0, t / 0.6), 3.0))
		"float":
			var k := minf(1.0, t / 0.9)
			return Vector2(14.0 * sin(t * 5.0) * (1.0 - k), -140.0 * pow(1.0 - k, 3.0))
		"roll":
			return Vector2(170.0 * pow(1.0 - minf(1.0, t / 0.7), 2.0), 0)
	return Vector2.ZERO

func _process(delta: float) -> void:
	if not _win_cells.is_empty():
		_fx_time += delta
		fx.queue_redraw()
	var dirty := false
	if _bn_t >= 0.0:
		_bn_t += delta; dirty = true
	if _rv_t >= 0.0:
		_rv_t += delta; rv.queue_redraw()
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 1.6); dirty = true
	if _ring >= 0.0:
		_ring += delta * 150.0; dirty = true
	for sp in _sprs:
		sp.t += delta; dirty = true
	_sprs = _sprs.filter(func(q): return q.t * q.fps < 9.0)
	for pt in _parts:
		pt.life -= delta; pt.v.y += pt.g * delta; pt.p += pt.v * delta; dirty = true
	_parts = _parts.filter(func(q): return q.life > 0.0)
	if dirty or _spot > 0.0:
		top_fx.queue_redraw()

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
		var t := 2 if _fx_tier >= 3 else 1
		fx.draw_rect(Rect2(x, y, CELL.x, t), col); fx.draw_rect(Rect2(x, y + CELL.y - t, CELL.x, t), col)
		fx.draw_rect(Rect2(x, y, t, CELL.y), col); fx.draw_rect(Rect2(x + CELL.x - t, y, t, CELL.y), col)
		if _fx_tier >= 2:
			var sym: int = _cell_sym.get(cell[0] * 3 + cell[1], -1)
			if sym >= 0:
				var k := 1.0 + 0.16 * (0.5 + 0.5 * sin(_fx_time * 9.0))
				var tex: Texture2D = reels.symbols[sym]
				if sym >= 4:
					tex = _fr["shim_" + GRADES[sym]][int(_fx_time * 10.0) % 9]
				var sz := Vector2(tex.get_width(), tex.get_height()) * k
				fx.draw_texture_rect(tex, Rect2(Vector2(x + CELL.x * 0.5, y + CELL.y * 0.5) - sz * 0.5, sz), false)
		if _fx_tier >= 4:
			# 반짝이 점: 시간에 따라 칸 안에서 위치가 바뀜
			for k in 3:
				var sx := x + 6 + fmod(_fx_time * 37.0 + k * 19.0 + cell[0] * 11.0, CELL.x - 12)
				var sy := y + 5 + fmod(_fx_time * 23.0 + k * 13.0 + cell[1] * 7.0, CELL.y - 10)
				fx.draw_rect(Rect2(int(sx), int(sy), 2, 2), Color(1, 1, 0.8))

## 맨 위 층: 번쩍·스포트라이트·충격파·파티클
func _draw_top() -> void:
	if _bn_t >= 0.0:
		var bt: Texture2D = _fr["banner"][0]
		var k := maxf(0.05, minf(1.0, _bn_t / 0.25))
		var pop := 1.0 + 0.3 * sin(minf(1.0, _bn_t / 0.25) * PI)
		var sz := Vector2(bt.get_width(), bt.get_height()) * 1.4 * k * pop
		var c := Vector2(135, 190)
		top_fx.draw_texture_rect(bt, Rect2((c - sz * 0.5).round(), sz), false)
		var font: Font = _font
		var label := "JACKPOT"
		var fs := 32
		var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var lp := Vector2(135 - tw * 0.5, 190 + (40.0 - 37.0) * 1.4 + 2.0 + (font.get_ascent(fs) - font.get_descent(fs)) * 0.5)
		var tc := Color(1, 1, 0.8) if int(_bn_t * 10.0) % 2 == 0 else Color(1, 0.85, 0.3)
		if _bn_t >= 0.25:
			top_fx.draw_string_outline(font, lp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0.3, 0.05, 0.05))
			top_fx.draw_string(font, lp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, tc)
	if _spot > 0.0:
		var w := Rect2(WINDOW_POS, Vector2(CELL.x * 3, CELL.y * 3))
		var c := Color(0, 0, 0, 0.6)
		top_fx.draw_rect(Rect2(0, 0, 270, w.position.y), c)
		top_fx.draw_rect(Rect2(0, w.end.y, 270, 420 - w.end.y), c)
		top_fx.draw_rect(Rect2(0, w.position.y, w.position.x, w.size.y), c)
		top_fx.draw_rect(Rect2(w.end.x, w.position.y, 270 - w.end.x, w.size.y), c)
	if _ring >= 0.0:
		var ctr := WINDOW_POS + Vector2(CELL.x * 1.5, CELL.y * 1.5)
		var r := int(_ring)
		top_fx.draw_rect(Rect2(ctr.x - r, ctr.y - r * 0.8, r * 2, 2), Color(1, 0.9, 0.4, 0.8))
		top_fx.draw_rect(Rect2(ctr.x - r, ctr.y + r * 0.8, r * 2, 2), Color(1, 0.9, 0.4, 0.8))
		top_fx.draw_rect(Rect2(ctr.x - r, ctr.y - r * 0.8, 2, r * 1.6), Color(1, 0.9, 0.4, 0.8))
		top_fx.draw_rect(Rect2(ctr.x + r, ctr.y - r * 0.8, 2, r * 1.6), Color(1, 0.9, 0.4, 0.8))
	for sp in _sprs:
		if sp.t < 0.0: continue
		var ft: Texture2D = _fr[sp.n][mini(int(sp.t * sp.fps), 8)]
		var fs: Vector2 = Vector2(ft.get_width(), ft.get_height()) * float(sp.s)
		top_fx.draw_texture_rect(ft, Rect2((sp.p - fs * 0.5).round(), fs), false)
	for pt in _parts:
		if pt.has("spr"):
			var st: Texture2D = _fr[pt.spr][(pt.ph + int(pt.life * 12.0)) % 9]
			top_fx.draw_texture(st, (pt.p - Vector2(st.get_width(), st.get_height()) * 0.5).round())
			continue
		var a := clampf(pt.life * 2.0, 0.0, 1.0)
		var col: Color = pt.c
		top_fx.draw_rect(Rect2(int(pt.p.x), int(pt.p.y), 2, 2), Color(col.r, col.g, col.b, a))
	if _flash > 0.0:
		top_fx.draw_rect(Rect2(0, 0, 270, 420), Color(1, 1, 1, _flash))

func _draw_reveal() -> void:
	if _rv_t < 0.0: return
	var g := _rv_grade
	var col: Color = REVEAL_COL[g]
	var T0 := _rv_start(g)
	var t0 := _rv_t - T0            # 등장 시작 후 시간(음수면 실루엣 단계)
	var ctr := Vector2(135, 190)
	var kind: String = PET_ENTRY[_rv_pet]
	# 흔들림: 쾅 착지 순간 / 높은 등급은 등장 순간
	var amp := 0.0
	if kind == "slam" and t0 > 0.25 and t0 < 0.65: amp = 6.0 * (0.65 - t0) / 0.4
	if g >= 5 and t0 > 0.0 and t0 < 0.5: amp = maxf(amp, (2.0 + g - 5.0) * (0.5 - t0) / 0.5)
	rv.position = Vector2(randf_range(-amp, amp), randf_range(-amp, amp)) if amp > 0.0 else Vector2.ZERO
	var a := clampf(_rv_t / 0.35, 0.0, 1.0)
	rv.draw_rect(Rect2(-20, -20, 310, 460), Color(0, 0, 0, 0.85 * a))
	var theme: String = PET_THEME[_rv_pet]
	var tc: Array = THEME_COL[theme]
	var base: Color = tc[0]
	var feet := ctr + Vector2(0, 62)
	# 바닥 빛 웅덩이: 실루엣 동안 점점 밝아진다
	var glow := clampf((_rv_t - 0.2) / maxf(0.2, T0 - 0.2), 0.0, 1.0) if t0 < 0.0 else 1.0
	for i in 4:
		rv.draw_circle(ctr + Vector2(0, 8), 40.0 + g * 6.0 + i * 16.0 * (0.5 + glow), Color(base.r, base.g, base.b, (0.10 - i * 0.02) * (0.4 + glow)))
	# SSS: 오로라 커튼(세로 띠가 일렁임)
	if g >= 6:
		for i in 5:
			var cx := 25.0 + i * 55.0 + sin(_rv_t * 1.5 + i) * 10.0
			var hc := Color.from_hsv(fmod(0.45 + i * 0.12 + _rv_t * 0.1, 1.0), 0.55, 1.0)
			var ca := 0.28 * (0.3 + 0.7 * glow)
			rv.draw_polygon(PackedVector2Array([Vector2(cx - 18, 0), Vector2(cx + 18, 0), Vector2(cx + 24, 190), Vector2(cx + 30, 380), Vector2(cx - 30, 380), Vector2(cx - 24, 190)]), PackedColorArray([Color(hc.r, hc.g, hc.b, 0.0), Color(hc.r, hc.g, hc.b, 0.0), Color(hc.r, hc.g, hc.b, ca), Color(hc.r, hc.g, hc.b, 0.0), Color(hc.r, hc.g, hc.b, 0.0), Color(hc.r, hc.g, hc.b, ca)]))
	# B 이상: 바닥에서 퍼지는 물결 고리
	var vis := 0.3 + 0.7 * glow
	rv.draw_set_transform(feet, 0.0, Vector2(1.0, 0.35))
	if g >= 2:
		for k in 2:
			var ph := fmod(_rv_t * 0.9 + k * 0.5, 1.0)
			rv.draw_arc(Vector2.ZERO, 20.0 + ph * 90.0, 0.0, TAU, 40, Color(base.r, base.g, base.b, (1.0 - ph) * 0.6 * vis), 2.0)
	# A 이상: 발밑 마법진(고리+도는 점). 등급이 오를수록 고리와 점이 늘어난다
	if g >= 3:
		var rings := 1 + (1 if g >= 4 else 0) + (1 if g >= 5 else 0)
		for k in rings:
			var rad := 56.0 + k * 18.0
			rv.draw_arc(Vector2.ZERO, rad, 0.0, TAU, 48, Color(base.r, base.g, base.b, 0.8 * vis), 2.0)
			var dots := 8 + k * 4
			for d in dots:
				var an := TAU * d / dots + _rv_t * (1.0 if k % 2 == 0 else -1.0)
				rv.draw_rect(Rect2((Vector2(cos(an), sin(an)) * rad).round() - Vector2(1, 1), Vector2(3, 3)), Color(tc[1].r, tc[1].g, tc[1].b, vis))
		if g >= 4:
			var pts := PackedVector2Array()
			for d in 4: pts.append(Vector2(cos(TAU * d / 3.0 + _rv_t * 0.6), sin(TAU * d / 3.0 + _rv_t * 0.6)) * 56.0)
			rv.draw_polyline(pts, Color(tc[1].r, tc[1].g, tc[1].b, 0.7 * vis), 2.0)
	rv.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 위에서 내리꽂는 빛기둥: S부터
	if g >= 4:
		var pw := 10.0 + 26.0 * glow if t0 < 0.0 else maxf(0.0, 36.0 - t0 * 30.0)
		rv.draw_rect(Rect2(ctr.x - pw * 0.5, 0, pw, ctr.y + 30), Color(1, 1, 0.9, 0.25 + 0.2 * glow))
	# 펫
	var frames: Array = _fr["rv_" + _rv_pet]
	var ft: Texture2D = frames[int(maxf(t0, 0.0) * 10.0) % 9]
	var ps := maxi(2, int(130.0 / maxf(ft.get_width(), ft.get_height())))
	var sz := Vector2(ft.get_width(), ft.get_height()) * ps
	var off := Vector2.ZERO if t0 < 0.0 else _entry(kind, t0)
	var mod := Color(0, 0, 0, 1) if t0 < 0.0 else Color.WHITE
	if t0 < 0.0:
		off = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * (glow * (g - 1.0) * 0.8)   # 실루엣이 떨린다
	rv.draw_texture_rect(ft, Rect2((ctr + off - sz * 0.5).round(), sz), false, mod)
	# 속성별 입자: 불=솟는 불똥, 물=거품, 풀=낙엽, 바람=깃털, 번개=불꽃+번개줄, 마법=별빛, 바위=먼지. 등급이 높을수록 많다
	if t0 >= 0.0:
		_rv_particles(theme, tc, ctr, t0, g)
	# SS·SSS: 동전·보석 비
	if t0 >= 0.0 and g >= 5:
		for i in (5 if g == 5 else 12):
			var x := fmod(float(i) * 53.0, 250.0) + 10.0
			var y := fmod(t0 * (80.0 + (i % 4) * 20.0) + i * 47.0, 470.0) - 40.0
			var st: Texture2D = _fr["coin" if i % 2 == 0 else "gem"][(i + int(_rv_t * 12.0)) % 9]
			rv.draw_texture(st, Vector2(x, y).round())
	# 이름: 등급은 위 줄에 색 글자로, 펫 이름은 아래 줄(S 이상은 리본의 붉은 띠 가운데)에 쓴다
	if t0 >= 0.4:
		var la := clampf((t0 - 0.4) / 0.25, 0.0, 1.0)
		var font: Font = _font
		var gtxt: String = "%s 등급" % GRADES[g]
		var gw := font.get_string_size(gtxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		var gp := Vector2(135 - gw * 0.5, 268)
		rv.draw_string_outline(font, gp, gtxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 3, Color(0, 0, 0, la))
		rv.draw_string(font, gp, gtxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(col.r, col.g, col.b, la))
		var nm: String = PET_NAME[_rv_pet]
		var nfs := 32
		var ny := 300.0
		if g >= 4:
			var bt: Texture2D = _fr["banner"][0]
			rv.draw_texture_rect(bt, Rect2(Vector2(135 - 96, 276), Vector2(192, 74)), false, Color(1, 1, 1, la))
			nfs = 16
			ny = 276.0 + 42.0 + (font.get_ascent(nfs) - font.get_descent(nfs)) * 0.5   # 붉은 띠(배너 y 28~51)의 세로 가운데
		var nw := font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs).x
		var np := Vector2(135 - nw * 0.5, ny)
		rv.draw_string_outline(font, np, nm, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs, 2 if g >= 4 else 4, Color(0, 0, 0, la))
		rv.draw_string(font, np, nm, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs, Color(1, 1, 1, la))
	# 번쩍: 등장 순간(SSS는 두 번), SSS는 충격파 고리도
	var fl := clampf(1.0 - absf(t0) * (6.0 if t0 < 0.0 else 3.0), 0.0, 1.0) if absf(t0) < 0.4 else 0.0
	if g == 6 and t0 > 0.5 and t0 < 0.8: fl = maxf(fl, (0.8 - t0) * 2.0)
	if fl > 0.0: rv.draw_rect(Rect2(-20, -20, 310, 460), Color(1, 1, 1, fl))
	if g >= 5 and t0 > 0.0 and t0 < 1.0:
		var r := t0 * 300.0
		rv.draw_arc(ctr, r, 0.0, TAU, 48, Color(col.r, col.g, col.b, 1.0 - t0), 3.0)

func _rv_particles(theme: String, tc: Array, ctr: Vector2, t: float, g: int) -> void:
	var n := 6 + g * 5
	var c0: Color = tc[0]
	var c1: Color = tc[1]
	for i in n:
		var bx := fmod(float(i) * 61.3, 250.0) + 10.0
		var sp := 1.0 + float(i % 5) * 0.25
		match theme:
			"fire":
				var y := 340.0 - fmod(t * 70.0 * sp + i * 37.0, 300.0)
				rv.draw_rect(Rect2(Vector2(bx + sin(t * 3.0 + i) * 6.0, y).round(), Vector2(2, 3)), c0 if i % 2 == 0 else c1)
			"water":
				var y := 340.0 - fmod(t * 35.0 * sp + i * 41.0, 320.0)
				rv.draw_arc(Vector2(bx + sin(t * 2.0 + i) * 8.0, y).round(), 2.0 + float(i % 3), 0.0, TAU, 8, c0 if i % 2 == 0 else c1, 1.0)
			"nature":
				var y := fmod(t * 32.0 * sp + i * 43.0, 380.0) - 20.0
				rv.draw_rect(Rect2(Vector2(bx + sin(t * 2.0 + i) * 14.0, y).round(), Vector2(3, 2)), c0 if i % 2 == 0 else c1)
			"air":
				var y := fmod(t * 22.0 * sp + i * 47.0, 380.0) - 20.0
				rv.draw_rect(Rect2(Vector2(bx + sin(t * 1.6 + i) * 20.0, y).round(), Vector2(2, 5)), c0 if i % 2 == 0 else c1)
			"volt":
				var an := fmod(float(i) * 2.399 + floorf(t * 8.0) * 1.7, TAU)
				var rr := 50.0 + fmod(float(i) * 23.0, 80.0)
				rv.draw_rect(Rect2((ctr + Vector2(cos(an), sin(an)) * rr).round(), Vector2(2, 2)), c1)
			"magic":
				var y := 340.0 - fmod(t * 40.0 * sp + i * 39.0, 320.0)
				var tw := 1 + int(t * 6.0 + i) % 2
				var p := Vector2(bx, y).round()
				rv.draw_rect(Rect2(p - Vector2(tw, 0), Vector2(tw * 2 + 1, 1)), c1)
				rv.draw_rect(Rect2(p - Vector2(0, tw), Vector2(1, tw * 2 + 1)), c0)
			"earth":
				var y := 340.0 - fmod(t * 28.0 * sp + i * 37.0, 300.0)
				rv.draw_rect(Rect2(Vector2(bx + sin(t + i) * 5.0, y).round(), Vector2(2, 2)), c0 if i % 3 != 0 else c1)
	if theme == "volt" and g >= 2 and int(t * 5.0) % 2 == 0:
		var seed := int(t * 5.0)
		var pts := PackedVector2Array()
		var x := 135.0 + float((seed * 37) % 80 - 40)
		for k in 7:
			pts.append(Vector2(x + float((seed * 13 + k * 29) % 31 - 15) * (1.0 if k < 6 else 0.0), k * (ctr.y + 50.0) / 6.0))
		rv.draw_polyline(pts, c1, 2.0)
