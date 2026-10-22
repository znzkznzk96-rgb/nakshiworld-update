extends SceneTree
func _initialize() -> void:call_deferred("run")
func capture(m,out: String,name: String) -> void:
	m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name+".png"))
func run() -> void:
	var out: String=OS.get_cmdline_user_args()[0]
	root.content_scale_size=Vector2i(270,540);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.size=Vector2i(540,1080)
	var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
	var txt:=Node2D.new();txt.set_script(load("res://text_layer.gd"));ui.add_child(txt)
	var m=load("res://main.gd").new();m.text_layer=txt;m.SET.sfx=0;m.SET.music=0;m.title_open=false;root.add_child(m);await process_frame
	m.development_preview=true;m.set_process(false);m.title_open=false;m.TUT.done=true;m.lesson_open=false;m.tip_t=0;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.scene="fish";m.bait=100;m.gold=12345;m.pearl=2;m.region_shop.unlocked=[0,1]
	for area in 2:
		m.active_region=area;m._layout();m.environment.show_scene(true)
		m.equipment.active_parts=["float","hook","line","reel"] if area==0 else ["r1_float","r1_hook","r1_line","r1_reel"]
		for progress in [0,73,100]:
			m.progression.owner_gauge[area]=progress;m.S={"phase":"idle"}
			await capture(m,out,"owner_%d_%d"%[area,progress])
		m.start_wait();m.S.grade=0;m.start_hook();m.S.pos=m.S.zc+0.1;m.hook_tap();m.S.t=1.0
		await capture(m,out,"owner_%d_warning"%area)
		m.start_fight();m.S.dist=30.0
		await capture(m,out,"owner_%d_fight"%area)
	root.content_scale_size=Vector2i(270,480);root.size=Vector2i(540,960);await process_frame
	m.S={"phase":"idle"};await capture(m,out,"owner_short")
	m.equipment.active_parts=[];await capture(m,out,"owner_missing_parts")
	print("OWNER_GAUGE_PREVIEW complete")
	m.audio_feedback.dispose();m.queue_free();await process_frame;quit()
