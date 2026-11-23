extends SceneTree
func _init() -> void:
	var main = load("res://test_main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.reels.runtime = 0.6; main.reels.reel_delay = 0.2
	main.reels.spin([[5,4,1],[3,3,3],[6,2,0]])
	await create_timer(0.25).timeout
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/shot_mid.png")
	await main.reels.spin_finished
	await create_timer(0.1).timeout
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/shot_end.png")
	quit()
