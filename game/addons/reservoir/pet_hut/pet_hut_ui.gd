class_name PetHutUI
extends Control
# 펫 오두막 창: 기존 상점 틀(panel/header/teal/card)과 같은 구성. 탭 3개.
signal closed
signal pearls_collected(n: int)
signal state_changed        # 펫·진주·조각이 바뀔 때마다(저장용)
const PETS := ["d_chick", "d_frog", "d_mouse", "c_mushroom", "c_puffbird", "c_slime", "b_hamster", "b_hedgehog", "b_sparrow", "a_fennec", "a_otter", "a_owl", "s_fairy", "s_tome", "s_wisp", "ss_golem", "ss_knight", "ss_storm", "sss_apostle", "sss_demon", "sss_lunar", "sss_seraph"]
const NAME := {"d_chick": "병아리", "d_frog": "개구리", "d_mouse": "생쥐", "c_mushroom": "버섯", "c_puffbird": "퍼프버드", "c_slime": "슬라임", "b_hamster": "햄스터", "b_hedgehog": "고슴도치", "b_sparrow": "참새", "a_fennec": "사막여우", "a_otter": "수달", "a_owl": "부엉이", "s_fairy": "요정", "s_tome": "마도서", "s_wisp": "촛불정령", "ss_golem": "골렘", "ss_knight": "기사", "ss_storm": "폭풍룡", "sss_apostle": "별의 사도", "sss_demon": "심연의 악마", "sss_lunar": "달의 여인", "sss_seraph": "세라핌"}
const SHORT := {"sss_apostle": "사도", "sss_demon": "악마", "sss_lunar": "여인", "c_puffbird": "퍼프", "b_hedgehog": "고슴", "a_fennec": "여우", "s_wisp": "정령"}   # 선택 칸용 줄임 이름(3글자 이하)
const GRADE_NAME := ["D", "C", "B", "A", "S", "SS", "SSS"]
const RATE := [0.1, 0.2, 0.35, 0.6, 1.0, 1.6, 2.5]   # 시간당 진주
const CAP_HOURS := 12.0
const WALK_X0 := 44.0   # 모래바닥 좌우 끝 (양옆 바위 안쪽)
const WALK_X1 := 188.0
const FLYERS := ["a_owl", "s_fairy", "s_tome", "s_wisp", "ss_storm", "sss_lunar", "sss_seraph"]
const SCENE := Vector2(230, 128)
## 창 높이(예전 380에서 세로로 늘림)
const PH := 440.0
const TABS := [["pets", "내 펫"], ["box", "보관함"], ["gacha", "뽑기"], ["plans", "도면"]]
const INK := Color("382619")
const CREAM := Color("fff0d1")
const MUTED := Color("5a4130")
const A := "res://art/pet_hut/"
const FRAG := [1, 3, 8, 20, 60, 200, 600]          # 분해로 얻는 조각(등급별)
const BP_COST := {3: [150, 50], 4: [450, 100], 5: [1200, 200], 6: [2100, 300]}   # 도면 제작: 조각, 진주
const COST := 10                                   # 슬롯 1회 진주
const COST10 := COST * 10                          # 10회 진주(할인 없음)
const GRADE_COL := [Color("8a7a66"), Color("4f9a5b"), Color("3f78c4"), Color("8a54c4"), Color("e08a2a"), Color("d6453d"), Color("e0b020")]
const GRADE_P := [71.3, 13.0, 8.0, 5.0, 2.0, 0.5, 0.2]   # 등급별 확률(%), 합 100
var tab := "pets"
var owned: Array = []          # 가진 펫(counts 1 이상), PETS 순서
var counts := {}               # 펫별 보유 수
var equipped: Array = []
var stored := 0.0
var pearl_total := 0
var _dust: Array = []
var time_scale := 1.0          # 시험용: 시간 가속
var picker := -1               # 펫 고르는 슬롯 번호, -1이면 닫힘
var _pets: Array = []
var _fx: Array = []
var _clock := 0.0
var _rng := RandomNumberGenerator.new()
var rects := {}
var _tex := {}
var _font: FontFile
var last_pet := ""
var frags := 0
var plan_sel := "a_fennec"     # 도면 상점에서 고른 펫
var box_sel := ""
## 일괄·자동 분해 범위(이 등급 이하만, S 이상은 항상 제외)와 자동 분해 켜짐 여부
var bulk_grade := 1
var auto_on := false
var _bulk_arm := -100.0
var _auto_frag := 0   # 방금 뽑기에서 자동 분해로 얻은 조각
var _auto_n := 0
var dim_margin := 0.0          # 어둡게 할 때 좌우로 더 덮을 폭(레터박스)
var dim := true                # 뒤 화면을 어둡게
var panel_y := -1.0            # 창 윗변 위치(-1이면 화면 가운데)
var leader := ""               # 대표 펫(장착 중인 펫 중 하나)
var box_msg := ""
var dis_sel := ""
var plan_msg := ""
var last_new := false
var show_odds := false
var _grng := RandomNumberGenerator.new()
var _slot: Control = null
var _machine: SlotMachine = null
var _holder: Control = null

func _ready() -> void:
	# main.gd의 글꼴 설정과 같게: 공유 리소스를 건드리지 않고 복사, 확대 보정 끄기, 갈무리 보조 글꼴
	_font = load("res://font/neodgm.ttf").duplicate(true)
	_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	_font.hinting = TextServer.HINTING_NONE
	_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	_font.oversampling = 1.0
	_font.fallbacks = [load("res://font/galmuri11.fnt")]
	_rng.seed = 7
	_grng.randomize()
	_sync_owned()
	_reset_pets()
	mouse_filter = Control.MOUSE_FILTER_STOP

# ── 저장/불러오기 ──
func serialize() -> Dictionary:
	return {"c": counts.duplicate(), "e": equipped.duplicate(), "l": leader, "f": frags, "bg": bulk_grade, "ao": auto_on, "s": stored, "t": Time.get_unix_time_from_system()}

# now: 현재 시각. 저장 시각이 미래(시계를 돌림)면 그동안은 진주가 쌓이지 않는다.
func restore(d: Dictionary, now: float) -> void:
	counts = {}
	var c = d.get("c", {})
	if c is Dictionary:
		for k in c:
			if PETS.has(str(k)): counts[str(k)] = maxi(0, int(c[k]))
	equipped = []
	var e = d.get("e", [])
	if e is Array:
		for k in e:
			if PETS.has(str(k)) and counts.get(str(k), 0) >= 1 and not equipped.has(str(k)) and equipped.size() < 3: equipped.append(str(k))
	leader = str(d.get("l", ""))
	frags = maxi(0, int(d.get("f", 0)))
	bulk_grade = clampi(int(d.get("bg", 1)), 0, 3)
	auto_on = bool(d.get("ao", false))
	stored = maxf(0.0, float(d.get("s", 0.0)))
	var t := float(d.get("t", now))
	var hours := clampf((now - t) / 3600.0, 0.0, CAP_HOURS)
	stored = minf(stored + rate_per_hour() * hours, rate_per_hour() * CAP_HOURS)
	_sync_owned()
	_reset_pets()

