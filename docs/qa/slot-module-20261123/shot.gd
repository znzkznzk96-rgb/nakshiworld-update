extends SceneTree
func _init() -> void:
	var main = load("res://test_main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var rng := RandomNumberGenerator.new(); rng.seed = 11
	var cases := [["d", 0, false, 2.2], ["a", 3, false, 2.3], ["ss", 5, false, 2.9], ["jp", 6, true, 3.9]]
	for c in cases:
		main.machine.play(SlotMachine.make_grid(c[1], rng, c[2]))
		await create_timer(c[3]).timeout
		root.get_viewport().get_texture().get_image().save_png("/tmp/fx_%s.png" % c[0])
		await main.machine.finished
		await create_timer(0.3).timeout
	quit()
