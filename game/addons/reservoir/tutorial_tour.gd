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
const PART_LINES := [   # 장비 탭 파츠 설명(찌·바늘·줄·릴·주인 물고기)
	"찌는 ★2 물고기가 입질하게 해 줘!\n비늘로 살 수 있어.",
	"바늘은 ★3 물고기! 찌를 먼저\n장착해야 살 수 있어.",
	"줄은 ★4 물고기! 앞의 파츠도\n전부 장착해야 해.",
	"릴은 마지막 파츠야! 다 갖추면\n주인 물고기에 도전할 수 있어.",
	"주인은 낚시터마다 있는 대물이야.\n물고기를 잡아 게이지를 100% 채워!",
]

var target := Rect2()        # 지금 눌러야 할 곳(없으면 자유롭게 조작)
var sub := -1                # 낚시 상점 설명 순서(-1이면 아직 정하지 않음)
var explain := false         # 설명 쪽: 앞발 없이 밝게만 보여 주고, "다음"을 눌러야 넘어간다
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
var walk := ""              # 화면을 따라가며 짚어 주는 안내(WALKS)의 키
var tap_adv := false        # 이번 칸을 누르면 다음 단계로
var soft := false           # 강조만 하고 다른 곳 입력은 막지 않음
var gate_frame := -1
var gate_res := false
var walk_t := -1.0
var lv0 := -1
## 중간 안내(말풍선 한 번): [키, 문구, 대상]. 대상 = "mail"/"guide"/"menu"
const HINTS := {
	"mail": ["우편함에 완료 선물이 왔어! 눌러서 받아 봐.", "mail"],
	"moves": ["만난 몸짓은 메뉴 → 설정 → 몸짓 도감에서 다시 볼 수 있어.", "menu"],
	"guide": ["궁금한 건 가이드 책에 다 있어. 언제든 눌러 봐!", "guide"],
}
## 순서대로 조건이 되면 하나씩. 아래 WALKS에 있는 것은 실제 화면을 따라가며 짚어 주는 안내(누르는 건 막지 않고 단계가 따라간다)
const HINT_ORDER := ["mail", "moves", "aqua", "forge", "alch", "explore", "soldier_up", "merge", "pet", "guide"]
const WALKS := ["aqua", "forge", "alch", "explore", "soldier_up", "merge", "pet"]
## 건물 안내: [건물 번호, 건물 앞에서 가리킬 말]. 안에서의 단계는 _forge_steps/_aqua_steps/_pet_steps
const BLD_WALKS := {
	"aqua": [4, "수족관에 물고기를 넣어 볼까? 눌러 봐!"],
	"forge": [3, "비늘이 모였네! 대장간을 눌러 봐."],
	"pet": [7, "진주가 모였어! 펫 오두막을 눌러 봐."],
}

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
	m.TUT.tour = i;m._save_tut();step_t = m.ui_clock;sub = -1
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
	target = Rect2();point = Rect2();explain = false;tap_adv = false;soft = false
	if not active(m):
		if finish_t > 0 and m.ui_clock - finish_t > 2.0: finish_t = -1.0
		if walk != "": _walk_update(m)
		else: _update_hint(m)
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
				if sub < 0 and m.TUT.get("tour_bait", false): sub = 12
				if sub >= 12: _go(m, 2);return
				if sub < 7: sub = 0
				line = "낚시 상점에 가 보자. 하나씩 알려 줄게!";target = _building(m, BUILD_UP)
			elif v.shop == "up":
				if sub < 0: sub = 12 if m.TUT.get("tour_bait", false) else 0
				_shop_up(m, v)
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

## 낚시 상점: 장비 탭 → 파츠 하나씩 → 주인 물고기 → 미끼 탭(선물) → 어혼 탭 → 팔기 탭 → 닫기. 설명 쪽은 "다음"으로 넘긴다.
func _part_rect(v, slot: int) -> Rect2:
	return v.rects.get("part:%d" % slot, Rect2())

func _need_tab(v, key: String, ask: String) -> bool:
	if v.tab == key: return false
	line = ask;target = _row(v, "tab:" + key)
	return true