func _t(n: String) -> Texture2D:
	if not _tex.has(n): _tex[n] = load(A + n + ".png")
	return _tex[n]

# 기존 shop_restyle.draw_art와 같은 9분할
func _art(name: String, r: Rect2) -> void:
	var tex: Texture2D = _t(name)
	var src := tex.get_size()
	var edge := 24.0
	var border := 9.0 if name == "panel" else 8.0
	var xs := [0.0, edge, src.x - edge, src.x]
	var ys := [0.0, edge, src.y - edge, src.y]
	var dx := [r.position.x, r.position.x + border, r.end.x - border, r.end.x]
	var dy := [r.position.y, r.position.y + border, r.end.y - border, r.end.y]
	for iy in 3:
		for ix in 3:
			var d := Rect2(dx[ix], dy[iy], dx[ix + 1] - dx[ix], dy[iy + 1] - dy[iy])
			if d.size.x <= 0 or d.size.y <= 0: continue
			draw_texture_rect_region(tex, d, Rect2(xs[ix], ys[iy], xs[ix + 1] - xs[ix], ys[iy + 1] - ys[iy]))

# 상점 X 버튼(close_control.gd)과 같은 모양: shop_repair/header.png 9분할 + 손으로 찍은 X
func _close_btn(box: Rect2) -> void:
	if not _tex.has("shop_close"): _tex["shop_close"] = load("res://art/shop_repair/header.png")
	var art: Texture2D = _tex["shop_close"]
	var r := Rect2(box.position.round(), Vector2(22, 23))
	var src := art.get_size()
	var xs := [0.0, 24.0, src.x - 24.0, src.x]
	var ys := [0.0, 24.0, src.y - 24.0, src.y]
	var dx := [r.position.x, r.position.x + 4.0, r.end.x - 4.0, r.end.x]
	var dy := [r.position.y, r.position.y + 4.0, r.end.y - 4.0, r.end.y]
	for iy in 3:
		for ix in 3:
			draw_texture_rect_region(art, Rect2(dx[ix], dy[iy], dx[ix + 1] - dx[ix], dy[iy + 1] - dy[iy]), Rect2(xs[ix], ys[iy], xs[ix + 1] - xs[ix], ys[iy + 1] - ys[iy]))
	var o := (r.get_center() - Vector2(5, 5)).floor()
	var pts := [Vector2i(0, 0), Vector2i(4, 0), Vector2i(1, 1), Vector2i(3, 1), Vector2i(2, 2), Vector2i(1, 3), Vector2i(3, 3), Vector2i(0, 4), Vector2i(4, 4)]
	for q in pts: draw_rect(Rect2(o + Vector2(q) * 2.0 + Vector2.ONE, Vector2(2, 2)), Color("392316"))
	for q in pts: draw_rect(Rect2(o + Vector2(q) * 2.0, Vector2(2, 2)), Color("fff0cc"))

func _txt(s: String, pos: Vector2, size: int, col: Color, center := false, w := 232.0) -> void:
	var x := roundf(pos.x - w / 2.0) if center else roundf(pos.x)
	# main.gd _font_idx와 같은 글자 크기 단계(10/12/14/16)만 써야 네오둥근모가 깨지지 않는다
	var px := 10 if size <= 10 else (12 if size <= 13 else (14 if size <= 15 else 16))
	# 게임 화면은 작은 해상도로 그려 확대하므로, 글자는 마을(main)의 글자 층(text_layer)으로 보내 폰 해상도로 그린다
	_text_next.append([_font, Vector2(x, roundf(pos.y)), s, HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT, w, px, col, 1.0])

func panel_rect() -> Rect2:
	return Rect2(8, panel_y if panel_y >= 0.0 else roundf((size.y - PH) / 2.0), 254, PH)

var text_out: Array = []          # 마을이 글자 층으로 가져가는 이번 프레임 글자 목록
var _text_next: Array = []

func texts() -> Array:
	if _slot == null: return text_out
	if _machine == null or _holder == null: return []    # 슬롯 연출 중에는 오두막 글자를 숨기고 기계의 글자만 보낸다
	var out: Array = []
	for it in _machine.texts():
		var q: Array = it.duplicate()
		q[1] = it[1] + _holder.position + _machine.position
		out.append(q)
	return out

func _draw() -> void:
	_text_next = []
	_paint()
	text_out = _text_next

# 위에 덮이는 창(펫 고르기·확률)이 가리는 자리의 아래쪽 글자는 뺀다
func _cover(r: Rect2) -> void:
	_text_next = _text_next.filter(func(it): return not r.has_point(it[1]))

func _paint() -> void:
	rects = {}
	if dim: draw_rect(Rect2(-dim_margin, 0, size.x + 2.0 * dim_margin, size.y), Color(0.04, 0.06, 0.1, 0.84))
	var r := panel_rect()
	_art("panel", r)
	var header := Rect2(r.position + Vector2(5, 5), Vector2(r.size.x - 10, 39))
	_art("header", header)
	draw_texture(_t("badge"), (header.position + Vector2(5, 6)).round())
	_txt("펫 오두막", Vector2(header.get_center().x, header.position.y + 23), 14, CREAM, true, header.size.x - 82)
	var cr := Rect2(header.end.x - 28, header.position.y + 7, 22, 23)
	_close_btn(cr)
	rects["close"] = cr.grow(3)
	_txt("펫이 진주를 캐고 있어요!", Vector2(135, r.position.y + 59), 11, INK, true, 232)
	for i in TABS.size():
		var key: String = TABS[i][0]
		var tr := Rect2(r.position.x + 12 + i * 58, r.position.y + 69, 56, 24)
		_art("teal" if tab == key else "card", tr)
		_txt(TABS[i][1], tr.get_center() + Vector2(0, 4), 9, CREAM if tab == key else INK, true, 52)
		rects["tab:" + key] = tr
	var body := Rect2(r.position.x + 12, r.position.y + 105, r.size.x - 24, r.size.y - 117)
	_art("card", body)
	rects["body"] = body
	if tab == "pets":
		_draw_pets_tab(body)
	elif tab == "box":
		_draw_box_tab(body)
	elif tab == "gacha":
		_draw_gacha_tab(body)
	else:
		_draw_plans_tab(body)

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		press(e.position)

func press(p: Vector2) -> void:
	if _slot != null:                 # 슬롯 연출 중에는 오두막 창이 반응하지 않고, 누르면 연출을 건너뜀
		if _machine != null and _machine.busy: _machine.skip()
		return
	if not _res.is_empty():           # 10회 결과표: 누르면 한꺼번에 나타나고, 한 번 더 누르면 닫힘
		_res_press(); return
	if rects.get("close", Rect2()).has_point(p) or not panel_rect().has_point(p):
		state_changed.emit(); closed.emit(); return
	if tab == "pets" and _pets_press(p): return
	if tab == "box" and _box_press(p): return
	if tab == "gacha" and _gacha_press(p): return
	if tab == "plans" and _plans_press(p): return
	for t in TABS:
		if rects.get("tab:" + t[0], Rect2()).has_point(p):
			tab = t[0]; picker = -1; show_odds = false; plan_msg = ""; box_msg = ""; queue_redraw(); return

