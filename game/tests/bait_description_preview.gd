extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size=Vector2i(270,540);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.size=Vector2i(540,1080)
	var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
	var text:=Node2D.new();text.set_script(load("res://text_layer.gd"));ui.add_child(text)
	var m=load("res://main.gd").new();m.text_layer=text;m.SET.sfx=0;m.SET.music=0;root.add_child(m)
	await process_frame
	m.development_preview=true;m.set_process(false);m.title_open=false;m.lesson_open=false;m.tip_t=0;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true
	m.scene="village";m.S={"phase":"idle"};m.environment.set_hour(16.0)
	m.V.open_shop(m,"up");m.V.tab="bait"
	m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("bait.png"))
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("DEX_NATIVE failures=[]");quit()