func _shop_up(m, v) -> void:
	if sub <= 5 and _need_tab(v, "sell", "먼저 장비 탭을 눌러 봐!"): return
	if sub == 0:
		line = "여긴 장비 탭이야! 파츠를 사서\n더 높은 별 물고기를 낚아 보자.";target = _row(v, "tab:sell");explain = true
	elif sub <= 5:
		line = PART_LINES[sub - 1];target = _part_rect(v, mini(sub - 1, 3));explain = true
	elif sub <= 7:
		if _need_tab(v, "bait", "이제 미끼 탭을 눌러 봐!"): return
		if sub == 6 and not m.TUT.get("tour_bait", false):
			m.bait += BAIT_GIFT;m.TUT.tour_bait = true;m._save_tut();m._save_game()
			m.show_toast("고양이가 미끼 %d개를 줬어요!" % BAIT_GIFT, Color("ffd166"));face = "happy"
		sub = 7
		line = "미끼가 있으면 입질이 빨라져!\n%d개 선물이야." % BAIT_GIFT
		target = v.rects.get("baitcell:0", Rect2());explain = true
	elif sub <= 9:
		if _need_tab(v, "pouches", "이번엔 어혼 탭을 눌러 봐!"): return
		sub = 9
		line = "어혼 주머니는 병사를 키우는 재료야.\n탐험에 보낼 병사가 나와!";target = _row(v, "tab:pouches");explain = true
	elif sub <= 11:
		if _need_tab(v, "gear_sell", "마지막으로 팔기 탭을 눌러 봐!"): return
		sub = 11
		line = "팔기 탭에선 안 쓰는 장비를 팔아.\n물고기는 어시장에서 팔아!";target = _row(v, "tab:gear_sell");explain = true
	else:
		line = "다 봤어! 상점을 닫고 낚시터로 가자.";target = v.rects.get("close", Rect2())

## ───────── 화면을 따라가는 안내(walk) ─────────
## 한 단계 = 지금 화면 상태를 보고 line/target을 정한다. 설명 쪽(explain)은 "다음"으로, 행동 쪽은 칸을 누르거나 상태가 바뀌면 넘어간다.
func _gate_press(m, pos: Vector2) -> bool:
	var f: int = Engine.get_process_frames()
	if gate_frame == f: return gate_res   # 같은 누름이 gate와 press에서 두 번 오더라도 한 번만 처리
	gate_frame = f;gate_res = _gate_calc(m, pos)
	return gate_res

func _gate_calc(m, pos: Vector2) -> bool:
	if rects.get("skip", Rect2()).grow(4).has_point(pos): _walk_end(m);m.audio_feedback.sound(m, "click", -8.0);return true
	if explain:
		sub += 1;face = "idle";m.audio_feedback.sound(m, "click", -8.0, 1.3)   # 설명 쪽은 어디를 눌러도 다음으로
		return true
	if soft or target.size == Vector2.ZERO: return false
	if target.grow(4).has_point(pos):
		if tap_adv: sub += 1
		return false
	bounce_t = m.ui_clock;m.audio_feedback.sound(m, "click", -12.0, 0.8)
	return true

## 창이 먼저 입력을 가져가는 화면(병사 배치 등)에서도 막고 단계가 넘어가도록, main이 맨 앞에서 부른다.
func gate(m, e: InputEvent) -> bool:
	if walk == "" or _blocked(m) or not (e is InputEventMouseButton) or e.button_index != MOUSE_BUTTON_LEFT: return false
	if e.pressed: return _gate_press(m, e.position - Vector2(m.ox, 0))
	return gate_res

func _walk_end(m) -> void:
	_mark_seen(m, walk);walk = "";sub = 0;walk_t = -1.0;lv0 = -1

func _say(txt: String, rect: Rect2) -> void:
	line = txt;target = rect;explain = true

func _do(txt: String, rect: Rect2, tap: bool = true) -> void:
	line = txt;target = rect;tap_adv = tap

## 메뉴에서 화면을 열도록 안내(메뉴 → 해당 항목)
func _w_menu(m, key: String, label: String) -> void:
	var idx := -1
	for i in m.MENU.size():
		if m.MENU[i][0] == key: idx = i
	if not m.menu_open: line = "메뉴를 열어서 %s를 눌러 봐!" % label;target = m.ui_rects.get("menu", Rect2())
	else: line = "%s를 눌러!" % label;target = _menu_item(m, idx)

