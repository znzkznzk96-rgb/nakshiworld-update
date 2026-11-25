## 슬롯 기계 한 대(본체+릴+레버+버튼 램프+당첨 연출). 이미지 생성 없이 코드로 연출한다.
## play(결과 3x3)만 부르면 레버 → 램프 → 릴 회전 → 정지 → 당첨 줄 연출까지 진행하고 finished 신호를 낸다.
class_name SlotMachine
extends Node2D

signal finished(info: Dictionary)
## 효과음 자리: 게임에서 이 이름에 소리를 연결한다. (lever, spin, reel_stop, win_0..win_6, jackpot, reveal)
signal sfx(name: String)
## 펫 등장 컷신 자리: 게임이 받아서 펫 연출을 재생한다. 끝나면 reveal_done()을 부른다.
signal reveal_requested(grade: int)

const A := "res://art/pet_hut/slot/"
const GRADES := ["D", "C", "B", "A", "S", "SS", "SSS"]
## 8개 줄(행3·열3·대각2). 각 칸은 [행, 열]
const LINES := [
	[[0,0],[0,1],[0,2]], [[1,0],[1,1],[1,2]], [[2,0],[2,1],[2,2]],
	[[0,0],[1,0],[2,0]], [[0,1],[1,1],[2,1]], [[0,2],[1,2],[2,2]],
	[[0,0],[1,1],[2,2]], [[0,2],[1,1],[2,0]],
]
## 좌표 단위는 게임 화면 1칸(폰 화면 4픽셀). 본체·심볼은 그림 1픽셀이 폰 화면 3픽셀이 되도록 0.75배로 그린다.
const ART := 0.75
const BODY_POS := Vector2(31.5, 41.0)
const BODY_H := 297.75   # 몸통 그림 높이(397픽셀 × 0.75)
const WINDOW_POS := Vector2(66.75, 128.0)
const CELL := Vector2(46, 40)
const LAMP_X := [82.5, 108.75, 135.75, 162.75, 189.75]   # 본체에 그려진 버튼 자리 위에 빛 레이어를 겹친다
const LAMP_Y := 262.25
const LEVER_ART := 0.75
const LEVER_POS := Vector2(217.0, 158.0)   # 판 왼쪽 아래(그림 4,128)가 기계 오른쪽 옆면에 닿는 자리
## 레버 당김 프레임(PixelLab 그림 + 레퍼런스 움짤의 움직임): 0=올림, 6~8=끝까지 내림, 12=반동으로 올라감
const LEVER_DOWN := [1, 2, 3, 4, 5, 6]
const LEVER_UP := [9, 10, 11, 12, 13, 14, 0]

var reels: SlotReels
var lever: Sprite2D
var lamps: Array[Sprite2D] = []
var fx: Control
var top_fx: Control
var _parts: Array = []
## PixelLab 모션 프레임(이름 → 텍스처 9장)과 재생 중인 스프라이트 연출
var _fr := {}
var _sprs: Array = []
## 한 장짜리 그림을 키우며 흐려지는 짧은 효과(충격 스파크·먼지·균열)
var _pops: Array = []
func _pop(n: String, pos: Vector2, s0: float, s1: float, dur: float, delay := 0.0, col := Color.WHITE, in_rv := false) -> void:
	_pops.append({"n": n, "p": pos, "s0": s0, "s1": s1, "d": dur, "t": -delay, "c": col, "rv": in_rv})
