extends SceneTree

var failures: Array[String] = []
var captures: int = 0

func _initialize() -> void:
	call_deferred("run")

func capture(m, out: String, name: String) -> void:
	m.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if image.is_empty() or image.save_png(out.path_join(name + ".png")) != OK:
		failures.append("failed capture " + name)
	captures += 1

func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var ui := CanvasLayer.new()
	ui.layer = 10
	root.add_child(ui)
	var text := Node2D.new()
	text.set_script(load("res://text_layer.gd"))
	ui.add_child(text)
	var m = load("res://main.gd").new()
	m.text_layer = text
	m.development_preview = true
	m.SET.sfx = 0
	m.SET.music = 0
	root.add_child(m)
	await process_frame
	m.set_process(false)
	m.title_open = false
	m.title_screen.root.hide()
	m.lesson_open = false
	m.tip_t = 0
	m.guide.opened = false
	m.mailbox.opened = false
	m.trans = {}
	m.TUT.done = true
	m.scene = "village"
	m.S = {"phase": "idle"}
	m.V.enter(m)
	m.V.open_shop(m, "forge")
	m.V.forge_tab = "upgrade"
	m.forge_seen = true
	m.rod_lv = 0
	m.forge_lv = 0
	var e = m.V.enhancement
	for win in [true, false]:
		for height in [480, 540, 660]:
			root.content_scale_size = Vector2i(270, height)
			root.size = Vector2i(540, height * 2)
			await process_frame
			m._layout()
			e.record = {"rod": 0, "old": 0, "next": 1 if win else 0, "success": win, "protected": false}
			for tick in range(36):
				# Full 3.5s timeline, with 0.1s stepped captures at the standard phone height.
				if height != 540 and tick not in [0, 6, 14, 22, 25, 27, 29, 35]:
					continue
				var t: float = float(tick) * 0.1
				e.phase = "working" if t < e.WORK_TIME else "result"
				e.elapsed = t if t < e.WORK_TIME else t - e.WORK_TIME
				var name: String = ("success" if win else "failure") + "_" + str(height) + "_%02d" % tick
				await capture(m, out, name)
				var have_dismiss: bool = false
				for row in m.V.rects.rows:
					if str(row[1]) == "forge_done":
						have_dismiss = true
					if not m.V.rects.panel.encloses(row[0]):
						failures.append("outside button " + name + " " + str(row[1]))
				if have_dismiss != (e.phase == "result" and e.elapsed >= e.REVEAL_TIME):
					failures.append("confirmation visibility " + name)
	e.phase = ""
	m.audio_feedback.dispose()
	m.queue_free()
	await process_frame
	print("FORGE_THREE_STRIKE_PREVIEW captures=", captures)
	print("FORGE_THREE_STRIKE_PREVIEW failures=", failures)
	quit(0 if failures.is_empty() else 1)