## 마무리: 화면을 닫고 마을로 돌아오면 가이드 책을 가리킨다(누름은 막지 않음).
func _walk_outro(m, txt: String) -> void:
	if m.scene != "village" or m.V.shop != "" or m.expedition.opened != "" or m.menu_open or m.guide.opened: return
	if walk_t < 0.0: walk_t = m.ui_clock;face = "happy"
	line = txt;target = m.guide.button;soft = true
	if m.ui_clock - walk_t > 7.0: _walk_end(m)

func _souls_pick(d, second: bool) -> int:
	var first := -1
	for i in d.souls.size():
		if int(d.souls[i]) > 0: first = i;break
	if not second or first < 0: return first
	if int(d.souls[first]) >= 2: return first
	for i in range(first + 1, d.souls.size()):
		if int(d.souls[i]) > 0: return i
	return first

func _walk_update(m) -> void:
	if _blocked(m): return
	var ev = m.expedition
	if m.scene != "village" and ev.opened == "": return   # 낚시터 등에 가 있으면 잠깐 멈춤
	match walk:
		"alch": _walk_alch(m, ev)
		"explore": _walk_explore(m, ev)
		"soldier_up": _walk_up(m, ev)
		"merge": _walk_merge(m, ev)
		_: _walk_building(m)

func _walk_alch(m, ev) -> void:
	var R: Dictionary = ev.rects;var d = ev.data
	if sub >= 7: _walk_outro(m, "병사가 나왔어! 더 궁금한 건\n가이드 책을 읽어 봐.");return
	if ev.opened != "alchemy": sub = 0;_w_menu(m, "alchemy", "연성");return
	if sub == 0: sub = 1
	if ev.tab != 0: _do("어혼 연성 탭을 눌러 봐!", R.get("tab:0", Rect2()), false);return
	if not d.pending.is_empty() or ev.effect_kind != "": sub = 7;return
	match sub:
		1: _say("여긴 연성 화면이야!\n어혼 두 개를 합쳐서 병사를 만들어.", R.get("tab:0", Rect2()))
		2: _say("위쪽 두 칸이 재료 칸이야.\n여기에 어혼 두 개가 들어가.", R.get("pair:0", Rect2()).merge(R.get("pair:1", Rect2())))
		3: _do("아래 보유 어혼 중 하나를 눌러서\n첫 번째 재료로 골라 봐!", R.get("element:%d" % _souls_pick(d, false), Rect2()))
		4: _do("한 번 더! 두 번째 재료를 골라.\n같은 속성을 또 골라도 돼.", R.get("element:%d" % _souls_pick(d, true), Rect2()))
		5: _say("결과 미리보기야. 두 어혼의 조합으로\n병사가 정해져. ?는 처음 만드는 병사!", R.get("preview", Rect2()))
		_: _do("이제 연성하기를 눌러서\n병사를 만들어 봐!", R.get("craft", Rect2()), false)

