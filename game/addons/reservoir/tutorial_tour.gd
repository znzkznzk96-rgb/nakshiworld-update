extends RefCounted
# 첫 플레이 튜토리얼(5단계): 마을 둘러보기 → 미끼 받기 → 낚시터 가기 → 첫 낚시 → 판매·도감.
# 컷신의 흰 고양이가 한 줄 말풍선으로 안내하고, 눌러야 할 버튼만 밝게 비추고(스포트라이트) 그 버튼만 눌리게 한다.
# 진행은 TUT.tour(0~4, DONE)에 저장돼 앱을 껐다 켜도 이어진다. 끝나거나 건너뛰면 우편 선물(TUT.tour_mail).
const DONE := 99
const STEPS := 5
const PORTRAITS := {"idle": preload("res://art/tutorial/cat_idle.png"), "happy": preload("res://art/tutorial/cat_happy.png"), "wow": preload("res://art/tutorial/cat_wow.png")}
const PAW := preload("res://art/tutorial/paw.png")   # PixelLab 고양이 앞발(아래를 가리킴)
const POP_COLORS := [Color("ffd166"), Color("ff8fab"), Color("8be0c8"), Color("9fd3ff"), Color("ffffff")]
const BUILD_UP := 2      # village.gd BUILD 낚시 상점
const BUILD_WORK := 1    # village.gd BUILD 어시장
const BAIT_GIFT := 3
const TAB_LINES := {
	"sell": "여긴 장비 탭! 돈을 벌어 찌→바늘→줄을 해금할수록 더 높은 별 물고기가 나와!",
	"pouches": "어혼 탭에선 병사를 키울 어혼 주머니를 팔아. 다음 탭을 눌러 봐!",
	"gear_sell": "팔기 탭에선 벗어 둔 장비를 팔아. 이제 미끼 탭을 눌러 봐!",
}

var target := Rect2()        # 지금 눌러야 할 곳(없으면 자유롭게 조작)
var point := Rect2()         # 앞발이 가리킬 칸(없으면 target). 설명 중인 칸과 다음에 누를 칸을 같이 밝힐 때 쓴다
var line := ""
var face := "idle"
var bounce_t := -9.0
var pop_t := -9.0
var pop_text := ""
var cam0 := 0.0
var gold0 := 0
var confirm := false
var finish_t := -1.0
var centered_work := false
var step_t := 0.0
var rects := {}
var overlay: Node2D
const BAND_H := 62.0
var end_t := -1.0         # 끝 인사 띠를 보여 주기 시작한 때
const END_LINE := "이제 혼자서도 괜찮겠다냥! 완료 선물은 우편함에 넣어 뒀어."
var force := false        # 검사용: PC에서도 시작
var hint := ""             # 지금 보여 주는 중간 안내 키(강제 아님, 한 번만)
var hint_t := 0.0
var hint_page := 0
## 중간 안내: [키, 쪽들]. 쪽 = [문구, 대상]. 대상 = "mail"/"guide"/"menu" 또는 마을 건물 번호. 마지막 쪽은 가이드로 안내한다.
const HINTS := [
	["mail", [["우편함에 완료 선물이 왔어! 눌러서 받아 봐.", "mail"]]],
	["moves", [["만난 몸짓은 메뉴 → 설정 → 몸짓 도감에서 다시 볼 수 있어.", "menu"]]],
	["aqua", [["물고기를 수족관에 넣으면 쉬는 동안에도 비늘을 벌어!", 4], ["수족관 칸을 눌러 가방의 물고기를 넣어 봐.\n더 궁금한 건 가이드 책!", "guide"]]],
	["forge", [["비늘이 모였네! 대장간에서 낚싯대를 강화할 수 있어.", 3], ["강화는 비늘과 비늘조각이 들어.\n높은 단계는 실패하면 내려갈 수도 있어!", 3], ["보호권 같은 자세한 건 가이드 책에서 읽어 봐!", "guide"]]],
	["alch", [["어혼 2개가 모였어! 합치면 병사가 한 마리 나와.", "menu"], ["메뉴 → 연성 → 어혼 연성을 눌러 봐.", "menu"], ["위쪽 칸을 고르고 아래 어혼을 눌러\n재료 2개를 정해! 같은 속성도 돼.", "menu"], ["두 어혼의 조합으로 병사 종류가 정해져.\n처음 보는 병사는 물음표로 나와!", "menu"], ["더 궁금한 건 가이드 책을 읽어 봐!", "guide"]]],
	["explore", [["병사 3마리가 모였어! 탐험은\n3마리가 있어야 출발할 수 있어.", "menu"], ["탐험 → 병사 배치에서 3마리를 편성해.\n카드는 왼쪽부터 뒤·중간·앞이야.", "menu"], ["그다음 메뉴 → 탐험에서 노선을 골라\n보내면 돼. 탐험 중에도 낚시는 OK!", "menu"], ["더 궁금한 건 가이드 책을 읽어 봐!", "guide"]]],
	["soldier_up", [["병사는 강화할 수 있어! 비늘과 같은 속성\n어혼이 들고 +3까지 올라가.", "menu"], ["연성 화면에서 병사를 골라 강화해.\n탐험 중에는 못 하니까 조심!", "menu"], ["더 궁금한 건 가이드 책을 읽어 봐!", "guide"]]],
	["merge", [["같은 별 병사 둘이 +3이 됐네!\n연성 → 병사 합성으로 별을 올려.", "menu"], ["1성 둘은 2성, 2성 둘은 3성이 돼.\n재료 병사는 사라지니 확인창을 봐!", "menu"], ["아끼는 병사는 잠가 두면 안전해.\n더 궁금한 건 가이드 책!", "guide"]]],
	["pet", [["진주 10개면 펫 오두막에서 한 번 뽑을 수 있어!", 7], ["오두막에서 뽑기를 누르면 돼.\n더 궁금한 건 가이드 책!", "guide"]]],
	["guide", [["궁금한 건 가이드 책에 다 있어. 언제든 눌러 봐!", "guide"]]],
]

