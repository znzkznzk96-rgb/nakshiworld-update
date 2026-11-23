extends SceneTree
func _init() -> void:
	var main = load("res://test_main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for t in ["pets", "gacha", "plans"]:
		main.ui.press(main.ui.rects["tab:" + t].get_center())
		await process_frame
		await process_frame
		root.get_viewport().get_texture().get_image().save_png("/tmp/hutui_%s.png" % t)
	quit()