# ───────── 내 펫 탭: 돌아다니며 진주 캐기 ─────────
static func grade_of(k: String) -> int:
	return {"d": 0, "c": 1, "b": 2, "a": 3, "s": 4, "ss": 5, "sss": 6}[k.split("_")[0]]

func rate_per_hour() -> float:
	var r := 0.0
	for k in equipped: r += RATE[grade_of(k)]
	return r

func _strip(k: String, kind: String) -> Texture2D:
	var n := "pets/%s_%s" % [k, kind]
	if not _tex.has(n): _tex[n] = load(A + n + ".png")
	return _tex[n]

func _reset_pets() -> void:
	_pets = []
	for i in equipped.size():
		var x := clampf(60.0 + i * 50.0, WALK_X0, WALK_X1)
		_pets.append({"k": equipped[i], "x": x, "y": 112.0 + (i % 2) * 8.0, "puff": 0.0, "tx": x, "face": 1, "state": "walk", "t": 0.0, "wait": _rng.randf_range(0.2, 1.5)})

func _half_w(k: String) -> float:
	return _strip(k, "move").get_height() / 2.0   # 1배 폭의 절반

func _pick_target(i: int) -> float:
	var lo := WALK_X0
	var hi := WALK_X1
	for _n in 8:
		var x := _rng.randf_range(lo, hi)
		var ok := true
		for j in _pets.size():
			if j != i and absf(_pets[j].x - x) < 26.0: ok = false
		if ok: return x
	return _rng.randf_range(lo, hi)

# dt초만큼 진행 (시험에서 직접 호출 가능)
func step(dt: float) -> void:
	_clock += dt
	stored = minf(stored + rate_per_hour() * dt * time_scale / 3600.0, rate_per_hour() * CAP_HOURS)
	for i in _pets.size():
		var p: Dictionary = _pets[i]
		p.t += dt
		match p.state:
			"walk":
				var d: float = p.tx - p.x
				if p.wait > 0.0:
					p.wait -= dt
				elif absf(d) < 1.5:
					p.state = "work"; p.t = 0.0
				else:
					p.face = 1 if d > 0 else -1
					p.x += signf(d) * minf(absf(d), 15.0 * dt)
					p.puff -= dt
					if p.puff <= 0.0 and not (p.k in FLYERS):
						p.puff = 0.14
						_dust.append({"x": p.x - p.face * 4.0 + _rng.randf_range(-2, 2), "y": p.y - 1.0, "t": 0.0})
			"work":
				if p.t >= 9.0 / 7.0:       # 동작 한 번(9프레임, 초당 7프레임)
					_fx.append({"x": p.x, "y": p.y, "t": 0.0})
					p.state = "walk"; p.t = 0.0; p.tx = _pick_target(i); p.wait = _rng.randf_range(0.3, 1.2)
	for f in _fx: f.t += dt
	for d in _dust: d.t += dt
	_dust = _dust.filter(func(d): return d.t < 0.6)
	_fx = _fx.filter(func(f): return f.t < 1.0)
	queue_redraw()

func _process(delta: float) -> void:
	if visible and tab == "pets": step(delta)
	if _slot != null:
		_sea_t += delta
		_slot.queue_redraw()

func _draw_pets_tab(body: Rect2) -> void:
	var scene := Rect2(body.position + Vector2(0, 5), SCENE)
	draw_texture_rect_region(_t("bg_sea"), scene, Rect2(1, 0, SCENE.x, SCENE.y))
	var props := [["coral", Vector2(8, 118), 5.0], ["pearls", Vector2(56, 126), 6.0], ["star", Vector2(176, 124), 4.0], ["chest", Vector2(198, 112), 7.0]]
	for pr in props:
		var tex: Texture2D = _t("prop_" + pr[0])
		var fi := int(_clock * 6.0 + pr[2]) % 9
		draw_texture_rect_region(tex, Rect2(scene.position + pr[1] - Vector2(0, 32), Vector2(32, 32)), Rect2(fi * 32, 0, 32, 32))
	for d in _dust:
		var u: float = d.t / 0.6
		var r := roundf(1.5 + u * 2.5)
		var c := Color(0.93, 0.85, 0.7, 0.75 * (1.0 - u))
		var cp := scene.position + Vector2(roundf(d.x), roundf(d.y - u * 6.0))
		draw_rect(Rect2(cp - Vector2(r, r), Vector2(r * 2.0, r * 2.0)), c)
	var order := range(_pets.size())
	order.sort_custom(func(a, b): return _pets[a].y < _pets[b].y)
	for i in order:
		var p: Dictionary = _pets[i]
		var kind: String = "work" if p.state == "work" else "move"
		var tex: Texture2D = _strip(p.k, kind)
		var h := tex.get_height()
		var fr := int(p.t * 7.0) % 9 if kind == "work" else (int(_clock * 8.0) % 9 if absf(p.tx - p.x) > 1.5 and p.wait <= 0.0 else 0)
		var sc := 1
		var lift := 0.0
		if p.k in FLYERS: lift = 6.0 + sin(_clock * 3.0 + i) * 2.0
		var pos := (scene.position + Vector2(p.x, p.y - lift)).round()   # 정수 칸에만 그려야 픽셀이 깨지지 않는다
		var dest := Rect2(pos.x - floorf(h * sc / 2.0), pos.y - h * sc, h * sc, h * sc).abs()
		if p.face < 0:
			draw_set_transform(Vector2(pos.x, 0), 0.0, Vector2(-1, 1))
			draw_texture_rect_region(tex, Rect2(-floorf(h * sc / 2.0), dest.position.y, h * sc, h * sc), Rect2(fr * h, 0, h, h))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_texture_rect_region(tex, dest, Rect2(fr * h, 0, h, h))
		# 11/22에 만든 펫별 오라 오버레이(윤곽·발광·파티클): 몸 칸을 사방 14픽셀 넓힌 칸
		var moving: bool = absf(p.tx - p.x) > 1.5 and p.wait <= 0.0
		var fxk: String = "work" if kind == "work" else ("move" if moving else "idle")
		var fxt: Texture2D = _strip(p.k, "fx_" + fxk)
		if fxt != null:
			var fs := fxt.get_height()
			var ff := fr if fxk != "idle" else int(_clock * 8.0) % 9
			var pad := floorf((fs - h) * 0.5)
			if p.face < 0:
				draw_set_transform(Vector2(pos.x, 0), 0.0, Vector2(-1, 1))
				draw_texture_rect_region(fxt, Rect2(-floorf(fs / 2.0), pos.y - h - pad, fs, fs), Rect2(ff * fs, 0, fs, fs))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				draw_texture_rect_region(fxt, Rect2(pos.x - floorf(fs / 2.0), pos.y - h - pad, fs, fs), Rect2(ff * fs, 0, fs, fs))
	for f in _fx:
		var yy: float = scene.position.y + f.y - 30.0 - f.t * 26.0
		var xx: float = scene.position.x + f.x
		var a: float = 1.0 - f.t
		draw_rect(Rect2(xx - 3, yy - 2, 6, 4), Color(0.2, 0.17, 0.25, a))
		draw_rect(Rect2(xx - 2, yy - 3, 4, 6), Color(0.2, 0.17, 0.25, a))
		draw_rect(Rect2(xx - 2, yy - 2, 4, 4), Color(1, 1, 1, a))
	# 상태 줄
	var y0 := scene.end.y + 15.0
	_txt("일하는 펫 %d마리 · 시간당 진주 %.2f" % [equipped.size(), rate_per_hour()], Vector2(body.position.x + body.size.x / 2.0, y0), 9, INK, true, body.size.x - 8)
	var cap := rate_per_hour() * CAP_HOURS
	var bar := Rect2(body.position.x + 6, y0 + 7, body.size.x - 12, 6)
	draw_rect(bar, Color("163d43"))
	draw_rect(Rect2(bar.position, Vector2(floorf(bar.size.x * clampf(stored / maxf(cap, 0.001), 0.0, 1.0)), bar.size.y)), Color("53c9bd"))
	_txt("보관 진주 %.1f / %.1f   (보유 %d)" % [stored, cap, pearl_total], Vector2(body.position.x + body.size.x / 2.0, y0 + 24), 8, INK, true, body.size.x - 8)
	var cb := Rect2(body.position.x + 6, y0 + 30, body.size.x - 12, 24)
	var can := stored >= 1.0
	_art("button" if can else "card", cb)
	_txt("진주 받기" if can else "진주 받기 (1개부터)", cb.get_center() + Vector2(0, 4), 10, CREAM if can else Color("6e5c49"), true, cb.size.x - 10)
	rects["collect"] = cb
	# 장착 슬롯 3칸
	for i in 3:
		var sr := Rect2(body.position.x + 6 + i * 74.0, cb.end.y + 8, 70, 80)
		_art("card", sr)
		rects["slot:%d" % i] = sr
		if i >= equipped.size():
			_txt("+ 비어 있음", sr.get_center() + Vector2(0, 4), 10, MUTED, true, 64)
			continue
		var k: String = equipped[i]
		var tex: Texture2D = _strip(k, "move")
		var th := tex.get_height()
		draw_texture_rect_region(tex, Rect2(sr.position + Vector2(floorf((70 - th) / 2.0), 8), Vector2(th, th)), Rect2(0, 0, th, th))
		_txt(GRADE_NAME[grade_of(k)], sr.position + Vector2(66 - GRADE_NAME[grade_of(k)].length() * 5, 14), 10, MUTED, false, 24)
		_txt(NAME[k], sr.position + Vector2(35, 72), 10, INK, true, 66)
		if get_leader() == k:
			draw_rect(Rect2(sr.position.x + 3, sr.position.y + 3, 22, 12), Color("c8962b"))
			_txt("대표", Vector2(sr.position.x + 14, sr.position.y + 13), 10, CREAM, true, 22)
	if picker >= 0: _draw_picker(body)