func active(m) -> bool:
	return int(m.TUT.get("tour", DONE)) < DONE

func step(m) -> int:
	return int(m.TUT.get("tour", DONE))

## 저장을 읽은 뒤 한 번: 새 플레이어는 0단계부터, 기존 플레이어는 완료 처리하고 우편 선물만 준다.
func setup(m) -> void:
	# 컷신과 같이 폰에서만 시작한다. PC 실행·검사 장면은 새 저장이어도 끼어들지 않는다(보려면 --tour)
	var enabled: bool = OS.has_feature("mobile") or "--tour" in OS.get_cmdline_user_args() or force
	if not m.TUT.has("tour") and enabled:
		m.TUT.tour = 0 if m.intro_new_player else DONE
		if not m.intro_new_player: m.TUT.tour_mail = true
		m._save_tut()
	m.mailbox.tour_mail = bool(m.TUT.get("tour_mail", false))

func _go(m, i: int) -> void:
	m.TUT.tour = i;m._save_tut();step_t = m.ui_clock
	if i == 0: cam0 = m.V.camera_x
	if i == 4: gold0 = m.gold

func _finish(m) -> void:
	m.TUT.tour = DONE;m.TUT.tour_mail = true;m._save_tut()
	m.mailbox.tour_mail = true;target = Rect2();line = "";confirm = false;end_t = m.ui_clock

func _pop(m, text: String) -> void:
	pop_t = m.ui_clock;pop_text = text;face = "happy"
	m.audio_feedback.sound(m, "catch", -6.0, 1.2)

func _blocked(m) -> bool:
	# 제목 화면·장면 전환·컷신 중에는 기다린다
	return m.title_open or m.title_screen.leaving or not m.trans.is_empty() or is_instance_valid(m.intro)

## 화면 좌표의 건물 칸(마을 지도 → 화면)
func _row(v, key: String) -> Rect2:
	for row in v.rects.get("rows", []):
		if row[1] == key: return row[0]
	return Rect2()

func _building(m, i: int) -> Rect2:
	var v = m.V;var b: Array = v.BUILD[i]
	var h: float = m.get_viewport_rect().size.y
	var o: Vector2 = v.map_origin(m, h);var anchor := Vector2(135, v.map_y)
	var p0: Vector2 = (b[2].position + o - anchor) * v.zoom + anchor
	return Rect2(p0, b[2].size * v.zoom)