var _snd := {}
var _players: Array[AudioStreamPlayer] = []
var _bn_t := -1.0
var _rv_t := -1.0
var _rv_grade := 0
var _rv_skip := false
var _rv_burst := false
var _rv_wait := false
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
## 뽑기 결과로 보여줄 펫 키(비워 두면 해당 등급에서 무작위)
var reveal_pet := ""
## 등장 후 천천히 두 바퀴 돌고 정면에서 멈추는 시간(초). 옆모습에 두께를 줘서 만든 16방향 시트(pets/*_spin.png)를 쓴다.
const SPIN_T := 4.0
var _spin := {}
var _rv_pet := ""
## 펫마다 PixelLab으로 만든 오라 시트(가로 9칸). 등장 연출은 이 그림만 쓴다.
var _aura := {}
const REVEAL_COL := [Color(0.7, 0.7, 0.7), Color(0.4, 0.9, 0.4), Color(0.4, 0.7, 1.0), Color(0.8, 0.5, 1.0), Color(1.0, 0.85, 0.3), Color(1.0, 0.4, 0.6), Color(1, 1, 1)]
var _flash := 0.0
var _spot := 0.0
var _ring := -1.0
var _lever_tex := {}
var _base_y := 0.0
var _lamp_off: Array[Texture2D] = []
var _lamp_on: Array[Texture2D] = []
var _win_cells: Array = []
var _cell_sym := {}
var _fx_time := 0.0
var _fx_tier := 0
var _dim := false
var _body: Sprite2D
var busy := false

# 글자는 호스트(게임)의 글자 층으로 보내 폰 해상도로 그린다. 이 모듈 안에서 그리면 작은 화면을 확대해 흐려진다.
var _tx_top: Array = []
var _tx_rv: Array = []
var _holder_pos := Vector2.ZERO
func _put_text(ci: CanvasItem, font: Font, pos: Vector2, text: String, fs: int, col: Color, ol := 0, ol_col := Color.BLACK) -> void:
	var list: Array = _tx_top if ci == top_fx else _tx_rv
	var at: Vector2 = pos + ci.position
	if ol > 0:
		var d := maxf(1.0, ol * 0.5)
		for o in [Vector2(-d, 0), Vector2(d, 0), Vector2(0, -d), Vector2(0, d), Vector2(-d, -d), Vector2(d, -d), Vector2(-d, d), Vector2(d, d)]:
			list.append([font, at + o, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, ol_col, 1.0])
	list.append([font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fs, col, 1.0])

## 호스트가 글자 층에 올릴 이번 화면 글자(기계 안쪽 좌표 → origin은 기계 위치)
func texts() -> Array:
	var out: Array = []
	if _bn_t >= 0.25: out.append_array(_tx_top)
	if _rv_t >= 0.0: out.append_array(_tx_rv)
	return out

static func _tex(name: String) -> Texture2D:
	return ImageTexture.create_from_image((load(A + name + ".png") as Texture2D).get_image())   # 폰(APK)에는 원본 PNG가 없어 load()로 읽는다

