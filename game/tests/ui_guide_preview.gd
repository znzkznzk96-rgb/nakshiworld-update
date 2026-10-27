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
	m.gold=957184;m.pearl=2;m.V.camera_x=889;m.aqua_lv=2
	m.aqua[0]={"sp":1,"grade":3,"w":1.0,"len":20.0}
	for height in [480,660]:
		root.content_scale_size=Vector2i(270,height);root.size=Vector2i(540,height*2);await process_frame
		m._layout();m.mailbox.opened=false;m.guide.opened=false
		await capture(m,out,"village_%d"%height)
		m.mailbox.opened=true;m.mailbox.detail="0.87";m.mailbox.full_text=false
		await capture(m,out,"mail_B_%d"%height)
		m.mailbox.full_text=true;await capture(m,out,"mail_detail_%d"%height)
		m.mailbox.opened=false;m.guide.opened=true;m.guide.tab=5;m.guide.topic=0;m.guide.page=0
		await capture(m,out,"guide_souls_%d"%height)
		m.guide.tab=0;m.guide.topic=3;await capture(m,out,"guide_owner_%d"%height)
	m.audio_feedback.dispose();m.queue_free();await process_frame;quit()