func _walk_explore(m, ev) -> void:
	var R: Dictionary = ev.rects;var d = ev.data
	if sub >= 8: _walk_outro(m, "탐험을 보냈어! 더 궁금한 건\n가이드 책을 읽어 봐.");return
	if d.active() and sub < 8: sub = 8;return
	if ev.opened != "explore":
		sub = 0;_w_menu(m, "explore", "탐험");return
	if sub == 0: sub = 1
	if sub == 1: _say("여긴 탐험 화면이야! 병사 3마리를\n보내서 보상을 받아 와.", R.get("explore_tab:0", Rect2()));return
	if sub == 2:
		if ev.explore_tab == 1: sub = 3;return
		_do("먼저 병사 배치 탭을 눌러 봐!\n탐험은 병사 3마리가 있어야 가.", R.get("explore_tab:1", Rect2()), false);return
	if sub == 3:
		_say("위쪽 세 칸이 편성 자리야.\n왼쪽부터 뒤·중간·앞! 3칸을 모두 채워야 해.", R.get("slot:0", Rect2()).merge(R.get("slot:1", Rect2())).merge(R.get("slot:2", Rect2())));return
	if sub == 4:
		if d.team.size() >= 3 and ev.formation_uid < 0: sub = 5;return
		if ev.explore_tab != 1: sub = 2;return
		if ev.formation_uid >= 0:
			_do("배치 버튼을 눌러서 이 병사를\n출전시켜!", ev.formation_ui.modal_rects.get("confirm", Rect2()), false);return
		var pick := Rect2()
		for k in R:
			if str(k).begins_with("formation_unit:") and not (int(str(k).get_slice(":", 1)) in d.team): pick = R[k];break
		_do("아래 보유 병사를 눌러서 배치해 봐!\n(출전 %d/3)" % d.team.size(), pick, false);return
	if sub == 5:
		if ev.explore_tab != 0: _do("이제 탐사 노선 탭을 눌러 봐!", R.get("explore_tab:0", Rect2()), false);return
		sub = 6
	if sub == 6: _say("갈 노선을 골라. 처음엔 1번만\n열려 있어. 이 방으로 가자!", R.get("round:1", Rect2()));return
	_do("탐험 보내기를 눌러! 탐험 중에도\n낚시는 계속할 수 있어.", R.get("start", Rect2()), false)

func _walk_up(m, ev) -> void:
	var R: Dictionary = ev.rects;var d = ev.data
	if sub >= 9: _walk_outro(m, "강화 끝! 더 궁금한 건\n가이드 책을 읽어 봐.");return
	if ev.opened not in ["alchemy", "management", "training"]:
		sub = 0;_w_menu(m, "alchemy", "연성");return
	if sub == 0: sub = 1
	if ev.opened == "alchemy":
		if ev.tab != 2: _do("병사 탭을 눌러 봐!\n가진 병사를 볼 수 있어.", R.get("tab:2", Rect2()), false);return
		var pick := Rect2()
		for su in d.soldiers:
			if int(su.get("level", 0)) < 3 and R.has("select:%d" % int(su.uid)): pick = R["select:%d" % int(su.uid)];break
		_do("강화할 병사를 눌러 봐!", pick, false);return
	if ev.opened == "management":
		_do("강화 버튼을 눌러!\n비늘과 같은 속성 어혼이 들어가.", R.get("upgrade:%d" % int(ev.management.uid), Rect2()), false);return
	var u: Dictionary = d.unit(ev.training_uid)
	if lv0 < 0: lv0 = int(u.get("level", 0))
	if int(u.get("level", 0)) > lv0: sub = 9;lv0 = -1;return
	if sub == 1: _say("현재 능력치와 강화 뒤 능력치,\n드는 비용을 확인해!", R.get("train", Rect2()))
	elif sub == 2: _say("강화는 +3까지 할 수 있어.\n+3이 되면 병사 합성도 할 수 있지!", R.get("train", Rect2()))
	else: _do("강화하기를 눌러 봐!", R.get("train", Rect2()), false)

func _walk_merge(m, ev) -> void:
	var R: Dictionary = ev.rects;var d = ev.data
	if sub >= 9: _walk_outro(m, "합성 안내는 여기까지!\n더 궁금한 건 가이드 책을 읽어 봐.");return
	if ev.opened == "merge_confirm":
		sub = 8;line = "재료 병사는 사라져. 소모되는 재료를 보고\n합성하거나 취소해!";soft = true;return
	if sub == 8: sub = 9;return
	if ev.opened != "alchemy":
		sub = 0;_w_menu(m, "alchemy", "연성");return
	if sub == 0: sub = 1
	if ev.tab != 1: _do("병사 합성 탭을 눌러 봐!", R.get("tab:1", Rect2()), false);return
	match sub:
		1: _say("같은 별이고 둘 다 +3인 병사 둘을\n합치면 더 높은 별 병사가 돼!", R.get("tab:1", Rect2()))
		2:
			var picks: Array = _merge_pair(d)
			var left: Array = ev.selected
			var pick := Rect2()
			for uid in picks:
				if not (int(uid) in left) and R.has("select:%d" % int(uid)): pick = R["select:%d" % int(uid)];break
			if left.size() >= 2: sub = 3;return
			_do("합성할 병사를 눌러 골라 봐! (%d/2)" % left.size(), pick, false)
		_: _do("합성 결과와 소모 재료를 확인해 봐.\n안 하고 싶으면 취소해도 돼!", R.get("merge_review", Rect2()), false)