func _ready() -> void:
	_base_y = position.y
	_font = load("res://font/neodgm.ttf").duplicate(true)
	_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	_font.hinting = TextServer.HINTING_NONE
	_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	_font.oversampling = 1.0
	_font.fallbacks = [load("res://font/galmuri11.fnt")]
	_body = Sprite2D.new()
	_body.texture = _tex("body_empty"); _body.centered = false; _body.position = BODY_POS; _body.scale = Vector2(ART, ART)
	add_child(_body)
	reels = SlotReels.new()
	var syms: Array[Texture2D] = []
	for g in GRADES:
		syms.append(_tex("sym_" + g))
	reels.symbols = syms
	reels.cell_size = CELL
	reels.symbol_scale = ART
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
		l.texture = _lamp_off[i]; l.position = Vector2(LAMP_X[i], LAMP_Y); l.scale = Vector2(ART, ART)
		add_child(l); lamps.append(l)
	for n in ["spark", "dust", "crack"]:
		_fr[n] = [_tex(n)]
	for n in ["burst", "rainbow", "coin", "gem", "shim_S", "shim_SS", "shim_SSS"]:
		var arr: Array[Texture2D] = []
		for i in 9: arr.append(_tex("%s_%02d" % [n, i]))
		_fr[n] = arr
	for g in PETS:
		for k in PETS[g]:
			var parr: Array[Texture2D] = []
			for i in 9: parr.append(_tex("rv_%s_%02d" % [k, i]))
			_fr["rv_" + k] = parr
			_aura[k] = load("res://art/pet_hut/pets/%s_fx_rv.png" % k)
			_spin[k] = load("res://art/pet_hut/pets/%s_spin.png" % k)
	_fr["banner"] = [_tex("banner")]
	var snames := ["lever", "spin", "reel_stop", "jackpot", "reveal"]
	for i in 7: snames.append("win_%d" % i)
	for n in snames:
		_snd[n] = load(A + "sfx/" + n + ".wav")
	for i in 6:
		var pl := AudioStreamPlayer.new(); add_child(pl); _players.append(pl)
	sfx.connect(_on_sfx)
	reels.reel_stopped.connect(_on_reel_stop)
	reels.tension.connect(_on_tension)
	reels.fake_stopped.connect(_on_fake_stopped)
	reels.fake_flip.connect(_on_fake_flip)
	rv = Control.new()
	rv.size = Vector2(270, 420); rv.z_index = 40; rv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rv.draw.connect(_draw_reveal)
	add_child(rv)
	for i in 17:
		_lever_tex[i] = _tex("lever_pull_%02d" % i)
	lever = Sprite2D.new()
	lever.texture = _lever_tex[0]; lever.centered = false; lever.scale = Vector2(LEVER_ART, LEVER_ART)
	lever.position = LEVER_POS
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
	# 예고: 등급별로 멈추는 템포가 다르다(결과는 이미 정해져 있고, 아래는 보여주는 방식만 바꾼다)
	_can_skip = top <= 2
	_pending_top = top
	reels.runtime = [1.5, 1.7, 2.0, 2.4, 3.0, 3.4, 3.4][maxi(top, 0)]
	reels.speed = 8.0   # 평균 칸/초. 시작은 약 3배로 아주 빠르고 끝으로 갈수록 느려진다
	reels.reel_delay = [0.18, 0.22, 0.25, 0.25, 0.55, 0.55, 0.95][maxi(top, 0)]
	reels.crawl_last = false
	reels.last_mode = _pick_mode(top)
	_mode = reels.last_mode
	# 불빛 예고: 고등급은 대체로, 낮은 등급도 가끔 섞어서 패턴이 읽히지 않게 한다
	_tease_lamps = false
	_tease_pending = (randf() < 0.75) if top >= 3 else (randf() < 0.1)
	var fake_col: Array = []
	if _mode == "fake":
		for r in 3:
			fake_col.append((grid[r][2] + 1 + randi() % (reels.symbols.size() - 1)) % reels.symbols.size())
	_lamp_hold = [false, false, false, false, false]
	await _prime_lamps()
	sfx.emit("lever")
	await _pull_lever()
	sfx.emit("spin")
	_start_lamp_chase()
	reels.spin(grid, fake_col)
	_release_lever()
	await reels.spin_finished
	_stop_lamp_chase()
	await _win_show(info)
	busy = false
	finished.emit(info)

func skip() -> void:
	if reels.spinning and _can_skip: reels.skip()
	if _rv_t >= 0.0 and (_rv_grade <= 3 or _rv_t > _rv_start(_rv_grade) + 1.0): _rv_skip = true   # 자주 나오는 등급만 바로 넘긴다

var _can_skip := true
var _pending_top := -1
var _mode := ""
var _tease_lamps := false
var _tease_pending := false

## 마지막 릴 멈춤 방식. 같은 등급이어도 가끔 다르게 섞어서 패턴을 읽을 수 없게 한다.
func _pick_mode(top: int) -> String:
	match top:
		6: return "fake"
		5: return "over"
		4: return "tease" if randf() < 0.15 else "edge"
		3: return "tease" if randf() < 0.6 else "slight"
		2: return "slight"
	return "tease" if randf() < 0.12 else ""

func _play(n: String, pitch := 1.0) -> void:
	if not _snd.has(n): return
	for pl in _players:
		if not pl.playing:
			pl.pitch_scale = pitch; pl.stream = _snd[n]; pl.play(); return
	_players[0].pitch_scale = pitch; _players[0].stream = _snd[n]; _players[0].play()

## 마지막 릴 직전 뜸: 낮은 등급은 불빛만, 높은 등급은 어두워지고 번쩍하며 흔들린다
func _on_tension(mode: String) -> void:
	if _mode_top() >= 4:
		_dim = true
		_flash = 0.25
		_shake(_mode_top())
		_play("reel_stop", 0.7)
	fx.queue_redraw()