func _center_on(m, i: int) -> void:
	var v = m.V;var b: Array = v.BUILD[i]
	v.camera_x = b[2].get_center().x - 135.0;v.clamp_camera(m);v.velocity = 0

func _menu_item(m, i: int) -> Rect2:
	if not m.menu_open: return m.ui_rects.get("menu", Rect2())
	var items: Array = m.ui_rects.get("m_items", [])
	return items[i] if i < items.size() else Rect2()

func update(m, _dt: float) -> void:
	target = Rect2();point = Rect2()
	if not active(m):
		if finish_t > 0 and m.ui_clock - finish_t > 2.0: finish_t = -1.0
		_update_hint(m)
		return
	if _blocked(m): line = "";return
	if m.ui_clock - pop_t > 1.4: face = "idle"
	var v = m.V
	match step(m):
		0:   # 마을 둘러보기: 좌우로 밀면 끝
			if m.scene != "village" or v.shop != "": return
			if step_t <= 0.0: _go(m, 0)
			line = "여기가 낚시월드 마을이야. 화면을 좌우로 밀어 봐!"
			if absf(v.camera_x - cam0) > 60.0:
				m.audio_feedback.sound(m, "click", -8.0, 1.5);face = "happy";_go(m, 1);_center_on(m, BUILD_UP)
		1:   # 낚시 상점에서 미끼 선물 받기
			if m.scene != "village": return
			if v.shop == "":
				if m.TUT.get("tour_bait", false): _go(m, 2);return
				line = "낚시 상점에 가 보자. 미끼를 챙겨 줄게!";target = _building(m, BUILD_UP)
			elif v.shop == "up":
				var done: bool = m.TUT.get("tour_bait", false)
				if not done and v.tab != "bait":   # 탭을 하나씩 짚어 주고 마지막에 미끼 탭으로
					var nxt: String = {"pouches": "gear_sell", "gear_sell": "bait"}.get(v.tab, "pouches")
					line = TAB_LINES.get(v.tab, TAB_LINES.sell);point = _row(v, "tab:" + nxt);target = point
					var cur: Rect2 = _row(v, "tab:" + v.tab)   # 설명 중인 탭도 어둡게 가리지 않고 같이 밝힌다
					if cur.size != Vector2.ZERO and point.size != Vector2.ZERO: target = cur.merge(point)
				else:
					if not done:
						m.bait += BAIT_GIFT;m.TUT.tour_bait = true;m._save_tut();m._save_game()
						m.show_toast("고양이가 미끼 %d개를 줬어요!" % BAIT_GIFT, Color("ffd166"));face = "happy"
					line = "미끼가 있으면 입질이 빨라져! %d개 선물이야." % BAIT_GIFT;target = v.rects.get("close", Rect2())
			else: target = v.rects.get("close", Rect2());line = "앗, 여긴 아니야. 닫고 낚시 상점으로 가자."
		2:   # 메뉴 → 낚시터 → 첫 낚시터 들어가기
			if m.scene == "fish": _go(m, 3);return
			if m.scene == "spots":
				line = "첫 번째 낚시터로 들어가자!";target = m.spots.rects.get("enter", Rect2());return
			if v.shop != "": target = v.rects.get("close", Rect2());line = "상점을 닫고 낚시터로 가자.";return
			line = "메뉴를 열어 낚시터로 가 보자!" if not m.menu_open else "낚시터를 눌러!"
			target = _menu_item(m, 0)
		3:   # 첫 낚시: 기존 연습 붕어. 낚시 조작은 막지 않는다
			if m.scene != "fish": return
			if m.lesson_open: line = "";return
			match m.S.phase:
				"idle":
					if m.TUT.get("tour_caught", false): _go(m, 4);return
					line = "화면을 눌러 낚싯대를 던져 봐!"
				"wait", "pre", "hook": line = "찌가 쏙 들어가면 바로 눌러!"
				"fight", "catch": line = ""
				"fail": line = "괜찮아, 다시 던져 보자!";face = "wow"
				"result":
					if m.S.get("ok", false):
						if not m.TUT.get("tour_caught", false):
							m.TUT.tour_caught = true;m._save_tut();_pop(m, "첫 낚시 성공!")
						line = "잡았다! '보관통에 넣기'를 눌러 챙기자.";target = m.ui_rects.get("keep", Rect2())
		4:   # 마을로 → 어시장에서 팔기 → 도감 열기
			if m.personal_dex.opened:
				if finish_t < 0.0: finish_t = m.ui_clock;_pop(m, "도감 등록!")
				line = "방금 잡은 물고기가 도감에 올라갔어!"
				if m.ui_clock - finish_t > 2.2: _finish(m)
				return
			if m.scene == "fish":
				line = "이제 마을로 돌아가서 팔아 보자." if not m.menu_open else "마을을 눌러!"
				target = _menu_item(m, 0) if m.S.phase in ["idle", "result"] else Rect2();return
			if m.scene != "village": return
			if not m.TUT.get("tour_sold", false):
				if m.gold > gold0 or m.bag.is_empty(): m.TUT.tour_sold = true;m._save_tut();face = "happy"
				elif not v.commerce.pending.is_empty(): line = "확인을 누르면 팔려!";return
				elif v.shop == "work":
					line = "'모두 팔기'를 눌러!"
					for row in v.rects.get("rows", []):
						if row[1] == "sellall": target = row[0]
					return
				elif v.shop != "": target = v.rects.get("close", Rect2());line = "여긴 아니야. 어시장으로 가자.";return
				else:
					if not centered_work: centered_work = true;_center_on(m, BUILD_WORK)
					line = "어시장에서 물고기를 팔 수 있어!";target = _building(m, BUILD_WORK);return
			if v.shop != "": line = "판매 완료! 상점을 닫자.";target = v.rects.get("close", Rect2());return
			line = "마지막으로 도감을 열어 보자!" if not m.menu_open else "도감을 눌러!"
			target = _menu_item(m, 2)

