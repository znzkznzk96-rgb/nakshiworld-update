extends SceneTree
func _initialize(): call_deferred("run")
func run():
	var out: String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_size=Vector2i(270,540);root.size=Vector2i(810,1620)
	var app=load("res://tests/valley_native_root.gd").new();root.add_child(app);app._start()
	var m=app.box.get_child(0).get_child(0)
	m.development_preview=true;m.SET.sfx=0;m.SET.music=0;m.set_process(false)
	m.title_open=false;m.lesson_open=false;m.trans={};m.TUT.done=true;m.tip_t=0
	await process_frame;app._fit();await process_frame
	m._switch_scene("spots");m.spots.index=2;m.spots.scroll=2;m.spots.shift=0;m.queue_redraw()
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("before_selection_540.png"))
	m.audio_feedback.dispose();app.queue_free();await process_frame;await process_frame
	print("BASELINE_SELECTION_CAPTURED");quit(0)
