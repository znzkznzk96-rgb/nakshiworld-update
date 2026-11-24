extends SceneTree
func _init() -> void:
	var main = load("res://test_main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var m: SlotMachine = main.machine
	var rng := RandomNumberGenerator.new(); rng.seed = 9
	m.play(SlotMachine.make_grid(6, rng, true))
	while m._bn_t < 0.9: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/r_jp.png")
	for c in [["rd", 0], ["ra", 3], ["rsss", 6]]:
		while m.busy and m._rv_t < 0.0: await process_frame
		if not m.busy:
			m.play(SlotMachine.make_grid(c[1], rng))
		while m._rv_t < 1.3: await process_frame
		root.get_viewport().get_texture().get_image().save_png("/tmp/%s.png" % c[0])
		m.skip()
		await m.finished
		if c[0] == "rd":
			m.play(SlotMachine.make_grid(3, rng))
		elif c[0] == "ra":
			m.play(SlotMachine.make_grid(6, rng))
	quit()