func _hint_ready(m, k: String) -> bool:
	var ex = m.expedition.data
	match k:
		"mail": return m.mailbox.tour_mail and not ("tutorial-reward-163" in m.testing_grants)
		"moves": return m.TUT.seen.size() >= 2
		"aqua": return m.bag.size() >= 3
		"forge": return m.gold >= m.V.enhancement.cost(m.forge_lv, m.rod_lv) and m.souls >= m.V.enhancement.soul_cost(m.rod_lv, m.forge_lv)
		"alch": return int(ex.souls.reduce(func(a, b): return a + int(b), 0)) >= 2 and ex.soldiers.is_empty()   # 연성 1회 = 어혼 2개
		"explore": return ex.soldiers.size() >= 3 and ex.completed.is_empty()   # 탐험은 병사 3마리가 있어야 출발
		"pet": return m.pearl >= 10 and m.pet_hut.get("e", []).is_empty()
		"soldier_up": return ex.soldiers.size() >= 3 and "explore" in m.TUT.get("hints", []) and ex.soldiers.any(func(u): return int(u.level) < 3)
		"merge": return _can_merge(ex)
		"guide": return m.TUT.get("hints", []).size() >= 3
	return false

func _can_merge(ex) -> bool:
	for i in ex.soldiers.size():
		var a = ex.soldiers[i]
		if int(a.level) < 3 or int(a.star) >= 3: continue
		for j in range(i + 1, ex.soldiers.size()):
			var b = ex.soldiers[j]
			if int(b.star) == int(a.star) and int(b.level) >= 3: return true
	return false

func _hint_target(m, what) -> Rect2:
	if what is int: return _building(m, what)
	match what:
		"mail": return m.mailbox.button
		"guide": return m.guide.button
		"menu": return m.ui_rects.get("menu", Rect2())
	return Rect2()

