extends SceneTree
var failures: Array = []
var output: String
func _initialize() -> void: call_deferred("run")
func capture(m, name: String) -> void:
	m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.save_png(output.path_join(name + ".png")) != OK: failures.append(name)
func run() -> void:
	output = OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	seed(131)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var ui := CanvasLayer.new();ui.layer=10;root.add_child(ui)
	var text := Node2D.new();text.set_script(load("res://text_layer.gd"));ui.add_child(text)
	var m=load("res://main.gd").new();m.text_layer=text;m.SET.music=0;m.SET.sfx=0;root.add_child(m);await process_frame;m.set_process(false)
	m.title_open=false;m.title_screen.leaving=false;m.title_screen.root.hide();m.lesson_open=false;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.tip_t=0
	m._switch_scene("village");m.trans={};m.V.ferry_clock=8;m.V.visitors.motion_rng.seed=131
	for h in [480,540,660]:
		root.content_scale_size=Vector2i(270,h);root.size=Vector2i(810,h*3);await process_frame
		for x in [0,270,810,1360]:
			m.V.camera_x=x
			await capture(m,"village_%d_%d"%[h,x])
	root.content_scale_size=Vector2i(270,660);root.size=Vector2i(810,1980);await process_frame
	for x in [0,360,900]:
		m.V.camera_x=x
		for frame in 48:
			m.V.process(m,1.0/12.0);m.V.ferry_clock=8
			await capture(m,"motion_%d_%02d"%[x,frame])
	m.V.visitors.hide_all(m.V.res+m.V.locals)
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("VILLAGE_LIFE131_PREVIEW failures=",failures," native_screens=156")
	quit(0 if failures.is_empty() else 1)