func _draw_picker(body: Rect2) -> void:
	var pr := Rect2(body.position + Vector2(2, 2), body.size - Vector2(4, 4))
	_art("panel", pr)
	_cover(pr)
	_txt("슬롯 %d에 일할 펫 고르기" % (picker + 1), Vector2(pr.get_center().x, pr.position.y + 17), 9, INK, true, pr.size.x - 10)
	for n in owned.size():
		var k: String = owned[n]
		var cr := Rect2(pr.position.x + 4 + (n % 5) * 44.5, pr.position.y + 24 + (n / 5) * 45.0, 43, 43)
		var here: int = equipped.find(k)
		draw_rect(cr, Color("8a5a2b"))
		draw_rect(cr.grow(-1), Color("1f6f6a") if here == picker else Color("f3e2b8"))
		var tex: Texture2D = _strip(k, "move")
		var th := tex.get_height()
		draw_texture_rect_region(tex, Rect2(cr.position + Vector2(floorf((43 - th) / 2.0), 0), Vector2(th, th)), Rect2(0, 0, th, th))
		draw_rect(Rect2(cr.position.x + 1, cr.position.y + 31, 41, 11), Color("1f6f6a") if here == picker else Color("f3e2b8"))
		_txt(SHORT.get(k, NAME[k]), cr.position + Vector2(21.5, 40), 10, CREAM if here == picker else INK, true, 50)
		rects["pick:" + k] = cr
	var xb := Rect2(pr.end.x - 38, pr.position.y + 5, 32, 16)
	_art("button", xb)
	_txt("닫기", xb.get_center() + Vector2(0, 4), 10, CREAM, true, 30)
	rects["picker_close"] = xb

func _pets_press(p: Vector2) -> bool:
	if picker >= 0:
		if rects.get("picker_close", Rect2()).has_point(p): picker = -1; queue_redraw(); return true
		for k in owned:
			if rects.get("pick:" + k, Rect2()).has_point(p):
				var other: int = equipped.find(k)
				if picker >= equipped.size():
					if other >= 0: equipped.remove_at(other)
					equipped.append(k)
				else:
					if get_leader() == equipped[picker]: leader = k
					if other >= 0 and other != picker: equipped[other] = equipped[picker]
					equipped[picker] = k
				picker = -1; _reset_pets(); state_changed.emit(); queue_redraw(); return true
		return true   # 고르는 창이 열려 있으면 다른 곳은 눌러도 반응 없음
	if rects.get("collect", Rect2()).has_point(p):
		var n := floori(stored)
		if n >= 1:
			stored -= n; pearl_total += n; pearls_collected.emit(n); state_changed.emit(); queue_redraw()
		return true
	for i in 3:
		if rects.get("slot:%d" % i, Rect2()).has_point(p): picker = i; queue_redraw(); return true
	return false

# ───────── 뽑기 탭: 진주 10개로 슬롯 한 판 ─────────
func _sync_owned() -> void:
	owned = PETS.filter(func(k): return counts.get(k, 0) >= 1)

static func pets_of(g: int) -> Array:
	return PETS.filter(func(k): return grade_of(k) == g)

static func pet_percent(k: String) -> float:
	return GRADE_P[grade_of(k)] / pets_of(grade_of(k)).size()

# 등급을 먼저 확률로 정하고, 같은 등급 안에서는 균등하게 한 마리를 정한다
func roll_pet() -> String:
	var x := _grng.randf() * 100.0
	var g := 6
	var acc := 0.0
	for i in 7:
		acc += GRADE_P[i]
		if x < acc: g = i; break
	var list := pets_of(g)
	return list[_grng.randi() % list.size()]

func can_pull(n := 1) -> bool:
	return _slot == null and pearl_total >= COST * n