## 릴이 쿵 하고 멈추는 자리: 먼지, 마지막 릴이 고등급이면 충격 스파크도
func _land_fx(c: int) -> void:
	var base := WINDOW_POS + Vector2((c + 0.5) * CELL.x, CELL.y * 3.0 - 3.0)
	_pop("dust", base + Vector2(-12, 0), 0.5, 1.0, 0.35)
	_pop("dust", base + Vector2(12, 0), 0.5, 1.0, 0.35, 0.03)
	if c == 2 and _pending_top >= 3:
		var big := 1.6 + 0.5 * (_pending_top - 3)
		var mid := WINDOW_POS + Vector2(CELL.x * 2.5, CELL.y * 1.5)
		_pop("spark", mid, 0.8, big * 1.5, 0.5)
		for k in 3:
			var off := Vector2(randf_range(-1.0, 1.0) * CELL.x * 0.9, randf_range(-1.0, 1.0) * CELL.y * 1.3)
			_pop("spark", mid + off, 0.5, big, 0.4, 0.06 * (k + 1))

func _mode_top() -> int:
	return {"over": 5, "edge": 4}.get(_mode, 3)

## 가짜 멈춤: 평범하게 선 것처럼 낮은 소리 → 불빛이 꺼지고 정적 → 번쩍·흔들림과 함께 진짜 결과가 내려온다
func _on_fake_stopped() -> void:
	_play("reel_stop", 0.8)
	_stop_lamp_chase(); _tease_lamps = false
	_lamps_all(false)

func _on_fake_flip() -> void:
	_dim = true; _flash = 0.8
	_pop("crack", WINDOW_POS + Vector2(CELL.x * 1.5, CELL.y * 1.5), 1.0, 3.2, 0.7)
	_shake(6)
	_play("win_5", 1.2)
	fx.queue_redraw()

## 시작 전 예열: 버튼 램프가 왼쪽부터 차례로 켜졌다가 레버를 당긴다
func _prime_lamps() -> void:
	for i in 5:
		lamps[i].texture = _lamp_on[i]; await get_tree().create_timer(0.07).timeout
	await get_tree().create_timer(0.1).timeout
	_lamps_all(false)

## 레버를 끝까지 내린 순간 릴이 돌기 시작한다(올라오는 건 따로 진행)
func _pull_lever() -> void:
	for f in LEVER_DOWN:
		lever.texture = _lever_tex[f]
		await get_tree().create_timer(0.04).timeout

func _release_lever() -> void:
	for f in LEVER_UP:
		lever.texture = _lever_tex[f]; await get_tree().create_timer(0.06).timeout

## 대기 중 버튼 불빛이 제멋대로 반짝인다
var _tw_t := [0.3, 0.9, 0.5, 1.2, 0.7]
func _twinkle(delta: float) -> void:
	for i in 5:
		_tw_t[i] -= delta
		if _tw_t[i] <= 0.0:
			var on: bool = lamps[i].texture != _lamp_on[i]
			lamps[i].texture = _lamp_on[i] if on else _lamp_off[i]
			_tw_t[i] = randf_range(0.12, 0.5) if on else randf_range(0.4, 1.8)