func _merge_pair(d) -> Array:
	for i in d.soldiers.size():
		var a = d.soldiers[i]
		if int(a.level) < 3 or int(a.star) >= 3 or bool(a.locked): continue
		for j in range(i + 1, d.soldiers.size()):
			var b = d.soldiers[j]
			if int(b.star) == int(a.star) and int(b.level) >= 3 and not bool(b.locked): return [int(a.uid), int(b.uid)]
	return []

## 건물 안내(수족관·대장간·펫 오두막): 건물을 누르게 하고 → 안에서 설명 쪽 → 닫으면 가이드 책
## 대장간: 강화 탭 → 단계·비용 → 실패 주의 → 강화하기(눌러 보기)
func _forge_steps(m, v) -> void:
	var pn: Rect2 = v.rects.get("panel", Rect2())
	if sub == 2:
		if v.forge_tab != "upgrade": _do("먼저 강화 탭을 눌러 봐!", _row(v, "forgetab:upgrade"), false);return
		sub = 3
	match sub:
		3: _say("낚싯대 강화 화면이야. 지금 단계와\n성공률, 드는 비용을 볼 수 있어.", pn)
		4: _say("비늘과 비늘조각이 들어가. 높은 단계는\n실패하면 내려갈 수 있어. 보호권도 있어!", pn)
		5:
			var b: Rect2 = _row(v, "forge")
			if b.size == Vector2.ZERO: _say("비늘이 모자라면 낚시로 모아 와!\n모이면 여기서 강화하기를 눌러.", pn)
			else: _do("강화하기를 눌러 봐!", b, true)
		_: soft = true   # 강화하는 동안은 막지 않는다. 상점을 닫으면 가이드 책 안내

func _row_pre(v, prefix: String) -> Rect2:
	for row in v.rects.get("rows", []):
		if str(row[1]).begins_with(prefix): return row[0]
	return Rect2()

func _aqua_count(m) -> int:
	var n := 0
	for f in m.aqua: if f != null: n += 1
	return n

## 수족관: 설명 → 물고기 관리 → 보관통 탭 → 넣기(실제로 넣어 봄)
func _aqua_steps(m, v) -> void:
	var pn: Rect2 = v.rects.get("panel", Rect2())
	if sub == 2:
		if lv0 < 0: lv0 = _aqua_count(m)
		_say("수족관에 물고기를 넣어 두면\n쉬는 동안에도 비늘을 벌어 줘!", pn);return
	if sub >= 3 and _aqua_count(m) > lv0: sub = 9
	if sub >= 9: soft = true;return
	if not v.aqua_manage: _do("물고기 관리를 눌러 봐!", _row(v, "amanage"), false);return
	if not v.aquarium.list_bag: _do("보관통 · 넣기 탭을 눌러 봐!", _row(v, "alist_bag"), false);return
	var b: Rect2 = _row_pre(v, "put:")
	if b.size == Vector2.ZERO: _say("보관통에 넣을 물고기가 없어.\n낚시로 물고기를 잡아 와서 넣어 보자!", pn);return
	_do("넣고 싶은 물고기의 넣기를 눌러 봐!", b, false)

## 펫 오두막: 뽑기 탭 → 설명 → 1회 뽑기(진주가 있으면 눌러 보기)
func _pet_steps(m, v) -> void:
	var h = v.hut
	if h == null or not is_instance_valid(h): return
	var R: Dictionary = h.rects
	if sub == 2:
		if h.tab != "gacha": _do("뽑기 탭을 눌러 봐!", R.get("tab:gacha", Rect2()), false);return
		sub = 3
	match sub:
		3: _say("진주 10개로 펫을 한 번 뽑을 수 있어!\n뽑은 펫은 키우면 도움이 돼.", R.get("pull", Rect2()).merge(R.get("pull10", Rect2())))
		4: _say("무엇이 나오는지 궁금하면\n확률 보기를 눌러 확인해 봐!", R.get("odds", Rect2()))
		5:
			if m.pearl >= 10: _do("1회 뽑기를 눌러 봐!", R.get("pull", Rect2()), true)
			else: _say("진주가 모자라면 낚시와 펫으로 모아 와!", R.get("pull", Rect2()))
		_: soft = true