## 자동 분해: 이미 가진 펫이고 범위 안의 등급이면 새로 쌓지 않고 바로 조각으로 바꾼다
func _auto_dismantles(k: String) -> bool:
	return auto_on and grade_of(k) <= bulk_grade and counts.get(k, 0) >= 1

func pull() -> bool:
	if not can_pull(): return false
	pearl_total -= COST
	var k := roll_pet()
	last_new = counts.get(k, 0) == 0
	_auto_frag = 0; _auto_n = 0
	if _auto_dismantles(k): _auto_frag = frag_of(k); _auto_n = 1; frags += _auto_frag
	else: counts[k] = counts.get(k, 0) + 1
	last_pet = k
	_sync_owned()
	state_changed.emit()
	_start_slot(k)
	queue_redraw()
	return true

## 10회: 슬롯은 10마리 중 가장 높은 등급 기준으로 1번만 돌리고, 끝나면 같은 펫을 합친 결과표를 보여준다
var _res: Array = []          # 결과표 칸: {k, n, new}, 높은 등급 순
var _res_shown := 0

func pull10() -> bool:
	if not can_pull(10): return false
	pearl_total -= COST10
	var got: Dictionary = {}   # 펫 → {k, n, new}
	_auto_frag = 0; _auto_n = 0
	var top := ""
	for i in 10:
		var k := roll_pet()
		if not got.has(k): got[k] = {"k": k, "n": 0, "new": counts.get(k, 0) == 0}
		got[k].n += 1
		if _auto_dismantles(k): _auto_frag += frag_of(k); _auto_n += 1; frags += frag_of(k)
		else: counts[k] = counts.get(k, 0) + 1
		if top == "" or grade_of(k) > grade_of(top): top = k
	_res = got.values()
	_res.sort_custom(func(a, b): return grade_of(a.k) > grade_of(b.k) or (grade_of(a.k) == grade_of(b.k) and PETS.find(a.k) < PETS.find(b.k)))
	last_pet = top
	last_new = got[top].new
	_sync_owned()
	state_changed.emit()
	_start_slot(top)
	queue_redraw()
	return true

func _show_result() -> void:
	_res_shown = 0
	queue_redraw()
	for i in _res.size():
		await get_tree().create_timer(0.15).timeout
		if _res.is_empty(): return
		_res_shown = maxi(_res_shown, i + 1)
		queue_redraw()

func _res_press() -> void:
	if _res_shown < _res.size(): _res_shown = _res.size()
	else: _res.clear()
	queue_redraw()

var _sea_t := 0.0

func _draw_sea() -> void:   # 슬롯 뒤 배경: 깊은 바다(위 청록 → 아래 남색) + 떠오르는 기포·진주
	var sz := _slot.size
	var n := 64
	for i in n:
		var f := float(i) / (n - 1)
		_slot.draw_rect(Rect2(0, sz.y * i / n, sz.x, sz.y / n + 1.0), Color(0.02, 0.17, 0.2).lerp(Color(0.01, 0.03, 0.12), f))
	for i in 18:
		var x := fmod(float(i) * 37.0 + 11.0, sz.x) + sin(_sea_t * 0.8 + i) * 4.0
		var sp := 14.0 + (i % 5) * 6.0
		var y := sz.y - fmod(_sea_t * sp + i * 83.0, sz.y + 20.0) + 10.0
		var pearl := i % 6 == 0
		var r := 1.5 if pearl else 1.0 + (i % 3)
		var c := Color(1, 0.95, 0.85, 0.7) if pearl else Color(0.6, 0.9, 1, 0.3)
		_slot.draw_rect(Rect2(roundf(x), roundf(y), r * 2.0, r * 2.0), c)
		if pearl: _slot.draw_rect(Rect2(roundf(x) + 1.0, roundf(y) + 1.0, 1.0, 1.0), Color(1, 1, 1, 0.9))

func _start_slot(k: String) -> void:
	_slot = Control.new()
	_slot.size = size
	_slot.z_index = 50
	_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slot.draw.connect(_draw_sea)
	# 슬롯은 게임 화면(작은 해상도를 4배 확대)이 아니라 폰 실제 해상도 층에 올려야 도트가 곱게 나온다. 층이 없으면(시험 등) 기존처럼 안에 얹는다.
	var hires := get_tree().get_first_node_in_group("hires_layer") as Node2D
	if hires != null:
		hires.add_child(_slot)
		_slot.position = global_position
	else:
		add_child(_slot)
	var holder := Control.new()   # 오두막 창과 같은 세로 가운데에 기계 몸통 가운데를 맞춘다(위 상태창에 겹치지 않음)
	holder.position = Vector2(0, maxf(panel_rect().get_center().y - SlotMachine.BODY_POS.y - SlotMachine.BODY_H * 0.5, 0.0))
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slot.add_child(holder)
	_holder = holder
	_machine = SlotMachine.new()
	_machine.reveal_pet = k
	holder.add_child(_machine)
	_machine.finished.connect(_slot_done, CONNECT_ONE_SHOT)
	var g := grade_of(k)
	_machine.play(SlotMachine.make_grid(g, _grng, g == 6 and _grng.randf() < 0.25))

func _slot_done(_info: Dictionary) -> void:
	_slot.queue_free()
	_slot = null; _machine = null; _holder = null
	if not _res.is_empty(): _show_result()
	queue_redraw()

# 슬롯 모듈과 같은 방식(원본 PNG를 그대로 읽음)
func _sym(g: String) -> Texture2D:
	var key := "sym_" + g
	if not _tex.has(key):
		_tex[key] = ImageTexture.create_from_image((load(A + "slot/" + key + ".png") as Texture2D).get_image())   # 폰(APK)에는 원본 PNG가 없어 load()로 읽는다
	return _tex[key]

