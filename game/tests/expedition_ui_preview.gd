extends SceneTree
var failures: Array=[]
func _initialize() -> void: call_deferred("run")
func capture(m,out: String,name: String) -> void:
	m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name+".png"))
func run() -> void:
	var out: String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size=Vector2i(270,540);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.size=Vector2i(540,1080)
	var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
	var txt:=Node2D.new();txt.set_script(load("res://text_layer.gd"));ui.add_child(txt)
	var m=load("res://main.gd").new();m.text_layer=txt;m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame
	m.development_preview=true;m.set_process(false);m.title_open=false;m.lesson_open=false;m.tip_t=0;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.scene="village";m.S={"phase":"idle"};m.V.enter(m)
	var v=load("res://tests/expedition_ui_proposal.gd").new();v.setup();m.expedition=v
	var d=v.data;d.unlocked=10
	for id in [3,0,7]: d.team.append(d.add_unit(id,2,[4,4,4]).uid)
	d.start(3,1000);d.battle.phase="fight";d.battle.clock=.4;d.battle.fighters[0].hp=100;d.tick();d.battle.fx.age=.28
	for height in [480,660]:
		root.content_scale_size=Vector2i(270,height);root.size=Vector2i(540,height*2);await process_frame
		m._switch_scene("village");v.opened="explore"
		for kind in ["success","failure"]:
			v.proposal=kind;await capture(m,out,"%s_%d"%[kind,height])
		v.proposal="compact";v.opened="";m._switch_scene("fish");m._layout();m.environment.set_hour(12);m.environment.update(0)
		await capture(m,out,"fishing_%d"%height)
		m._switch_scene("village");v.proposal="";v.opened="explore";v.explore_tab=1;d.battle.status="lose"
		await capture(m,out,"formation_%d"%height)
		v.explore_tab=0;d.battle.status="running"
		await capture(m,out,"damage_%d"%height)
	m.audio_feedback.dispose();m.queue_free();await process_frame;quit()
