extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func snapshot(m, path: String, clock: float) -> void:
	m.update_screen.motion.time_override = clock
	m.update_screen.motion.advance(0.0)
	m.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out.path_join("frames"))
	root.content_scale_size = Vector2i(270, 660)
	root.size = Vector2i(540, 1320)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var m = load("res://root.gd").new()
	root.add_child(m)
	await process_frame
	m.set_process(false)
	m.status = "업데이트 다운로드 중"
	m.update_phase = "download"
	m.update_version = "0.72"
	m.expected_size = 33108128
	m.progress = 0.66
	m.downloaded_bytes = int(m.expected_size * m.progress)
	assert(m.http == null, "preview must never start network requests")
	assert(m.update_screen.motion.effect_nodes.size() == 5)
	for i in 5:
		m.update_screen.motion.set_effect_enabled(i, false)
	await snapshot(m, out.path_join("base.png"), 0.0)
	for i in 5:
		m.update_screen.motion.set_effect_enabled(i, true)
		await snapshot(m, out.path_join("effect_%d.png" % i), 1.9)
		m.update_screen.motion.set_effect_enabled(i, false)
	for i in 5:
		m.update_screen.motion.set_effect_enabled(i, true)
	await snapshot(m, out.path_join("all.png"), 1.9)
	for frame in 192:
		m.progress = lerpf(0.12, 0.86, minf(float(frame) / 168.0, 1.0))
		m.downloaded_bytes = int(m.expected_size * m.progress)
		await snapshot(m, out.path_join("frames/%04d.png" % frame), frame / 24.0)
	assert(m.update_screen.spark_until < 191.0/24.0, "sparks must stop when byte progress stalls")
	root.content_scale_size = Vector2i(270, 480)
	root.size = Vector2i(540, 960)
	await process_frame
	await snapshot(m, out.path_join("small.png"), 1.9)
	print("UPDATE_MOTION_PREVIEW failures=[] frames=192 layers=5")
	quit()
