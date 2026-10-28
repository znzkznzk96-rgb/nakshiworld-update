extends RefCounted
const NAMES: = ["동네 저수지", "거꾸로 폭포 계곡", "타일 바다", "균열 해역", "심해 · 가라앉은 사무실", "우주 바다"]
const ART: = ["reservoir", "valley", "tile_sea", "rift", "deep", "space"]
const PRICES: = [0, 6600, 104000, 1545000, 10050000, 42450000]
const CONCEPT: = ["물에 비친 달이 조금 더 큰 저수지", "위로 솟아오르는 폭포를 찾아서", "타일 바닥이 끝없이 이어지는 바다", "빛나는 하늘 균열 아래의 선상 낚시", "물속에 가라앉은 사무실 복도", "별과 행성 사이에 떠 있는 바다"]
var images: = []
var chains: Texture2D
var index: = 0
var scroll: = 0.0
var pointer: = false
var dragging: = false
var down: = Vector2.ZERO
var shift: = 0.0
var rects: = {}
var notice: = ""
var notice_until: = 0.0
func setup() -> void :
	for n in ART: images.append(load("res://art/refresh53/%s.png" % ("reservoir_clean" if n == "reservoir" else n)))
	chains = load("res://art/refresh53/chains.png")
func enter() -> void : pointer = false;dragging = false;shift = 0;scroll = index;notice = ""
func process(dt: float) -> void :
	if not pointer: scroll = lerpf(scroll, float(index), 1 - exp( - dt * 13));shift = lerpf(shift, 0, 1 - exp( - dt * 13))
func change(delta: int) -> void : index = clampi(index + delta, 0, 5);shift = 0
func input_event(m, e: InputEvent) -> bool:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = e.position - Vector2(m.ox, 0)
		if e.pressed: pointer = true;dragging = false;down = p
		elif pointer:
			pointer = false
			if dragging:
				if absf(shift) > 32: change(-1 if shift > 0 else 1)
			else: m.press(p)
			shift = 0
		return true
	if e is InputEventMouseMotion and pointer:
		var p: Vector2 = e.position - Vector2(m.ox, 0)
		if absf(p.x - down.x) > 6: dragging = true
		if dragging: shift = clampf(p.x - down.x, -180, 180)
		return true
	return false
func price_text(value: int) -> String:
	if value >= 10000: return ("%.0f만" if value % 10000 == 0 else "%.1f만") % (float(value) / 10000)
	return str(value)
func press(m, p: Vector2) -> void :
	if rects.get("back", Rect2()).has_point(p): m.start_trans("village");return
	if rects.get("left", Rect2()).has_point(p): change(-1);m.play("plop", -9);return
	if rects.get("right", Rect2()).has_point(p): change(1);m.play("plop", -9);return
	if rects.get("enter", Rect2()).has_point(p):
		if m.region_shop.is_unlocked(index) and index in m.progression.available_regions:
			m.active_region = index;m._layout();m.start_trans("fish")
		elif index not in m.progression.available_regions:
			notice = "낚시터 준비 중";notice_until = m.ui_clock + 2.5
		elif not m.progression.licensed(index):
			notice = "%s 메인 번들 완료 후 자격증 획득" % NAMES[index-1];notice_until = m.ui_clock + 3.0
		elif m.region_shop.unlock(m,index):
			m.active_region = index;m._layout();m.start_trans("fish")
		else:
			notice = "해금에 필요한 비늘이 부족해요";notice_until = m.ui_clock + 2.5
func draw(m, h: float) -> void :
	m._ui_rect(Rect2( - m.ox, 0, m.VW + 2 * m.ox, h), Color("183d4b"))
	for band in 12: m._ui_rect(Rect2( - m.ox, band * h / 12, m.VW + 2 * m.ox, h / 12 + 1), Color("163444").lerp(Color("315b60"), band / 11.0))
	var title: = Rect2(10, m.top_y, 250, 37)
	m._ui_style_box(m.hud_reference_style, title)
	m._text("낚시터 선택", title.get_center() + Vector2(0, 5), 16, Color("fff0d1"), true, 230)
	if h >= 540: m._text("%d / 6" % (index + 1), Vector2(135, m.top_y + 64), 11, Color("e6d5ad"), true, 200)
	var cy: float = clampf(h * 0.48, m.top_y + 230, h - 226) if h >= 540 else h * 0.5 + 4
	var top: float = cy - 170
	for i in 6:
		var cx: float = 135 + (i - scroll) * 238 + shift
		if cx < -120 or cx > 390: continue
		var r: = Rect2(roundf(cx - 112), roundf(top), 224, 340)
		m._ui_style_box(m.hud_reference_style, r)
		if i == index:
			var pulse: float = 0.65 + 0.25 * sin(m.ui_clock * 3)
			for d in [0, 2]:
				var border: Rect2 = r.grow(d)
				var col: = Color(0.35, 0.91, 0.86, pulse * (1 if d == 0 else 0.22))
				m._ui_line(border.position, border.position + Vector2(border.size.x, 0), col, 1)
				m._ui_line(border.position, border.position + Vector2(0, border.size.y), col, 1)
				m._ui_line(border.end, border.end - Vector2(border.size.x, 0), col, 1)
				m._ui_line(border.end, border.end - Vector2(0, border.size.y), col, 1)
		var image_pos: Vector2 = r.position + Vector2(8, 8)
		m._ui_texture(images[i], image_pos, Color.WHITE if m.region_shop.is_unlocked(i) else Color(0.48, 0.53, 0.59, 1))
		if not m.region_shop.is_unlocked(i): m._ui_texture(chains, image_pos + Vector2(0, 84))
		var name: String = m._ui_wrap(NAMES[i], 12, 204, 2)
		m._text(name, Vector2(cx, r.position.y + 268), 12, Color("fff0d1"), true, 204)
		m._text(m._ui_wrap(CONCEPT[i], 8, 204, 1), Vector2(cx, r.position.y + 287), 8, Color("d5c8b2"), true, 204)
		var button: = Rect2(r.position + Vector2(12, 298), Vector2(200, 29))
		m._ui_style_box(m.sb_primary if m.region_shop.is_unlocked(i) else m.sb_btn, button)
		m._text("입장하기" if m.region_shop.is_unlocked(i) else "준비 중" if i not in m.progression.available_regions else "자격증 필요" if not m.progression.licensed(i) else "해금 · %s 비늘" % price_text(PRICES[i]), button.get_center() + Vector2(0, 5), 11, Color("fff0d1") if m.region_shop.is_unlocked(i) else Color("62584b"), true, 188)
		if i == index: rects.enter = button
	var left: = Rect2(1, cy - 15, 24, 32); var right: = Rect2(245, cy - 15, 24, 32)
	for item in [[left, "<"], [right, ">"]]:
		m._ui_style_box(m.sb_chip, item[0]);m._text(item[1], item[0].get_center() + Vector2(0, 5), 14, Color("513b29"), true, 20)
	rects.left = left;rects.right = right
	var note: String = notice if m.ui_clock < notice_until else "좌우로 밀어 낚시터 선택하기"
	if h >= 540: m._text(m._ui_wrap(note, 10, 244, 2), Vector2(135, top + 364), 10, Color("e6d5ad"), true, 244)
	var back: = Rect2(60, h - m.bot_pad - 93, 150, 32)
	m._ui_style_box(m.sb_btn, back);m._text("뒤로가기", back.get_center() + Vector2(0, 5), 12, Color("513b29"), true, 138)
	rects.back = back