func _draw_gacha_tab(body: Rect2) -> void:
	var cx := body.position.x + body.size.x / 2.0
	var y := body.position.y
	_txt("진주 슬롯", Vector2(cx, y + 17), 10, INK, true, 220)
	for i in 3:
		var sr := Rect2(cx - 82 + i * 56, y + 30, 52, 52)
		_art("card", sr)
		draw_texture(_sym(GRADE_NAME[[3, 4, 6][i]]), sr.position + Vector2(2, 2))
	_txt("보유 진주 %d개" % pearl_total, Vector2(cx, y + 104), 9, INK, true, 220)
	var bw := (body.size.x - 30) / 2.0
	var pb := Rect2(body.position.x + 12, y + 114, bw, 30)
	var ok := pearl_total >= COST
	_art("button" if ok else "card", pb)
	_txt("1회 (진주 %d)" % COST if ok else "진주 부족", pb.get_center() + Vector2(0, 4), 10, CREAM if ok else Color("6e5c49"), true, pb.size.x - 6)
	rects["pull"] = pb
	var pb10 := Rect2(pb.end.x + 6, y + 114, bw, 30)
	var ok10 := pearl_total >= COST10
	_art("button" if ok10 else "card", pb10)
	_txt("10회 (진주 %d)" % COST10 if ok10 else "진주 부족", pb10.get_center() + Vector2(0, 4), 10, CREAM if ok10 else Color("6e5c49"), true, pb10.size.x - 6)
	rects["pull10"] = pb10
	var ob := Rect2(body.position.x + 12, y + 152, body.size.x - 24, 24)
	_art("card", ob)
	_txt("확률 보기", ob.get_center() + Vector2(0, 4), 9, INK, true, ob.size.x - 10)
	rects["odds"] = ob
	var lr := Rect2(body.position.x + 6, y + 186, body.size.x - 12, 58)
	_art("card", lr)
	if last_pet == "":
		_txt("아직 뽑은 펫이 없어요", lr.get_center() + Vector2(0, 4), 11, MUTED, true, lr.size.x - 10)
	else:
		var tex: Texture2D = _strip(last_pet, "move")
		var th := tex.get_height()
		draw_texture_rect_region(tex, Rect2(lr.position + Vector2(8, floorf((58 - th) / 2.0)), Vector2(th, th)), Rect2(0, 0, th, th))
		_txt("최근 뽑은 펫", lr.position + Vector2(52, 18), 11, MUTED, false, 100)
		_txt("%s (%s)" % [NAME[last_pet], GRADE_NAME[grade_of(last_pet)]], lr.position + Vector2(52, 34), 9, INK, false, 100)
		_txt("새 펫!" if last_new else ("중복 · 자동 분해 +%d" % _auto_frag if _auto_n > 0 else "중복 · 분해 가능"), lr.position + Vector2(52, 50), 8, Color("2f8f84") if last_new else MUTED, false, 100)
	_txt("중복 펫은 도면 탭에서 분해해요", Vector2(cx, y + 270), 11, MUTED, true, 220)
	_txt("진주는 낚시·탐험·펫이 캐서 얻어요", Vector2(cx, y + 288), 11, MUTED, true, 220)
	if show_odds: _draw_odds(body)
	if not _res.is_empty(): _draw_result(body)

## 10회 결과표: 같은 펫은 하나로 합쳐 xN으로, 등급 높은 순
func _draw_result(body: Rect2) -> void:
	var pr := Rect2(body.position + Vector2(2, 2), body.size - Vector2(4, 4))
	_art("panel", pr)
	_cover(pr)
	_txt("10회 결과", Vector2(pr.get_center().x, pr.position.y + 17), 11, INK, true, 120)
	var cw := (pr.size.x - 20) / 2.0
	var ch := 40.0
	var grade_cnt := {}
	var new_cnt := 0
	for i in _res.size():
		var e: Dictionary = _res[i]
		var g := grade_of(e.k)
		grade_cnt[g] = grade_cnt.get(g, 0) + e.n
		if e.new: new_cnt += 1
		if i >= _res_shown: continue
		var cr := Rect2(pr.position + Vector2(7 + (i % 2) * (cw + 6), 26 + (i / 2) * (ch + 3)), Vector2(cw, ch))
		_art("card", cr)
		draw_rect(cr, GRADE_COL[g], false, 1.0)
		var tex: Texture2D = _strip(e.k, "move")
		var th := tex.get_height()
		draw_texture_rect_region(tex, Rect2(cr.position + Vector2(3, floorf((ch - th) / 2.0)), Vector2(th, th)), Rect2(0, 0, th, th))
		var tx := cr.position.x + th + 6
		_txt(NAME[e.k], Vector2(tx, cr.position.y + 15), 8, INK, false, cw - th - 8)
		_txt(GRADE_NAME[g] + ("  x%d" % e.n if e.n > 1 else ""), Vector2(tx, cr.position.y + 31), 9, GRADE_COL[g], false, 50)
		if e.new: _txt("NEW", Vector2(cr.end.x - 24, cr.position.y + 31), 8, Color("2f8f84"), false, 26)
	var parts: Array = []
	for g in range(6, -1, -1):
		if grade_cnt.has(g): parts.append("%s %d" % [GRADE_NAME[g], grade_cnt[g]])
	_txt(" · ".join(parts), Vector2(pr.get_center().x, pr.end.y - 30), 9, INK, true, pr.size.x - 10)
	var nt := "새 펫 %d마리" % new_cnt if new_cnt > 0 else "새 펫 없음"
	if _auto_n > 0: nt += " · 자동 분해 조각 +%d" % _auto_frag
	_txt(nt, Vector2(pr.get_center().x, pr.end.y - 18), 9, MUTED, true, pr.size.x - 10)
	_txt("누르면 닫혀요" if _res_shown >= _res.size() else "누르면 바로 보여요", Vector2(pr.get_center().x, pr.end.y - 6), 8, MUTED, true, 120)

func _draw_odds(body: Rect2) -> void:
	var pr := Rect2(body.position + Vector2(2, 2), body.size - Vector2(4, 4))
	_art("panel", pr)
	_cover(pr)
	_txt("등급별 확률", Vector2(pr.position.x + 50, pr.position.y + 17), 9, INK, true, 90)
	for g in 7:
		var n := pets_of(g).size()
		var ry := pr.position.y + 28 + g * 25.0
		var rr := Rect2(pr.position.x + 7, ry, pr.size.x - 14, 23)
		_art("card", rr)
		_txt(GRADE_NAME[g], rr.position + Vector2(8, 15), 10, MUTED, false, 30)
		_txt("%s%%" % String.num(GRADE_P[g], 1), rr.position + Vector2(46, 15), 9, INK, false, 50)
		_txt("펫 %d종 · 각 %s%%" % [n, String.num(GRADE_P[g] / n, 2)], rr.position + Vector2(100, 15), 8, INK, false, 120)
	_txt("같은 등급 안에서는 모두 같은 확률", Vector2(pr.get_center().x, pr.end.y - 38), 11, MUTED, true, pr.size.x - 10)
	_txt("결과를 먼저 정한 뒤 릴이 멈춰요", Vector2(pr.get_center().x, pr.end.y - 25), 11, MUTED, true, pr.size.x - 10)
	var xb := Rect2(pr.end.x - 38, pr.position.y + 5, 32, 16)
	_art("button", xb)
	_txt("닫기", xb.get_center() + Vector2(0, 4), 8, CREAM, true, 30)
	rects["odds_close"] = xb

func _gacha_press(p: Vector2) -> bool:
	if show_odds:
		if rects.get("odds_close", Rect2()).has_point(p): show_odds = false; queue_redraw()
		return true
	if rects.get("pull", Rect2()).has_point(p): pull(); return true
	if rects.get("pull10", Rect2()).has_point(p): pull10(); return true
	if rects.get("odds", Rect2()).has_point(p): show_odds = true; queue_redraw(); return true
	return false

# ───────── 도면 탭: 중복 펫 분해 → 조각, 조각+진주로 도면 제작 ─────────
static func frag_of(k: String) -> int:
	return FRAG[grade_of(k)]

func can_dismantle(k: String) -> bool:
	return counts.get(k, 0) >= 2          # 처음 얻은 1마리는 도감용이라 분해 불가