## 마을에서 아무 창도 안 열렸을 때만, 조건이 된 안내를 하나씩 6초 보여 준다. 누르는 것은 막지 않는다.
func _update_hint(m) -> void:
	if not m.TUT.has("tour"): return   # 튜토리얼을 시작하지 않은 실행(PC·검사)에는 안내도 없다
	var free_view: bool = m.scene == "village" and m.V.shop == "" and not m.menu_open and not m.market_open and not m.settings_open \
		and not m.mailbox.opened and not m.guide.opened and not m.personal_dex.opened and m.expedition.opened == "" and not _blocked(m)
	if hint != "":
		if not free_view: hint = ""
		elif m.ui_clock - hint_t > 8.0: _hint_next(m)
		return
	if not free_view or finish_t > 0 or (end_t > 0 and m.ui_clock - end_t < 3.5): return
	var seen: Array = m.TUT.get("hints", [])
	for h in HINTS:
		if h[0] in seen or not _hint_ready(m, h[0]): continue
		hint = h[0];hint_t = m.ui_clock;hint_page = 0;face = "happy" if h[0] == "mail" else "idle"
		if h[1].size() == 1: _hint_seen(m)
		m.audio_feedback.sound(m, "click", -10.0, 1.4)
		return

func _hint_seen(m) -> void:
	var seen: Array = m.TUT.get("hints", [])
	if not hint in seen: seen.append(hint);m.TUT.hints = seen;m._save_tut()

## 다음 쪽으로. 마지막 쪽이면 닫고 본 것으로 기록한다.
func _hint_next(m) -> void:
	var pages: Array = []
	for x in HINTS: if x[0] == hint: pages = x[1]
	hint_page += 1;hint_t = m.ui_clock
	if hint_page >= pages.size(): _hint_seen(m);hint = "";hint_page = 0
	elif hint_page == pages.size() - 1: _hint_seen(m)
	else: m.audio_feedback.sound(m, "click", -12.0, 1.2)

func _paint_hint(m, h: float) -> void:
	var pages: Array = []
	for x in HINTS: if x[0] == hint: pages = x[1]
	if pages.is_empty(): return
	var row: Array = pages[mini(hint_page, pages.size() - 1)]
	var r: Rect2 = _hint_target(m, row[1])
	if r.size != Vector2.ZERO and Rect2(0, 0, 270, h).intersects(r):
		var c := Color(1, 0.88, 0.45, 0.55 + 0.45 * sin(m.ui_clock * 6.0))
		var o := r.grow(3)
		m._ui_rect(Rect2(o.position, Vector2(o.size.x, 2)), c);m._ui_rect(Rect2(o.position.x, o.end.y - 2, o.size.x, 2), c)
		m._ui_rect(Rect2(o.position, Vector2(2, o.size.y)), c);m._ui_rect(Rect2(o.end.x - 2, o.position.y, 2, o.size.y), c)
	line = row[0];target = r
	_bubble(m, h)
	line = "";target = Rect2()

## 누른 곳이 지금 단계에서 허용되는지. true면 게임은 그 입력을 무시한다.
func intercept(m, p: Vector2) -> bool:
	if hint != "":   # 여러 쪽 안내: 누르면 다음 쪽(그 입력은 막음), 마지막 쪽이나 한 쪽짜리는 닫히고 입력은 그대로 게임으로 간다
		var n := 1
		for x in HINTS: if x[0] == hint: n = x[1].size()
		if hint_page < n - 1: _hint_next(m);return true
		hint = "";hint_page = 0
	if not active(m) or _blocked(m): return false
	if confirm:
		if rects.get("yes", Rect2()).has_point(p): _finish(m);m.lesson_open = false;m.audio_feedback.sound(m, "click", -8.0)
		elif rects.get("no", Rect2()).has_point(p): confirm = false
		return true
	if rects.get("skip", Rect2()).grow(4).has_point(p): confirm = true;m.audio_feedback.sound(m, "click", -8.0);return true
	if m.lesson_open or target.size == Vector2.ZERO: return false
	if target.grow(4).has_point(p): return false
	bounce_t = m.ui_clock;m.audio_feedback.sound(m, "click", -12.0, 0.8)
	return true

