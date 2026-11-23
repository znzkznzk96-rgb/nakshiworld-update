extends SceneTree
func _init() -> void:
	var main = load("res://test_main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var rng := RandomNumberGenerator.new(); rng.seed = 5
	var cases := [["b", 2, 0.3], ["a", 3, 0.25], ["s", 4, 0.4], ["ss", 5, 0.75], ["sss", 6, 0.95]]
	for c in cases:
		main.machine.play(SlotMachine.make_grid(c[1], rng))
		await main.machine.reels.spin_finished
		await create_timer(c[2]).timeout
		root.get_viewport().get_texture().get_image().save_png("/tmp/fx2_%s.png" % c[0])
		await main.machine.finished
		await create_timer(0.3).timeout
	quit()
