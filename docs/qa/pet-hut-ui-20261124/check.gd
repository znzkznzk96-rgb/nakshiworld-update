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
	print("통과 %d/%d" % [ok, n])
	quit(0 if ok == n else 1)
