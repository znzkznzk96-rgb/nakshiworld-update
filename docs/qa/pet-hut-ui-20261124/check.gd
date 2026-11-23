extends SceneTree
func _init() -> void:
	var main = load("res://test_main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var ui: PetHutUI = main.ui
	var ok := 0; var n := 0
	var closed := [false]
	ui.closed.connect(func(): closed[0] = true)
	for k in ["close", "tab:pets", "tab:gacha", "tab:plans", "body"]:
		n += 1; ok += 1 if ui.rects.has(k) else 0
	for t in ["gacha", "plans", "pets"]:
		ui.press(ui.rects["tab:" + t].get_center())
		n += 1; ok += 1 if ui.tab == t else 0
	ui.press(Vector2(2, 2))
	n += 1; ok += 1 if closed[0] else 0
	closed[0] = false
	ui.press(ui.rects["close"].get_center())
	n += 1; ok += 1 if closed[0] else 0
	closed[0] = false
	ui.press(ui.rects["body"].get_center())
	n += 1; ok += 1 if not closed[0] else 0
	# ── 내 펫 탭 ──
	ui.press(ui.rects["tab:pets"].get_center())
	await process_frame
	var got := [0]
	ui.pearls_collected.connect(func(c): got[0] += c)
	for i in 400: ui.step(0.05)                      # 20초 시뮬레이션
	n += 1; ok += 1 if ui._fx.size() >= 0 and ui._pets.size() == 3 else 0
	var xs_ok := true
	for p in ui._pets: xs_ok = xs_ok and p.x >= ui.WALK_X0 and p.x <= ui.WALK_X1
	n += 1; ok += 1 if xs_ok else 0                  # 펫이 장면 밖으로 안 나감
	ui.stored = 0.0; ui.time_scale = 3600.0
	ui.step(1.0)                                     # 1초 = 1시간
	n += 1; ok += 1 if absf(ui.stored - ui.rate_per_hour()) < 0.01 else 0   # 시간당 생산량
	ui.step(0.0); await process_frame
	ui.press(ui.rects["collect"].get_center())
	n += 1; ok += 1 if got[0] == floori(ui.rate_per_hour()) and ui.pearl_total == got[0] else 0
	ui.time_scale = 3600.0
	for i in 40: ui.step(1.0)                        # 40시간치 → 상한 12시간
	n += 1; ok += 1 if absf(ui.stored - ui.rate_per_hour() * 12.0) < 0.01 else 0
	ui.step(0.0); await process_frame
	ui.press(ui.rects["slot:0"].get_center())
	n += 1; ok += 1 if ui.picker == 0 else 0
	ui.step(0.0); await process_frame
	ui.press(ui.rects["pick:d_chick"].get_center())
	n += 1; ok += 1 if ui.equipped[0] == "d_chick" and ui.picker == -1 else 0
	ui.step(0.0); await process_frame
	ui.press(ui.rects["slot:1"].get_center())
	ui.step(0.0); await process_frame
	var prev0: String = ui.equipped[0]; var prev1: String = ui.equipped[1]
	ui.press(ui.rects["pick:" + prev0].get_center())   # 이미 다른 칸에 있는 펫 → 서로 교환
	n += 1; ok += 1 if ui.equipped[1] == prev0 and ui.equipped[0] == prev1 else 0
	print("통과 %d/%d" % [ok, n])
	quit(0 if ok == n else 1)
