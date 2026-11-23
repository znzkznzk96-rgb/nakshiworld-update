class_name PetHutUI
extends Control
# 펫 오두막 창: 기존 상점 틀(panel/header/teal/card)과 같은 구성. 탭 3개.
signal closed
signal pearls_collected(n: int)
const PETS := ["d_chick", "d_frog", "d_mouse", "c_mushroom", "c_puffbird", "c_slime", "b_hamster", "b_hedgehog", "b_sparrow", "a_fennec", "a_otter", "a_owl", "s_fairy", "s_tome", "s_wisp", "ss_golem", "ss_knight", "ss_storm", "sss_apostle", "sss_demon", "sss_lunar", "sss_seraph"]
const NAME := {"d_chick": "병아리", "d_frog": "개구리", "d_mouse": "생쥐", "c_mushroom": "버섯", "c_puffbird": "퍼프버드", "c_slime": "슬라임", "b_hamster": "햄스터", "b_hedgehog": "고슴도치", "b_sparrow": "참새", "a_fennec": "사막여우", "a_otter": "수달", "a_owl": "부엉이", "s_fairy": "요정", "s_tome": "마도서", "s_wisp": "촛불정령", "ss_golem": "골렘", "ss_knight": "기사", "ss_storm": "폭풍룡", "sss_apostle": "별의 사도", "sss_demon": "심연의 악마", "sss_lunar": "달의 여인", "sss_seraph": "세라핌"}
const GRADE_NAME := ["D", "C", "B", "A", "S", "SS", "SSS"]
const RATE := [0.1, 0.2, 0.35, 0.6, 1.0, 1.6, 2.5]   # 시간당 진주
const CAP_HOURS := 12.0
const WALK_X0 := 44.0   # 모래바닥 좌우 끝 (양옆 바위 안쪽)
const WALK_X1 := 188.0
const FLYERS := ["a_owl", "s_fairy", "s_tome", "s_wisp", "ss_storm", "sss_lunar", "sss_seraph"]
const SCENE := Vector2(230, 128)
const TABS := [["pets", "내 펫"], ["gacha", "뽑기"], ["plans", "도면"]]
const INK := Color("382619")
const CREAM := Color("fff0d1")
const A := "res://assets/"
var tab := "pets"
var owned: Array = PETS.duplicate()
var equipped: Array = ["b_hamster", "ss_golem", "sss_seraph"]
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

func _ready() -> void:
	_font = load(A + "neodgm.ttf")
	_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	_font.hinting = TextServer.HINTING_NONE
	_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	custom_minimum_size = Vector2(270, 420)
	_rng.seed = 7
	_reset_pets()
	mouse_filter = Control.MOUSE_FILTER_STOP

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

func _txt(s: String, pos: Vector2, size: int, col: Color, center := false, w := 232.0) -> void:
	var x := roundf(pos.x - w / 2.0) if center else roundf(pos.x)
	draw_string(_font, Vector2(x, roundf(pos.y)), s, HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT, w, size, col)

func panel_rect() -> Rect2:
	return Rect2(8, roundf((size.y - 380.0) / 2.0), 254, 380)

func _draw() -> void:
	rects = {}
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.1, 0.84))
	var r := panel_rect()
	_art("panel", r)
	var header := Rect2(r.position + Vector2(5, 5), Vector2(r.size.x - 10, 39))
	_art("header", header)
	draw_texture(_t("badge"), (header.position + Vector2(5, 6)).round())
	_txt("펫 오두막", Vector2(header.get_center().x, header.position.y + 23), 14, CREAM, true, header.size.x - 82)
	var cr := Rect2(header.end.x - 28, header.position.y + 7, 22, 23)
	_art("button", cr)
	_txt("X", cr.get_center() + Vector2(0, 4), 10, CREAM, true, 20)
	rects["close"] = cr.grow(3)
	_txt("펫이 진주를 캐고 있어요!", Vector2(135, r.position.y + 59), 9, INK, true, 232)
	for i in 3:
		var key: String = TABS[i][0]
		var tr := Rect2(r.position.x + 12 + i * 77, r.position.y + 69, 74, 24)
		_art("teal" if tab == key else "card", tr)
		_txt(TABS[i][1], tr.get_center() + Vector2(0, 4), 9, CREAM if tab == key else INK, true, 68)
		rects["tab:" + key] = tr
	var body := Rect2(r.position.x + 12, r.position.y + 105, r.size.x - 24, r.size.y - 117)
	_art("card", body)
	rects["body"] = body
	if tab == "pets":
		_draw_pets_tab(body)
	else:
		_txt({"gacha": "뽑기", "plans": "도면"}[tab] + " 화면", body.get_center() + Vector2(0, 4), 10, INK, true, body.size.x - 12)

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		press(e.position)

