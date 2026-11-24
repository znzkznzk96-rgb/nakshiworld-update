extends SceneTree
func _init() -> void:
	var main = load("res://test_main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var m: SlotMachine = main.machine
	var cases := [["d_frog", 0], ["a_otter", 3], ["s_wisp", 4], ["ss_storm", 5], ["sss_demon", 6], ["sss_apostle", 6]]
	for c in cases:
		m.reveal_pet = c[0]
		var g: int = c[1]
		var T0 := m._rv_start(g)
		m._reveal(g)
		var times := [T0 + 1.3]
		for i in 1:
			while m._rv_t < times[i]: await process_frame
			root.get_viewport().get_texture().get_image().save_png("/tmp/v_%s_%d.png" % [c[0], i])
		m.skip()
		while m._rv_t >= 0.0: await process_frame
	quit()
