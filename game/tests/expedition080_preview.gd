extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(m,out: String,name: String) -> void:
	m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name+".png"))
func run() -> void:
	var out: String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size=Vector2i(270,660);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.size=Vector2i(540,1320)
	var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
	var txt:=Node2D.new();txt.set_script(load("res://text_layer.gd"));ui.add_child(txt)
	var m=load("res://main.gd").new();m.text_layer=txt;m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame
	m.set_process(false);m.title_open=false;m.lesson_open=false;m.tip_t=0;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.scene="village";m.S={"phase":"idle"};m.V.enter(m)
	var v=m.expedition;var d=v.data;d.restore({});d.souls=[50,50,50,50,50];m.gold=1000000
	for id in [3,0,6]: d.team.append(d.add_unit(id,1,[3,4,5]).uid)
	d.soldiers[0].locked=true;v.open(m,"alchemy");v.tab=2;await capture(m,out,"locks")
	v.training_uid=1;v.opened="training";await capture(m,out,"training")
	v.open(m,"explore");v.explore_tab=1
	await capture(m,out,"formation")
	v.explore_tab=0;await capture(m,out,"route")
	v.opened="";d.start(1,Time.get_unix_time_from_system())
	DirAccess.make_dir_recursive_absolute(out.path_join("motion"))
	for f in 150:
		v.update(m,.1);m.ui_clock+=.1
		await capture(m,out.path_join("motion"),"%04d"%f)
		if f==103: await capture(m,out,"combat")
	m.scene="fishing";v.opened="";d.finish(true);v.result_notice=6;v.update(m,.01);await capture(m,out,"fishing_result")
	m.scene="village";v.update(m,.01);await capture(m,out,"village_result")
	root.content_scale_size=Vector2i(270,480);root.size=Vector2i(540,960);await process_frame
	v.open(m,"explore");v.explore_tab=1;await capture(m,out,"formation_480")
	v.open(m,"alchemy");v.tab=2;await capture(m,out,"upgrade_480")
	m.audio_feedback.dispose();m.queue_free();await process_frame;ui.queue_free();await process_frame
	quit()
