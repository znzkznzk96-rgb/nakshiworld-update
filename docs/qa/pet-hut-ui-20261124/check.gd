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
	# ── 뽑기 탭 ──
	var psum := 0.0
	for g in PetHutUI.GRADE_P: psum += g
	n += 1; ok += 1 if absf(psum - 100.0) < 0.001 and PetHutUI.PETS.size() == 22 else 0
	var pp := 0.0
	for k in PetHutUI.PETS: pp += PetHutUI.pet_percent(k)
	n += 1; ok += 1 if absf(pp - 100.0) < 0.001 else 0           # 펫별 확률 합 100
	ui._grng.seed = 11
	var gc := [0, 0, 0, 0, 0, 0, 0]
	for i in 100000: gc[PetHutUI.grade_of(ui.roll_pet())] += 1
	var dist_ok := true
	for g in 7: dist_ok = dist_ok and absf(gc[g] / 1000.0 - PetHutUI.GRADE_P[g]) < maxf(0.25, PetHutUI.GRADE_P[g] * 0.15)
	n += 1; ok += 1 if dist_ok else 0                            # 시뮬 확률이 표와 일치
	ui.press(ui.rects["tab:gacha"].get_center()); ui.step(0.0); await process_frame
	ui.pearl_total = 9
	n += 1; ok += 1 if not ui.can_pull() and not ui.pull() and ui.pearl_total == 9 else 0   # 진주 부족이면 안 됨
	ui.pearl_total = 25
	var before_cnt := 0
	for k in ui.counts: before_cnt += ui.counts[k]
	var done := [false]
	n += 1; ok += 1 if ui.pull() and ui.pearl_total == 15 and ui._slot != null else 0       # 10개 차감, 슬롯 시작
	var after_cnt := 0
	for k in ui.counts: after_cnt += ui.counts[k]
	n += 1; ok += 1 if after_cnt == before_cnt + 1 and ui.counts[ui.last_pet] >= 1 and ui.owned.has(ui.last_pet) else 0
	n += 1; ok += 1 if not ui.pull() and ui.pearl_total == 15 else 0                          # 연출 중 중복 뽑기 막힘
	ui.press(Vector2(135, 200)); n += 1; ok += 1 if ui._slot != null else 0                  # 연출 중 창은 반응 없음
	var waited := 0.0
	while ui._slot != null and waited < 40.0:
		await process_frame
		if ui._machine != null and ui._machine.busy: ui._machine.skip()
		waited += 0.016
	n += 1; ok += 1 if ui._slot == null and ui.can_pull() else 0                              # 연출이 끝나고 돌아옴
	ui.step(0.0); await process_frame
	ui.press(ui.rects["odds"].get_center()); n += 1; ok += 1 if ui.show_odds else 0
	ui.step(0.0); await process_frame
	ui.press(ui.rects["odds_close"].get_center()); n += 1; ok += 1 if not ui.show_odds else 0
	# ── 도면 탭 ──
	ui.press(ui.rects["tab:plans"].get_center()); ui.step(0.0); await process_frame
	ui.counts = {"d_chick": 1, "ss_golem": 3, "a_owl": 2}; ui._sync_owned(); ui.frags = 0; ui.pearl_total = 0
	n += 1; ok += 1 if not ui.dismantle("d_chick") and ui.frags == 0 else 0                 # 처음 1마리는 분해 불가
	n += 1; ok += 1 if ui.dismantle("ss_golem") and ui.frags == 200 and ui.counts["ss_golem"] == 2 else 0
	n += 1; ok += 1 if ui.dismantle("a_owl") and ui.frags == 220 and ui.counts["a_owl"] == 1 and not ui.dismantle("a_owl") else 0
	ui.frags = 149; ui.pearl_total = 50
	n += 1; ok += 1 if not ui.can_craft("a_fennec") else 0                                  # 조각 부족
	ui.frags = 150; ui.pearl_total = 49
	n += 1; ok += 1 if not ui.can_craft("a_fennec") else 0                                  # 진주 부족
	ui.pearl_total = 50
	n += 1; ok += 1 if not ui.can_craft("b_hamster") else 0                                 # B 이하는 도면 없음
	n += 1; ok += 1 if ui.craft("a_fennec") and ui.frags == 0 and ui.pearl_total == 0 and ui.counts["a_fennec"] == 1 and ui.owned.has("a_fennec") else 0
	var cost_ok := true
	for g in [3, 4, 5, 6]: cost_ok = cost_ok and PetHutUI.BP_COST[g].size() == 2
	n += 1; ok += 1 if cost_ok and PetHutUI.BP_COST[6] == [2100, 300] else 0
	ui.step(0.0); await process_frame
	n += 1; ok += 1 if PetHutUI.bp_pets().size() == 13 and ui.rects.has("bp:sss_lunar") and not ui.rects.has("open_dis") else 0     # 상점에 13종
	ui.frags = 2100; ui.pearl_total = 300
	ui.press(ui.rects["bp:sss_seraph"].get_center()); ui.step(0.0); await process_frame
	ui.press(ui.rects["buy"].get_center())
	n += 1; ok += 1 if ui.plan_sel == "sss_seraph" and ui.frags == 0 and ui.pearl_total == 0 and ui.counts["sss_seraph"] == 1 else 0   # 화면에서 눌러 구매
	# ── 보관함 탭 ──
	ui.counts = {"d_chick": 1, "ss_golem": 3, "a_owl": 2, "b_hamster": 1}; ui._sync_owned(); ui.equipped = ["b_hamster", "ss_golem"]; ui._reset_pets(); ui.frags = 0
	ui.press(ui.rects["tab:box"].get_center()); ui.step(0.0); await process_frame
	n += 1; ok += 1 if ui.tab == "box" and ui.rects.has("bx:sss_lunar") and ui.rects.has("bx:d_chick") else 0     # 22칸(없는 펫 포함)
	ui.press(ui.rects["bx:a_owl"].get_center()); ui.step(0.0); await process_frame
	ui.press(ui.rects["bx_equip"].get_center()); ui.step(0.0); await process_frame
	n += 1; ok += 1 if ui.equipped == ["b_hamster", "ss_golem", "a_owl"] and ui._pets.size() == 3 else 0           # 장착
	ui.press(ui.rects["bx:d_chick"].get_center()); ui.step(0.0); await process_frame
	ui.press(ui.rects["bx_equip"].get_center())
	n += 1; ok += 1 if not ui.equipped.has("d_chick") and ui.equipped.size() == 3 else 0                          # 가득 차면 장착 안 됨
	ui.step(0.0); await process_frame
	ui.press(ui.rects["bx:a_owl"].get_center()); ui.step(0.0); await process_frame
	ui.press(ui.rects["bx_equip"].get_center())
	n += 1; ok += 1 if ui.equipped == ["b_hamster", "ss_golem"] else 0                                              # 빼기
	ui.step(0.0); await process_frame
	ui.press(ui.rects["bx:ss_golem"].get_center()); ui.step(0.0); await process_frame
	ui.press(ui.rects["bx_dis"].get_center())
	n += 1; ok += 1 if ui.frags == 200 and ui.counts["ss_golem"] == 2 and ui.equipped.has("ss_golem") else 0       # 분해(장착 유지)
	ui.step(0.0); await process_frame
	ui.press(ui.rects["bx:d_chick"].get_center()); ui.step(0.0); await process_frame
	ui.press(ui.rects["bx_dis"].get_center())
	n += 1; ok += 1 if ui.frags == 200 and ui.counts["d_chick"] == 1 else 0                                         # 1마리는 분해 불가
	ui.press(ui.rects["tab:pets"].get_center()); ui.step(0.0); await process_frame
	ui.press(ui.rects["slot:2"].get_center()); ui.step(0.0); await process_frame
	ui.press(ui.rects["pick:d_chick"].get_center())
	n += 1; ok += 1 if ui.equipped == ["b_hamster", "ss_golem", "d_chick"] else 0                                    # 빈 슬롯에 장착
	print("통과 %d/%d" % [ok, n])
	quit(0 if ok == n else 1)