## 릴이 멈출 때마다: 그 릴의 램프가 켜진 채 고정되고 기계가 살짝 쿵 한다
const LAMP_GROUP := [[0, 1], [2], [3, 4]]
var _lamp_hold := [false, false, false, false, false]
func _on_reel_stop(c: int) -> void:
	_play("reel_stop", 1.0 + 0.18 * c)   # 멈출 때마다 음이 올라간다
	if c == 1 and _tease_pending: _tease_lamps = true
	_land_fx(c)
	for i in LAMP_GROUP[c]:
		_lamp_hold[i] = true; lamps[i].texture = _lamp_on[i]
	var tw := create_tween()
	tw.tween_property(self, "position:y", _base_y + 1.0, 0.04)
	tw.tween_property(self, "position:y", _base_y, 0.08)

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
		if _tease_lamps:
			_lamps_all(k % 2 == 0); k += 1
			await get_tree().create_timer(0.04).timeout
			continue
		var free: Array = []
		for i in 5:
			if not _lamp_hold[i]: free.append(i)
		for i in 5:
			var lit: bool = _lamp_hold[i] or (not free.is_empty() and i == free[k % free.size()])
			lamps[i].texture = _lamp_on[i] if lit else _lamp_off[i]
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
	_play(n)

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
	_rv_grade = top; _rv_skip = false; _rv_t = 0.0; _rv_burst = false
	_rv_pet = reveal_pet if reveal_pet != "" else PETS[top][randi() % PETS[top].size()]
	sfx.emit("reveal")
	var dur: float = _rv_start(top) + 1.0 + SPIN_T + [1.0, 1.1, 1.2, 1.4, 1.7, 2.0, 2.4][top]
	while _rv_t < dur and not _rv_skip:
		await get_tree().process_frame
	# 정해진 연출이 끝나면 "눌러서 계속"을 띄우고, 누를 때까지 펫을 계속 보여준다(스크린샷용)
	_rv_wait = not _rv_skip
	while not _rv_skip:
		await get_tree().process_frame
	_rv_wait = false
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
	if not busy: _twinkle(delta)
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
	for pp in _pops:
		pp.t += delta; dirty = true
	_pops = _pops.filter(func(q): return q.t < q.d)
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
	_tx_top = []
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
			_put_text(top_fx, font, lp, label, fs, tc, 4, Color(0.3, 0.05, 0.05))
	if _spot > 0.0:
		var w := Rect2(WINDOW_POS, Vector2(CELL.x * 3, CELL.y * 3))
		var c := Color(0, 0, 0, 0.6)
		top_fx.draw_rect(Rect2(0, 0, 270, w.position.y), c)
		top_fx.draw_rect(Rect2(0, w.end.y, 270, 420 - w.end.y), c)
		top_fx.draw_rect(Rect2(0, w.position.y, w.position.x, w.size.y), c)
		top_fx.draw_rect(Rect2(w.end.x, w.position.y, 270 - w.end.x, w.size.y), c)
	if _ring >= 0.0:
		var ctr := WINDOW_POS + Vector2(CELL.x * 1.5, CELL.y * 1.5)
		var r := float(int(_ring))
		var ra := clampf(1.0 - r / 200.0, 0.0, 1.0)
		top_fx.draw_arc(ctr, r, 0.0, TAU, 64, Color(1, 0.9, 0.4, 0.85 * ra), 3.0)
		top_fx.draw_arc(ctr, r * 0.8, 0.0, TAU, 64, Color(1, 1, 1, 0.6 * ra), 1.5)
	for sp in _sprs:
		if sp.t < 0.0: continue
		var ft: Texture2D = _fr[sp.n][mini(int(sp.t * sp.fps), 8)]
		var fs: Vector2 = Vector2(ft.get_width(), ft.get_height()) * float(sp.s)
		top_fx.draw_texture_rect(ft, Rect2((sp.p - fs * 0.5).round(), fs), false)
	_draw_pops(top_fx, false)
	for pt in _parts:
		if pt.has("spr"):
			var st: Texture2D = _fr[pt.spr][(pt.ph + int(pt.life * 12.0)) % 9]
			top_fx.draw_texture(st, (pt.p - Vector2(st.get_width(), st.get_height()) * 0.5).round())
			continue
		var a := clampf(pt.life * 2.0, 0.0, 1.0)
		var col: Color = pt.c
		top_fx.draw_rect(Rect2(int(pt.p.x), int(pt.p.y), 2, 2), Color(col.r, col.g, col.b, a))
	if _flash > 0.0:
		top_fx.draw_rect(Rect2(-300, -400, 900, 1500), Color(1, 1, 1, _flash))

