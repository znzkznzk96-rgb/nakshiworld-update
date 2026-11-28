extends SceneTree
# 기본 튜토리얼: 건너뛰기 확인창, 이어하기, 기존 플레이어 처리, 완료 우편 선물
var failures: Array = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, what: String) -> void:
	if not ok: failures.append(what)
func boot():
	var holder := Node2D.new();root.add_child(holder)
	var txt := Node2D.new();txt.set_script(load("res://text_layer.gd"));holder.add_child(txt)
	var m = load("res://main.gd").new();m.text_layer = txt;m.SET.sfx = 0;m.SET.music = 0;root.add_child(m)
	for i in 10: await process_frame
	m.title_open = false;m.scene = "village";m.V.enter(m)
	for i in 4: await process_frame
	return m
func run() -> void:
	var m = await boot()
	# 새 플레이어로 시작
	m.TUT.erase("tour");m.TUT.erase("tour_mail");m.intro_new_player = true;m.tour.force = true;m.tour.setup(m)
	check(m.tour.step(m) == 0 and not m.mailbox.tour_mail, "new player starts at 0")
	m.tour._go(m, 2);for i in 3: await process_frame
	# 이어하기: 다시 켜도 같은 단계
	m.get_parent().remove_child(m);m.free();await process_frame
	m = await boot();m.tour.force = true;m.tour.setup(m)
	check(m.tour.step(m) == 2, "resume keeps step 2")
	# 건너뛰기 → 아니요 → 그대로, 건너뛰기 → 예 → 완료 + 우편
	for i in 3: await process_frame
	var skip: Rect2 = m.tour.rects.get("skip", Rect2())
	check(skip.size != Vector2.ZERO, "skip button drawn")
	check(m.tour.intercept(m, skip.get_center()) and m.tour.confirm, "skip opens confirm")
	for i in 2: await process_frame
	m.tour.intercept(m, m.tour.rects.no.get_center())
	check(not m.tour.confirm and m.tour.active(m), "no keeps tutorial")
	m.tour.intercept(m, skip.get_center());for i in 2: await process_frame
	m.tour.intercept(m, m.tour.rects.yes.get_center())
	check(not m.tour.active(m) and m.mailbox.tour_mail, "yes finishes with mail")
	check(m.mailbox.visible_letters().any(func(l): return l.id == "tour"), "tour letter listed")
	m.testing_grants.erase("tutorial-reward-163")   # 이전 실행 저장분 제거
	var g0: int = m.gold;var p0: int = m.pearl
	check(load("res://addons/reservoir/mail_gifts.gd").claim(m, "tour"), "gift claim")
	check(m.gold == g0 + 100 and m.pearl == p0 + 10, "gift amounts")
	# 기존 플레이어: 튜토리얼 없이 완료 + 우편
	m.TUT.erase("tour");m.TUT.erase("tour_mail");m.intro_new_player = false;m.tour.force = true;m.tour.setup(m)
	check(not m.tour.active(m) and m.mailbox.tour_mail, "existing player gets mail only")
	# 중간 안내: 조건이 되면 한 번만, 누르면 닫히고 입력은 막지 않는다
	m.TUT.hints = [];m.testing_grants.erase("tutorial-reward-163");m.tour.finish_t = -1.0;m.tour.end_t = -1.0;m.tour.hint = ""
	for i in 3: await process_frame
	check(m.tour.hint == "mail", "mail hint shows")
	check(not m.tour.intercept(m, Vector2(135, 300)) and m.tour.hint == "", "hint closes without blocking")
	for i in 3: await process_frame
	check(m.tour.hint != "mail", "mail hint only once")
	# 여러 쪽 안내: 누르면 다음 쪽(입력 막음), 마지막 쪽에서 닫히고 그때 본 것으로 기록
	m.tour.hint = "explore";m.tour.hint_page = 0
	check(m.tour.intercept(m, Vector2(135, 300)) and m.tour.hint == "explore" and m.tour.hint_page == 1, "multi-page hint advances and blocks tap")
	while m.tour.hint_page < 3: m.tour.intercept(m, Vector2(135, 300))
	check(not m.tour.intercept(m, Vector2(135, 300)) and m.tour.hint == "", "last page closes without blocking")
	var last_pages: Array = []
	for hh in m.tour.HINTS: if hh[1].size() > 1: last_pages.append(hh[1][hh[1].size() - 1][1])
	check(last_pages.all(func(x): return x == "guide"), "every multi-page hint ends at the guide")
	print("TUTORIAL_TOUR_VERIFY failures=", failures)
	quit(1 if failures else 0)