func _walk_building(m) -> void:
	var v = m.V;var row: Array = BLD_WALKS.get(walk, [])
	if row.is_empty(): _walk_end(m);return
	var code: String = v.BUILD[row[0]][1]
	if sub >= 100: _walk_outro(m, "더 궁금한 건 가이드 책을 읽어 봐!");return
	if v.shop == "":
		if sub == 0: _center_on(m, row[0]);sub = 1
		if sub >= 2: sub = 100;return   # 설명을 보고 닫았다
		if m.menu_open or m.market_open or m.settings_open or m.mailbox.opened or m.guide.opened: return
		line = row[1];target = _building(m, row[0]);return
	if v.shop != code: return
	if sub < 2: sub = 2
	match walk:
		"forge": _forge_steps(m, v)
		"aqua": _aqua_steps(m, v)
		_: _pet_steps(m, v)

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
		"soldier_up": return ex.soldiers.size() >= 3 and "explore" in m.TUT.get("hints", []) and not ex.active() and ex.soldiers.any(func(u): return int(u.level) < 3)
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
	match what:
		"mail": return m.mailbox.button
		"guide": return m.guide.button
		"menu": return m.ui_rects.get("menu", Rect2())
	return Rect2()

## 마을에서 아무 창도 안 열렸을 때만, 조건이 된 안내를 하나씩 시작한다.
func _update_hint(m) -> void:
	if not m.TUT.has("tour"): return   # 튜토리얼을 시작하지 않은 실행(PC·검사)에는 안내도 없다
	var free_view: bool = m.scene == "village" and m.V.shop == "" and not m.menu_open and not m.market_open and not m.settings_open \
		and not m.mailbox.opened and not m.guide.opened and not m.personal_dex.opened and m.expedition.opened == "" and not _blocked(m)
	if hint != "":
		if not free_view or m.ui_clock - hint_t > 6.0: hint = ""
		return
	if not free_view or finish_t > 0 or (end_t > 0 and m.ui_clock - end_t < 3.5): return
	var seen: Array = m.TUT.get("hints", [])
	for k in HINT_ORDER:
		if k in seen or not _hint_ready(m, k): continue
		if k in WALKS: walk = k;sub = 0;face = "idle";m.audio_feedback.sound(m, "click", -10.0, 1.4);return
		hint = k;hint_t = m.ui_clock;face = "happy" if k == "mail" else "idle"
		_mark_seen(m, k)
		m.audio_feedback.sound(m, "click", -10.0, 1.4)
		return

func _mark_seen(m, k: String) -> void:
	var seen: Array = m.TUT.get("hints", [])
	if not k in seen: seen.append(k);m.TUT.hints = seen;m._save_tut()