## 화면 위 덮개(어둡게·밝은 구멍·반짝 테두리·손가락·고양이 말풍선·진행 점·건너뛰기·팡). 글자까지 덮도록 별도 층에 그린다.
func draw(m, h: float) -> void:
	if overlay == null and m.text_layer != null:
		overlay = Node2D.new();overlay.set_script(load("res://text_layer.gd"));overlay.z_index = 50
		m.text_layer.get_parent().add_child(overlay)   # 글자 층 위(형제로 뒤에 붙임)
	if overlay == null: return
	overlay.position.x = m.ox
	var saved_cmd: Array = m.ui_commands;var saved_txt: Array = m.text_items
	m.ui_commands = [];m.text_items = []
	rects.skip = Rect2()
	if active(m) and not _blocked(m) and not m.lesson_open: _paint(m, h)
	elif hint != "": _paint_hint(m, h)
	elif end_t > 0 and m.ui_clock - end_t < 3.5 and not _blocked(m):
		line = END_LINE;face = "happy";_bubble(m, h);line = ""
	if m.ui_clock - pop_t < 1.4: _paint_pop(m, h)
	overlay.commands = m.ui_commands;overlay.items = m.text_items;overlay.queue_redraw()
	m.ui_commands = saved_cmd;m.text_items = saved_txt

func _paint(m, h: float) -> void:
	var t: float = m.ui_clock;var x0: float = -m.ox;var w: float = m.VW + 2 * m.ox
	var dim := Color(0.02, 0.03, 0.06, 0.74)
	if target.size != Vector2.ZERO:
		var r := target.grow(3)
		m._ui_rect(Rect2(x0, 0, w, r.position.y), dim)
		m._ui_rect(Rect2(x0, r.end.y, w, h - r.end.y), dim)
		m._ui_rect(Rect2(x0, r.position.y, r.position.x - x0, r.size.y), dim)
		m._ui_rect(Rect2(r.end.x, r.position.y, x0 + w - r.end.x, r.size.y), dim)
		var b: float = 1.0 + (2.0 if t - bounce_t < 0.25 else 0.0)
		var a: float = 0.55 + 0.45 * sin(t * 6.0)
		var o := r.grow(roundf(b))
		var c := Color(1, 0.88, 0.45, a)
		m._ui_rect(r, Color(1, 0.96, 0.78, 0.07 + 0.06 * a))   # 안쪽은 밝게
		var hl := o.grow(2);var hc := Color(1, 0.85, 0.4, 0.3 * a)   # 바깥 은은한 빛
		m._ui_rect(Rect2(hl.position, Vector2(hl.size.x, 2)), hc);m._ui_rect(Rect2(hl.position.x, hl.end.y - 2, hl.size.x, 2), hc)
		m._ui_rect(Rect2(hl.position, Vector2(2, hl.size.y)), hc);m._ui_rect(Rect2(hl.end.x - 2, hl.position.y, 2, hl.size.y), hc)
		m._ui_rect(Rect2(o.position, Vector2(o.size.x, 2)), c);m._ui_rect(Rect2(o.position.x, o.end.y - 2, o.size.x, 2), c)
		m._ui_rect(Rect2(o.position, Vector2(2, o.size.y)), c);m._ui_rect(Rect2(o.end.x - 2, o.position.y, 2, o.size.y), c)
		# 앞발은 칸의 오른쪽 위 모서리 바깥에서 비스듬히 찌른다(간판·글자를 가리지 않게). 화면 끝이면 뒤집는다
		var pr: Rect2 = point.grow(3) if point.size != Vector2.ZERO else r
		var fx: bool = pr.end.x > 236.0            # 오른쪽에 자리가 없으면 왼쪽 위에서
		var fy: bool = pr.position.y < m.top_y + 34   # 위에 자리가 없으면 아래에서
		var corner := Vector2(pr.position.x + 3 if fx else pr.end.x - 3, pr.end.y - 3 if fy else pr.position.y + 3)
		var dir := Vector2(-1.0 if fx else 1.0, 1.0 if fy else -1.0)   # 모서리에서 앞발 쪽으로
		# 둥실 떠다니다가 1.4초마다 톡 찌르고, 찌른 모서리에 반짝 물결
		var ph: float = fposmod(t, 1.4)
		var d: float = 5.0 + 2.5 * sin(t * 3.0)
		if ph > 1.1: d = lerpf(d, -1.0, sin((ph - 1.1) / 0.3 * PI))
		if ph > 1.2:
			var k: float = (ph - 1.2) / 0.2;var rc := Color(1, 0.95, 0.7, 0.85 * (1.0 - k));var q: float = roundf(3 + 7 * k)
			for v in [Vector2(-q, 0), Vector2(q, 0), Vector2(0, -q), Vector2(0, q)]:
				m._ui_rect(Rect2((corner + v).round() - Vector2(1, 1), Vector2(2, 2)), rc)
		_finger(m, corner + (dir * d).round(), fx, fy)
	elif step(m) == 0:
		# 좌우로 밀기: 양쪽 도트 화살표가 바깥으로 들썩이고, 앞발이 그 사이를 오간다
		var cyy: float = roundf(h * 0.5);var pu: float = roundf(absf(sin(t * 3.0)) * 3.0)
		_arrow(m, Vector2(16 - pu, cyy), -1);_arrow(m, Vector2(254 + pu, cyy), 1)
		var sx: float = 135.0 + roundf(sin(t * 2.2) * 50.0)
		_finger(m, Vector2(sx, cyy + 6), sin(t * 2.2 + 1.57) < 0.0, false)
	if line != "": _bubble(m, h)
	else: rects.skip = Rect2()
	if confirm: _confirm(m, h)