## 작은 펫이 주인공으로 보이도록 뒤에 까는 등급색 후광·빛줄기·받침대·파동
func _draw_backdrop(c: Vector2, sz: Vector2, col: Color, g: int, t0: float) -> void:
	var fade := clampf(t0 / 0.3, 0.0, 1.0)
	var R := 42.0 + 9.0 * g
	if g >= 3:
		var n := 6 + 2 * g
		for i in n:
			var an := TAU * i / n + t0 * 0.4
			var w := 0.025 + 0.004 * g
			var p0 := c
			rv.draw_colored_polygon(PackedVector2Array([p0, c + Vector2(cos(an - w), sin(an - w)) * R * 2.6, c + Vector2(cos(an + w), sin(an + w)) * R * 2.6]), Color(col.r, col.g, col.b, 0.2 * fade))
	for k in 5:
		var r := R * (1.0 - 0.17 * k) * (1.0 + 0.03 * sin(t0 * 5.0 + k))
		rv.draw_circle(c, r, Color(col.r, col.g, col.b, 0.07 * fade))
	var py := c.y + sz.y * 0.5 + 6.0
	rv.draw_colored_polygon(_ellipse(Vector2(c.x, py), sz.x * 0.55 + 8.0, 6.0), Color(0, 0, 0, 0.55 * fade))
	rv.draw_colored_polygon(_ellipse(Vector2(c.x, py), sz.x * 0.42 + 4.0, 4.0), Color(col.r, col.g, col.b, 0.5 * fade))
	if t0 < 0.9:
		var k := t0 / 0.9
		rv.draw_arc(c, 20.0 + 150.0 * k, 0.0, TAU, 64, Color(col.r, col.g, col.b, 0.8 * (1.0 - k)), 3.0)

func _draw_pops(layer: Control, in_rv: bool) -> void:
	for pp in _pops:
		if pp.t < 0.0 or pp.rv != in_rv: continue
		var k: float = pp.t / pp.d
		var pt_tex: Texture2D = _fr[pp.n][0]
		var sc: float = lerpf(pp.s0, pp.s1, 1.0 - pow(1.0 - k, 2.0))
		var psz := Vector2(pt_tex.get_width(), pt_tex.get_height()) * sc
		var c: Color = pp.c
		layer.draw_texture_rect(pt_tex, Rect2((pp.p - psz * 0.5).round(), psz), false, Color(c.r, c.g, c.b, clampf(2.0 * (1.0 - k), 0.0, 1.0)))

## 등장 순간 한 번: 등급별 스파크. C 작게 → B 파란 별 → A 보라 별 여러 개(색은 등급색으로 물들인다)
func _rv_burst_fx(g: int, c: Vector2, col: Color) -> void:
	if g < 1 or g > 3: return
	var n: int = [0, 2, 4, 7][g]
	var big: float = [0.0, 0.7, 1.1, 1.5][g]
	var tint := Color(lerpf(1.0, col.r, 0.55), lerpf(1.0, col.g, 0.55), lerpf(1.0, col.b, 0.55))
	_pop("spark", c, big * 0.6, big * 1.6, 0.45, 0.0, tint, true)
	for k in n:
		var an := TAU * k / n + randf() * 0.5
		var d := randf_range(26.0, 52.0)
		_pop("spark", c + Vector2(cos(an), sin(an)) * d, big * 0.4, big, 0.4, 0.05 * k, tint, true)

func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 24: pts.append(c + Vector2(cos(TAU * i / 24.0) * rx, sin(TAU * i / 24.0) * ry))
	return pts