func _paint_hint(m, h: float) -> void:
	var row: Array = HINTS.get(hint, [])
	if row.is_empty(): return
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
	if hint != "": hint = ""   # 한 줄 안내는 아무 곳이나 누르면 닫히고, 누른 입력은 그대로 게임으로 간다
	if walk != "": return false if _blocked(m) else _gate_press(m, p)
	if not active(m) or _blocked(m): return false
	if confirm:
		if rects.get("yes", Rect2()).has_point(p): _finish(m);m.lesson_open = false;m.audio_feedback.sound(m, "click", -8.0)
		elif rects.get("no", Rect2()).has_point(p): confirm = false
		return true
	if rects.get("skip", Rect2()).grow(4).has_point(p): confirm = true;m.audio_feedback.sound(m, "click", -8.0);return true
	if explain:
		if rects.get("next", Rect2()).grow(4).has_point(p): sub += 1;face = "idle";m.audio_feedback.sound(m, "click", -8.0, 1.3)
		else: bounce_t = m.ui_clock;m.audio_feedback.sound(m, "click", -12.0, 0.8)
		return true
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
	rects.skip = Rect2();rects.next = Rect2()
	if (active(m) or walk != "") and not _blocked(m) and not m.lesson_open: _paint(m, h)
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
		if not explain: _finger(m, corner + (dir * d).round(), fx, fy)
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
	_tip_box(m, band.grow_individual(4, 2 if not top else 4, 4, 4 if not top else 0) if not near else band.grow_individual(4, 0, 4, 0))
	var tex: Texture2D = PORTRAITS.get(face, PORTRAITS.idle)
	var hop: float = -2.0 if m.ui_clock - pop_t < 0.3 else 0.0
	m._ui_texture_rect(tex, Rect2(6, cy + 5 + hop, 48, 48))   # 고양이 몸통이 띠 세로 가운데
	if active(m) or walk != "":
		var cur: int = step(m) if active(m) else -1
		for i in (STEPS if active(m) else 0):
			m._ui_rect(Rect2(60 + i * 9, cy + 11, 5, 5), Color("e0a93a") if i < cur else (Color("17525a") if i == cur else Color(0.09, 0.32, 0.35, 0.3)))
		rects.skip = Rect2(196, bottom_edge - 28, 66, 20)   # 늘 띠 오른쪽 아래 같은 자리(누르는 칸은 넉넉히, 그림은 글자만)
		if explain:
			rects.next = Rect2(196, bottom_edge - 25, 66, 18);rects.skip = Rect2(60, bottom_edge - 25, 66, 18)
			var nb: Rect2 = rects.next.grow_individual(-2, -1, -2, -1)
			m._ui_rect(Rect2(nb.position.x + 2, nb.position.y, nb.size.x - 4, nb.size.y), Color("17525a"));m._ui_rect(Rect2(nb.position.x, nb.position.y + 2, nb.size.x, nb.size.y - 4), Color("17525a"))
			m._ui_rect(Rect2(nb.position.x + 2, nb.position.y + 2, nb.size.x - 4, nb.size.y - 4), Color("ffd166") if sin(m.ui_clock * 6.0) > -0.3 else Color("ffe9a0"))
			m._text("다음 >", rects.next.get_center() + Vector2(0, 4), 10, Color("17323a"), true, 56)
			m._text("건너뛰기", Vector2(rects.skip.get_center().x, bottom_edge - 12), 10, Color("3f7f86"), true, 66)
		else: m._text("건너뛰기 >", Vector2(rects.skip.get_center().x, bottom_edge - 13), 10, Color("3f7f86"), true, 66)
	var txt: String = m._ui_wrap(line, 10, 200, 2)
	var up: float = 6.0 if explain else 0.0   # 아래 "다음"·"건너뛰기" 줄과 겹치지 않게 글자를 조금 올린다
	m._text(txt, Vector2(160, cy + (26 if "\n" in txt else 35) - up), 10, Color("12373c"), true, 200)   # 글자도 세로 가운데

## 고양이 말풍선: 상점·메뉴의 갈색·크림색과 겹치지 않게 민트색 도트 틀(굵은 진청록 테두리 + 금색 윗줄)
func _tip_box(m, r: Rect2) -> void:
	var bd := Color("17525a");var fill := Color("e3f6ee")
	m._ui_rect(Rect2(r.position.x + 3, r.position.y, r.size.x - 6, r.size.y), bd);m._ui_rect(Rect2(r.position.x, r.position.y + 3, r.size.x, r.size.y - 6), bd)
	m._ui_rect(Rect2(r.position.x + 1, r.position.y + 1, r.size.x - 2, r.size.y - 2), bd)
	m._ui_rect(Rect2(r.position.x + 5, r.position.y + 3, r.size.x - 10, r.size.y - 6), fill);m._ui_rect(Rect2(r.position.x + 3, r.position.y + 5, r.size.x - 6, r.size.y - 10), fill)
	m._ui_rect(Rect2(r.position.x + 6, r.position.y + 3, r.size.x - 12, 2), Color("ffd166"))
	m._ui_rect(Rect2(r.position.x + 6, r.end.y - 5, r.size.x - 12, 2), Color("b5dccd"))

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