## 앞발 그림(↙로 찌름)의 발끝이 tip에 닿게 그린다. fx/fy면 좌우/상하로 뒤집는다
const PAW_TIP := Vector2(2, 23)
func _finger(m, tip: Vector2, fx: bool, fy: bool) -> void:
	var sz := PAW.get_size()
	var off := Vector2(sz.x - 1 - PAW_TIP.x if fx else PAW_TIP.x, sz.y - 1 - PAW_TIP.y if fy else PAW_TIP.y)
	var p := (tip - off).round()
	m._ui_texture_rect(PAW, Rect2(p.x + (sz.x if fx else 0.0), p.y + (sz.y if fy else 0.0), -sz.x if fx else sz.x, -sz.y if fy else sz.y))

## 도트 화살표(◀/▶): 크림색 몸통에 진한 갈색 테두리. c는 뾰족한 끝
func _arrow(m, c: Vector2, side: int) -> void:
	for j in 11:   # 테두리 삼각형
		m._ui_rect(Rect2(c.x - j * side, c.y - j, 1, j * 2 + 1), Color("2a1610"))
	for j in 8:   # 안쪽
		m._ui_rect(Rect2(c.x - (j + 2) * side, c.y - j, 1, j * 2 + 1), Color("fff4dc"))

func _band_top(m, h: float) -> bool:
	if m.scene == "fish" and m.S.phase in ["wait", "pre", "hook"]: return true
	return target.size != Vector2.ZERO and target.grow(4).end.y > _band_y(m, h)

## 아래 띠 윗선: 얇은 띠를 하단 메뉴 줄 바로 위에 얹는다(메뉴 줄은 어둡게만 가린다)
func _band_y(m, h: float) -> float:
	var menu: Rect2 = m.ui_rects.get("menu", Rect2())
	var y: float = h - m.bot_pad - BAND_H
	if menu.size != Vector2.ZERO and menu.position.y - 6 < y + BAND_H: y = menu.position.y - 6 - BAND_H
	return roundf(y)

