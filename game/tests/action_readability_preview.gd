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
	var m=load("res://main.gd").new();m.text_layer=txt;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame
	m.development_preview=true;m.set_process(false);m.title_open=false;m.lesson_open=false;m.tip_t=0;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.scene="fish";m.S={"phase":"idle"}
	m.active_region=0;m._layout();m.environment.show_scene(true);m.environment.set_hour(10.0);m.start_wait();m.S.sp=9;m.S.star=1;m.S.grade=1;m.S.lf=1.0;m.start_fight();m.S.tut=false;m.S.lesson="";m.reveal_pending=false;m.reveal_t=0;m.S.dist=35;m.S.fx=190;m.S.fy=m.WATER+80;m.S.dispY=m.S.fy
	for beh in ["tell","turn","rise","run","charge","jump"]:
		m.S.beh=beh;m.S.bt=.5;m.S.warningDuration=1.0;m.S.jumpDuration=1.2;m.S.jumpT=.6;m.S.tension=65;m.S.pose={};m.S.chargeX=0;m.S.dartX=0
		await capture(m,out,beh)
	for value in [20,40,65,85]:
		m.S.beh="swim";m.S.tension=value;await capture(m,out,"line_%d"%value)
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("ACTION_PREVIEW complete");quit()