func dismantle(k: String) -> bool:
	if not can_dismantle(k): return false
	counts[k] -= 1
	frags += frag_of(k)
	plan_msg = "%s 분해! 조각 +%d" % [NAME[k], frag_of(k)]
	state_changed.emit()
	return true

## 범위 안 등급의 중복(처음 1마리는 남김)을 한꺼번에 분해했을 때의 [마리 수, 조각]
func bulk_preview() -> Vector2i:
	var n := 0
	var f := 0
	for k in PETS:
		var extra: int = counts.get(k, 0) - 1
		if extra > 0 and grade_of(k) <= bulk_grade:
			n += extra; f += extra * frag_of(k)
	return Vector2i(n, f)

func dismantle_bulk() -> bool:
	var pv := bulk_preview()
	if pv.x <= 0: return false
	for k in PETS:
		if counts.get(k, 0) > 1 and grade_of(k) <= bulk_grade: counts[k] = 1
	frags += pv.y
	box_msg = "일괄 분해! %d마리 · 조각 +%d" % [pv.x, pv.y]
	state_changed.emit()
	return true

func can_craft(k: String) -> bool:
	var g := grade_of(k)
	return BP_COST.has(g) and frags >= BP_COST[g][0] and pearl_total >= BP_COST[g][1]

func craft(k: String) -> bool:
	if not can_craft(k): return false
	var c: Array = BP_COST[grade_of(k)]
	frags -= c[0]; pearl_total -= c[1]
	last_new = counts.get(k, 0) == 0
	counts[k] = counts.get(k, 0) + 1
	last_pet = k
	_sync_owned()
	plan_msg = "%s 도면 구매! 펫을 얻었어요" % NAME[k]
	state_changed.emit()
	return true

func _draw_plans_tab(body: Rect2) -> void:
	var b := body.position
	var cx := b.x + body.size.x / 2.0
	_txt(plan_msg if plan_msg != "" else "조각 %d개 · 진주 %d개" % [frags, pearl_total], Vector2(cx, b.y + 17), 9, Color("2f8f84") if plan_msg != "" else INK, true, 220)
	var list := bp_pets()
	for n in list.size():
		var k: String = list[n]
		var cr := Rect2(b.x + 4 + (n % 3) * 75.0, b.y + 26 + (n / 3) * 38.0, 73, 36)
		_art("teal" if plan_sel == k else "card", cr)
		var aff := can_craft(k)
		draw_texture(_t("icon/bp_" + k), cr.position + Vector2(2, 2), Color(1, 1, 1, 1.0 if aff else 0.5))
		var tex: Texture2D = _strip(k, "move")
		var th := tex.get_height()
		draw_texture_rect_region(tex, Rect2(cr.position + Vector2(36 + floorf((36 - th) / 2.0), floorf((36 - th) / 2.0)), Vector2(th, th)), Rect2(0, 0, th, th), Color(1, 1, 1, 1.0 if aff else 0.55))
		rects["bp:" + k] = cr
	var dr := Rect2(b.x + 6, b.y + 228, body.size.x - 12, 64)
	_art("card", dr)
	if plan_sel == "":
		_txt("살 도면을 골라요 (흐린 칸은 재료 부족)", dr.get_center() + Vector2(0, 4), 8, MUTED, true, dr.size.x - 10)
	else:
		var c: Array = BP_COST[grade_of(plan_sel)]
		_txt("%s 도면 (%s)" % [NAME[plan_sel], GRADE_NAME[grade_of(plan_sel)]], dr.position + Vector2(8, 20), 9, INK, false, 130)
		draw_texture(_t("icon/frag16"), dr.position + Vector2(8, 32))
		_txt("%d" % c[0], dr.position + Vector2(27, 44), 8, Color("2f8f84") if frags >= c[0] else Color("b04a3a"), false, 40)
		_txt("진주 %d" % c[1], dr.position + Vector2(66, 44), 8, Color("2f8f84") if pearl_total >= c[1] else Color("b04a3a"), false, 50)
		var bt := Rect2(dr.end.x - 54, dr.position.y + 19, 48, 26)
		var ok := can_craft(plan_sel)
		_art("button" if ok else "card", bt)
		_txt("구매", bt.get_center() + Vector2(0, 4), 9, CREAM if ok else Color("6e5c49"), true, 44)
		rects["buy"] = bt

static func bp_pets() -> Array:
	return PETS.filter(func(k): return BP_COST.has(grade_of(k)))

func _plans_press(p: Vector2) -> bool:
	for k in bp_pets():
		if rects.get("bp:" + k, Rect2()).has_point(p): plan_sel = k; plan_msg = ""; queue_redraw(); return true
	if plan_sel != "" and rects.get("buy", Rect2()).has_point(p): craft(plan_sel); queue_redraw(); return true
	return false

# ───────── 보관함 탭: 가진 펫 보기, 장착/빼기, 분해 ─────────
func get_leader() -> String:
	if equipped.has(leader): return leader
	return equipped[0] if equipped.size() > 0 else ""

func set_leader(k: String) -> bool:
	if counts.get(k, 0) < 1: return false
	if not equipped.has(k) and not equip(k): return false
	leader = k; box_msg = "%s 대표 지정!" % NAME[k]
	state_changed.emit()
	return true

func equip(k: String) -> bool:
	if counts.get(k, 0) < 1 or equipped.has(k): return false
	if equipped.size() >= 3: box_msg = "슬롯이 가득 찼어요. 먼저 빼 주세요"; return false
	equipped.append(k)
	if equipped.size() == 1: leader = k
	_reset_pets(); box_msg = "%s 장착!" % NAME[k]
	state_changed.emit()
	return true

func unequip(k: String) -> bool:
	if not equipped.has(k): return false
	var was := get_leader() == k
	equipped.erase(k)
	if was: leader = equipped[0] if equipped.size() > 0 else ""
	_reset_pets(); box_msg = "%s 뺐어요" % NAME[k]
	state_changed.emit()
	return true