func _bubble(m, h: float) -> void:
	var x0: float = -m.ox;var w: float = m.VW + 2 * m.ox
	var top: bool = _band_top(m, h)
	var by: float = _band_y(m, h)
	var band := Rect2(x0, by, w, BAND_H)
	var cy: float = by   # 내용 윗선
	var near := not top
	var bottom_edge: float = by + BAND_H   # 건너뛰기를 붙일 띠 아랫선
	if not top and target.size == Vector2.ZERO:   # 강조 칸이 없을 때도 띠 아래 메뉴 줄은 어둡게
		m._ui_rect(Rect2(x0, by + BAND_H, w, h - by - BAND_H), Color(0.02, 0.03, 0.06, 0.74))
	if top:
		# 눌러야 할 곳이 아래쪽이면 맨 위로 보내지 않고 그 바로 위에 띄운 뒤 꼬리로 가리킨다
		var ay: float = roundf(target.grow(4).position.y - PAW.get_height() - 10 - BAND_H)   # 띠와 칸 사이에 앞발
		if target.size != Vector2.ZERO and ay > m.top_y + 70 and not (m.scene == "fish" and m.S.phase in ["wait", "pre", "hook"]):
			band = Rect2(x0, ay, w, BAND_H);cy = ay;near = true;bottom_edge = cy + BAND_H   # 칸 바로 위에 띄운다
		else:
			band = Rect2(x0, 0, w, m.top_y + BAND_H + 4);cy = m.top_y + 2;bottom_edge = cy + BAND_H
	m._ui_style_box(m.sb_panel, band.grow_individual(4, 2 if not top else 4, 4, 4 if not top else 0) if not near else band.grow_individual(4, 0, 4, 0))
	var tex: Texture2D = PORTRAITS.get(face, PORTRAITS.idle)
	var hop: float = -2.0 if m.ui_clock - pop_t < 0.3 else 0.0
	m._ui_texture_rect(tex, Rect2(6, cy + 5 + hop, 48, 48))   # 고양이 몸통이 띠 세로 가운데
	if active(m):
		var cur: int = step(m)
		for i in STEPS:
			m._ui_rect(Rect2(60 + i * 9, cy + 11, 5, 5), Color("e0a93a") if i < cur else (Color("7a5232") if i == cur else Color(0.48, 0.32, 0.2, 0.3)))
		rects.skip = Rect2(196, bottom_edge - 28, 66, 20)   # 늘 띠 오른쪽 아래 같은 자리(누르는 칸은 넉넉히, 그림은 글자만)
		m._text("건너뛰기 >", Vector2(rects.skip.get_center().x, bottom_edge - 13), 10, Color("8c6a48"), true, 66)
	var txt: String = m._ui_wrap(line, 10, 200, 2)
	m._text(txt, Vector2(160, cy + (26 if "\n" in txt else 35)), 10, Color("382619"), true, 200)   # 글자도 세로 가운데

func _confirm(m, h: float) -> void:
	m._ui_rect(Rect2(-m.ox, 0, m.VW + 2 * m.ox, h), Color(0.02, 0.03, 0.06, 0.6))
	var r := Rect2(35, h * 0.5 - 70, 200, 130)
	m._ui_style_box(m.sb_panel, r)
	m._text("튜토리얼을 건너뛸까요?", Vector2(135, r.position.y + 30), 12, Color("382619"), true, 180)
	m._text("완료 선물은 우편함으로 보내 드려요", Vector2(135, r.position.y + 56), 9, Color("68533d"), true, 180)
	rects.no = Rect2(48, r.end.y - 45, 82, 30);rects.yes = Rect2(140, r.end.y - 45, 82, 30)
	m._ui_style_box(m.sb_btn, rects.no);m._text("계속하기", rects.no.get_center() + Vector2(0, 4), 10, Color("513b29"), true, 76)
	m._ui_style_box(m.sb_btn, rects.yes);m._text("건너뛰기", rects.yes.get_center() + Vector2(0, 4), 10, Color("513b29"), true, 76)

## 큰 팡: 첫 낚시 성공·도감 등록 때만
func _paint_pop(m, h: float) -> void:
	var k: float = m.ui_clock - pop_t
	var c := Vector2(135, h * 0.38)
	var s: float = lerpf(0.4, 1.15, k / 0.18) if k < 0.18 else (lerpf(1.15, 1.0, (k - 0.18) / 0.12) if k < 0.3 else 1.0)
	var a: float = clampf((1.4 - k) / 0.3, 0.0, 1.0)
	var sz := (Vector2(150, 34) * s).round()
	var box := Rect2((c - sz / 2.0).round(), sz)
	m._ui_style_box(m.sb_btn, box)
	if k > 0.12: m._text(pop_text, c + Vector2(0, 5), 14, Color(0.31, 0.2, 0.1, a), true, 150)
	for i in 30:
		var ang: float = TAU * i / 30.0 + 0.4 * sin(i * 5.0)
		var sp: float = 80.0 + 70.0 * fposmod(i * 0.618, 1.0)
		var p: Vector2 = c + Vector2(cos(ang), sin(ang) * 0.7) * (40.0 + sp * k) + Vector2(0, 120.0 * k * k)
		var col: Color = POP_COLORS[i % POP_COLORS.size()];col.a = clampf(1.0 - k / 1.2, 0.0, 1.0)
		m._ui_rect(Rect2(p.round(), Vector2(3, 3) if i % 3 == 0 else Vector2(2, 2)), col)
