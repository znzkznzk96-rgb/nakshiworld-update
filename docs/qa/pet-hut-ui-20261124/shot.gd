extends SceneTree
func _init() -> void:
	var main = load("res://test_main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.ui.time_scale = 3600.0 * 3.0
	for i in 60: main.ui.step(0.1)
	root.get_viewport().get_texture().get_image().save_png("/tmp/hutui_pets_a.png")
	for i in 25: main.ui.step(0.1)
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/hutui_pets_b.png")
	main.ui.press(main.ui.rects["slot:1"].get_center())
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/hutui_picker.png")
	main.ui.picker = -1
	for t in ["pets", "gacha", "plans"]:
		main.ui.press(main.ui.rects["tab:" + t].get_center())
		await process_frame
		await process_frame
		root.get_viewport().get_texture().get_image().save_png("/tmp/hutui_%s.png" % t)
	quit()