func _draw_box_tab(body: Rect2) -> void:
	var b := body.position
	var cx := b.x + body.size.x / 2.0
	_txt(box_msg if box_msg != "" else "도감 %d/%d · 장착 %d/3 · 조각 %d" % [owned.size(), PETS.size(), equipped.size(), frags], Vector2(cx, b.y + 17), 9, Color("2f8f84") if box_msg != "" else INK, true, 224)
	for n in PETS.size():
		var k: String = PETS[n]
		var have: int = counts.get(k, 0)
		var cr := Rect2(b.x + 4 + (n % 6) * 37.0, b.y + 26 + (n / 6) * 38.0, 36, 36)
		_art("teal" if box_sel == k else "card", cr)
		var tex: Texture2D = _strip(k, "move")
		var th := tex.get_height()
		var tint := Color(1, 1, 1, 1.0) if have >= 1 else Color(0.1, 0.08, 0.07, 0.75)
		draw_texture_rect_region(tex, Rect2(cr.position + Vector2(floorf((36 - th) / 2.0), floorf((36 - th) / 2.0) - 1), Vector2(th, th)), Rect2(0, 0, th, th), tint)
		if have >= 1:
			draw_rect(Rect2(cr.end.x - 15, cr.end.y - 14, 13, 12), Color(0.22, 0.15, 0.1, 0.85))
			_txt("%d" % have, Vector2(cr.end.x - 8.5, cr.end.y - 4), 10, CREAM, true, 13)
		if equipped.has(k):
			draw_rect(Rect2(cr.position.x + 2, cr.position.y + 2, 13, 12), Color("2f8f84"))
			_txt("장", Vector2(cr.position.x + 8.5, cr.position.y + 12), 10, CREAM, true, 13)
		if get_leader() == k:
			draw_rect(Rect2(cr.end.x - 15, cr.position.y + 2, 13, 12), Color("c8962b"))
			_txt("대", Vector2(cr.end.x - 8.5, cr.position.y + 12), 10, CREAM, true, 13)
		rects["bx:" + k] = cr
	var dr := Rect2(b.x + 4, b.y + 196, body.size.x - 8, 106)
	_art("card", dr)
	if box_sel == "":
		_draw_bulk_panel(dr)
		return
	var have2: int = counts.get(box_sel, 0)
	var tex2: Texture2D = _strip(box_sel, "move")
	var th2 := tex2.get_height()
	var t2 := Color(1, 1, 1, 1) if have2 >= 1 else Color(0.1, 0.08, 0.07, 0.75)
	draw_texture_rect_region(tex2, Rect2(dr.position + Vector2(6 + floorf((36 - th2) / 2.0), 8 + floorf((36 - th2) / 2.0)), Vector2(th2, th2)), Rect2(0, 0, th2, th2), t2)
	_txt("%s (%s)" % [NAME[box_sel], GRADE_NAME[grade_of(box_sel)]], dr.position + Vector2(48, 20), 9, INK, false, 110)
	_txt("보유 %d · 시간당 진주 %.2f" % [have2, RATE[grade_of(box_sel)]] if have2 >= 1 else "아직 없는 펫이에요", dr.position + Vector2(48, 38), 9, MUTED, false, 170)
	var eq := equipped.has(box_sel)
	var ok1 := have2 >= 1
	var b1 := Rect2(dr.position.x + 6, dr.position.y + 66, 68, 26)
	_art("button" if ok1 else "card", b1)
	_txt("빼기" if eq else "장착", b1.get_center() + Vector2(0, 4), 9, CREAM if ok1 else Color("6e5c49"), true, 62)
	rects["bx_equip"] = b1
	var is_l := get_leader() == box_sel
	var b3 := Rect2(dr.position.x + 78, dr.position.y + 66, 68, 26)
	var ok3 := ok1 and not is_l
	_art("button" if ok3 else "card", b3)
	_txt("대표 중" if is_l else "대표 지정", b3.get_center() + Vector2(0, 4), 8, CREAM if ok3 else Color("6e5c49"), true, 62)
	rects["bx_leader"] = b3
	var b2 := Rect2(dr.position.x + 150, dr.position.y + 66, 68, 26)
	var ok2 := can_dismantle(box_sel)
	_art("button" if ok2 else "card", b2)
	if ok2:
		draw_texture(_t("icon/frag16"), (b2.get_center() + Vector2(-22, -8)).round())
		_txt("+%d" % frag_of(box_sel), b2.get_center() + Vector2(8, 4), 8, CREAM, true, 40)
	else:
		_txt("분해 불가", b2.get_center() + Vector2(0, 4), 8, Color("6e5c49"), true, 62)
	rects["bx_dis"] = b2

## 펫을 고르지 않았을 때 아래 카드에 보이는 분해 관리: 범위 / 일괄 분해 / 자동 분해(큰 버튼 3줄)
func _draw_bulk_panel(dr: Rect2) -> void:
	var pv := bulk_preview()
	var armed := Time.get_ticks_msec() / 1000.0 - _bulk_arm < 3.0
	var w := dr.size.x - 16.0
	var rg := Rect2(dr.position.x + 8, dr.position.y + 8, w, 26)
	_art("button", rg)
	_txt("분해 범위  D~%s  (눌러서 바꾸기)" % GRADE_NAME[bulk_grade] if bulk_grade > 0 else "분해 범위  D만  (눌러서 바꾸기)", rg.get_center() + Vector2(0, 4), 9, CREAM, true, w - 10)
	rects["bx_range"] = rg
	var rb := Rect2(rg.position.x, rg.end.y + 5, w, 26)
	_art("button" if pv.x > 0 else "card", rb)
	var lb := "분해할 중복 펫이 없어요"
	if pv.x > 0: lb = ("한 번 더 누르면 분해! 조각 +%d" % pv.y) if armed else ("일괄 분해  %d마리 → 조각 +%d" % [pv.x, pv.y])
	_txt(lb, rb.get_center() + Vector2(0, 4), 9, CREAM if pv.x > 0 else Color("6e5c49"), true, w - 10)
	rects["bx_bulk"] = rb
	var ra := Rect2(rg.position.x, rb.end.y + 5, w, 26)
	_art("button" if auto_on else "card", ra)
	_txt("자동 분해  켬  (뽑을 때 D~%s 중복)" % GRADE_NAME[bulk_grade] if auto_on else "자동 분해  끔  (눌러서 켜기)", ra.get_center() + Vector2(0, 4), 9, CREAM if auto_on else INK, true, w - 10)
	rects["bx_auto"] = ra

func _box_press(p: Vector2) -> bool:
	if rects.get("bx_range", Rect2()).has_point(p):
		bulk_grade = (bulk_grade + 1) % 4; _bulk_arm = -100.0; box_msg = ""; state_changed.emit(); queue_redraw(); return true
	if rects.get("bx_bulk", Rect2()).has_point(p):
		if bulk_preview().x <= 0: box_msg = "분해할 중복 펫이 없어요"
		elif Time.get_ticks_msec() / 1000.0 - _bulk_arm < 3.0: dismantle_bulk(); _bulk_arm = -100.0
		else: _bulk_arm = Time.get_ticks_msec() / 1000.0
		queue_redraw(); return true
	if rects.get("bx_auto", Rect2()).has_point(p):
		auto_on = not auto_on; box_msg = "자동 분해 %s (D~%s 중복)" % ["켬" if auto_on else "끔", GRADE_NAME[bulk_grade]]; state_changed.emit(); queue_redraw(); return true
	for k in PETS:
		if rects.get("bx:" + k, Rect2()).has_point(p): box_sel = "" if box_sel == k else k; box_msg = ""; queue_redraw(); return true
	if box_sel != "" and rects.get("bx_equip", Rect2()).has_point(p):
		if equipped.has(box_sel): unequip(box_sel)
		else: equip(box_sel)
		queue_redraw(); return true
	if box_sel != "" and rects.get("bx_leader", Rect2()).has_point(p):
		set_leader(box_sel); queue_redraw(); return true
	if box_sel != "" and rects.get("bx_dis", Rect2()).has_point(p):
		if dismantle(box_sel): box_msg = plan_msg
		queue_redraw(); return true
	return false
