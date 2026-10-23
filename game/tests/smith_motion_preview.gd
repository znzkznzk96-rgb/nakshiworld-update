extends SceneTree
var failures: Array = []
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size = Vector2i(270, 540)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.size = Vector2i(540, 1080)
	var ui := CanvasLayer.new(); ui.layer = 10; root.add_child(ui)
	var text := Node2D.new(); text.set_script(load("res://text_layer.gd")); ui.add_child(text)
	var m = load("res://main.gd").new(); m.text_layer = text
	m.SET.sfx = 0; m.SET.music = 0; root.add_child(m)
	await process_frame
	m.development_preview = true; m.set_process(false); m.title_open = false
	m.lesson_open = false; m.tip_t = 0; m.guide.opened = false; m.mailbox.opened = false
	m.trans = {}; m.TUT.done = true; m.scene = "village"; m.V.shop = "forge"
	m.V.forge_tab = "upgrade"; m.forge_seen = true
	var e = m.V.enhancement
	e.phase = "working"; e.record = {"rod":0,"old":0,"next":1,"success":true,"protected":false}
	for i in 8:
		e.elapsed = i * 0.1 + 0.01
		m.queue_redraw(); await process_frame; await process_frame; await RenderingServer.frame_post_draw
		var found := false
		for cmd in m.ui_commands:
			if cmd[0] == "texture" and cmd[1] == e.animation.smith[i]: found = true
			if cmd[0] == "region" and cmd[1] in e.animation.smith: failures.append("partial smith frame " + str(i))
		if not found: failures.append("missing whole frame " + str(i))
		root.get_texture().get_image().save_png(out.path_join("smith_%d.png" % i))
	e.phase = "result"; e.elapsed = 0.6
	m.queue_redraw(); await process_frame; await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("result.png"))
	m.audio_feedback.dispose(); m.queue_free(); await process_frame
	print("SMITH_MOTION failures=", failures)
	quit(0 if failures.is_empty() else 1)