func press(p: Vector2) -> void:
	if rects.get("close", Rect2()).has_point(p) or not panel_rect().has_point(p):
		closed.emit(); return
	if tab == "pets" and _pets_press(p): return
	for t in TABS:
		if rects.get("tab:" + t[0], Rect2()).has_point(p):
			tab = t[0]; picker = -1; queue_redraw(); return

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
		var pos := scene.position + Vector2(p.x, p.y - lift)
		var dest := Rect2(pos.x - h * sc / 2.0, pos.y - h * sc, h * sc, h * sc).abs()
		if p.face < 0:
			draw_set_transform(Vector2(pos.x, 0), 0.0, Vector2(-1, 1))
			draw_texture_rect_region(tex, Rect2(-h * sc / 2.0, dest.position.y, h * sc, h * sc), Rect2(fr * h, 0, h, h))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_texture_rect_region(tex, dest, Rect2(fr * h, 0, h, h))
	for f in _fx:
		var yy: float = scene.position.y + f.y - 30.0 - f.t * 26.0
		var xx: float = scene.position.x + f.x
		var a: float = 1.0 - f.t
		draw_rect(Rect2(xx - 3, yy - 2, 6, 4), Color(0.2, 0.17, 0.25, a))
		draw_rect(Rect2(xx - 2, yy - 3, 4, 6), Color(0.2, 0.17, 0.25, a))
		draw_rect(Rect2(xx - 2, yy - 2, 4, 4), Color(1, 1, 1, a))
	# 상태 줄
	var y0 := scene.end.y + 13.0
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
	for i in equipped.size():
		var sr := Rect2(body.position.x + 6 + i * 74.0, cb.end.y + 6, 70, 44)
		_art("card", sr)
		var k: String = equipped[i]
		var tex: Texture2D = _strip(k, "move")
		var th := tex.get_height()
		draw_texture_rect_region(tex, Rect2(sr.position + Vector2(3, 6), Vector2(th, th)), Rect2(0, 0, th, th))
		_txt(NAME[k], sr.position + Vector2(40, 17), 8, INK, false, 30)
		_txt(GRADE_NAME[grade_of(k)], sr.position + Vector2(40, 31), 9, Color("8f6951"), false, 28)
		rects["slot:%d" % i] = sr
	if picker >= 0: _draw_picker(body)

func _draw_picker(body: Rect2) -> void:
	var pr := Rect2(body.position + Vector2(2, 2), body.size - Vector2(4, 4))
	_art("panel", pr)
	_txt("슬롯 %d에 일할 펫 고르기" % (picker + 1), Vector2(pr.get_center().x, pr.position.y + 17), 9, INK, true, pr.size.x - 10)
	for n in owned.size():
		var k: String = owned[n]
		var cr := Rect2(pr.position.x + 7 + (n % 5) * 43.0, pr.position.y + 26 + (n / 5) * 42.0, 40, 39)
		var here: int = equipped.find(k)
		_art("teal" if here == picker else "card", cr)
		var tex: Texture2D = _strip(k, "move")
		var th := tex.get_height()
		draw_texture_rect_region(tex, Rect2(cr.position + Vector2((40 - th) / 2.0, 2), Vector2(th, th)), Rect2(0, 0, th, th))
		_txt(NAME[k], cr.position + Vector2(20, 34), 7, CREAM if here == picker else INK, true, 38)
		rects["pick:" + k] = cr
	var xb := Rect2(pr.end.x - 38, pr.position.y + 5, 32, 16)
	_art("button", xb)
	_txt("닫기", xb.get_center() + Vector2(0, 4), 8, CREAM, true, 30)
	rects["picker_close"] = xb

func _pets_press(p: Vector2) -> bool:
	if picker >= 0:
		if rects.get("picker_close", Rect2()).has_point(p): picker = -1; queue_redraw(); return true
		for k in owned:
			if rects.get("pick:" + k, Rect2()).has_point(p):
				var other: int = equipped.find(k)
				if other >= 0 and other != picker: equipped[other] = equipped[picker]
				equipped[picker] = k
				picker = -1; _reset_pets(); queue_redraw(); return true
		return true   # 고르는 창이 열려 있으면 다른 곳은 눌러도 반응 없음
	if rects.get("collect", Rect2()).has_point(p):
		var n := floori(stored)
		if n >= 1:
			stored -= n; pearl_total += n; pearls_collected.emit(n); queue_redraw()
		return true
	for i in equipped.size():
		if rects.get("slot:%d" % i, Rect2()).has_point(p): picker = i; queue_redraw(); return true
	return false