func _draw_reveal() -> void:
	_tx_rv = []
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
	if g in [2, 3] and t0 > 0.0 and t0 < 0.3: amp = maxf(amp, (g - 1.0) * (0.3 - t0) / 0.3)   # B·A는 가볍게 흔들린다
	rv.position = Vector2(randf_range(-amp, amp), randf_range(-amp, amp)) if amp > 0.0 else Vector2.ZERO
	var a := clampf(_rv_t / 0.35, 0.0, 1.0)
	rv.draw_rect(Rect2(-300, -400, 900, 1500), Color(0, 0, 0, 0.75 * a))
	# 실루엣 동안 점점 밝아지는 정도(실루엣 떨림에만 쓴다)
	var glow := clampf((_rv_t - 0.2) / maxf(0.2, T0 - 0.2), 0.0, 1.0) if t0 < 0.0 else 1.0
	# 펫
	var frames: Array = _fr["rv_" + _rv_pet]
	var ft: Texture2D = frames[int(maxf(t0, 0.0) * 10.0) % 9]
	var pop := 1.0 + 2.0 * pow(1.0 - clampf(t0 / 0.55, 0.0, 1.0), 2.0) if t0 >= 0.0 else 1.0   # 나올 때 크게 확대됐다가 원래 크기로 줄어든다
	var ps := maxf(2.0, roundf(2.0 * pop))   # 도트가 깨지지 않게 정수 배율만 쓴다(원래 2배 → 등장할 때 6배까지)
	var sz := Vector2(ft.get_width(), ft.get_height()) * ps
	var spinning := t0 >= 0.0 and t0 < SPIN_T
	var off := Vector2.ZERO if t0 < 0.0 else _entry(kind, t0)
	var mod := Color(0, 0, 0, 1) if t0 < 0.0 else Color.WHITE
	if t0 < 0.0:
		off = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * (glow * (g - 1.0) * 0.8)   # 실루엣이 떨린다
	if t0 >= 0.0:
		_draw_backdrop(ctr + off, sz, col, g, t0)
	if t0 >= SPIN_T:
		var at: Texture2D = _aura[_rv_pet]
		var af := at.get_height()
		var ai := int(t0 * 10.0) % 9
		rv.draw_texture_rect_region(at, Rect2((ctr + off - Vector2(af, af) * ps * 0.5).round(), Vector2(af, af) * ps), Rect2(ai * af, 0, af, af))
	if t0 >= 0.0 and not _rv_burst:
		_rv_burst = true; _rv_burst_fx(g, ctr, col)
	if spinning:
		var sp: Texture2D = _spin[_rv_pet]
		var sc := sp.get_height()
		var u := t0 / SPIN_T
		var si := int(fposmod(2.0 * (1.0 - (1.0 - u) * (1.0 - u)), 1.0) * 16.0) % 16   # 2바퀴, 갈수록 느려져 정면에서 멈춘다
		rv.draw_texture_rect_region(sp, Rect2((ctr + off - Vector2(sc, sc) * ps * 0.5).round(), Vector2(sc, sc) * ps), Rect2(si * sc, 0, sc, sc), mod)
	else:
		rv.draw_texture_rect(ft, Rect2((ctr + off - sz * 0.5).round(), sz), false, mod)
	_draw_pops(rv, true)
	# SS·SSS: 동전·보석 비
	if t0 >= 0.0 and g >= 1:
		for i in int([0, 3, 6, 9, 10, 14, 18][g]):
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
		_put_text(rv, font, gp, gtxt, 16, Color(col.r, col.g, col.b, la), 3, Color(0, 0, 0, la))
		var nm: String = PET_NAME[_rv_pet]
		var nfs := 32
		var ny := 300.0
		if g >= 3:
			var bt: Texture2D = _fr["banner"][0]
			rv.draw_texture_rect(bt, Rect2(Vector2(135 - 96, 276), Vector2(192, 74)), false, Color(1, 1, 1, la))
			nfs = 16
			ny = 276.0 + 42.0 + (font.get_ascent(nfs) - font.get_descent(nfs)) * 0.5   # 붉은 띠(배너 y 28~51)의 세로 가운데
		var nw := font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs).x
		var np := Vector2(135 - nw * 0.5, ny)
		_put_text(rv, font, np, nm, nfs, Color(1, 1, 1, la), 2 if g >= 4 else 4, Color(0, 0, 0, la))
	if _rv_wait:
		var ha := 0.45 + 0.4 * sin(_rv_t * 4.0)
		var htxt := "화면을 눌러 계속"
		var hw := _font.get_string_size(htxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		_put_text(rv, _font, Vector2(135 - hw * 0.5, 392), htxt, 12, Color(1, 1, 1, ha), 2, Color(0, 0, 0, ha))
	# 번쩍: 등장 순간(SSS는 두 번)
	var fl := clampf(1.0 - absf(t0) * (6.0 if t0 < 0.0 else 3.0), 0.0, 1.0) if absf(t0) < 0.4 else 0.0
	if g == 6 and t0 > 0.5 and t0 < 0.8: fl = maxf(fl, (0.8 - t0) * 2.0)
	if fl > 0.0: rv.draw_rect(Rect2(-300, -400, 900, 1500), Color(1, 1, 1, fl))
