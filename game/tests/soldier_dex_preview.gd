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
	var v=m.expedition;var d=v.data;d.restore({});d.souls=[24,18,15,12,9]
	for height in [480,540,660]:
		root.content_scale_size=Vector2i(270,height);root.size=Vector2i(540,height*2);await process_frame
		d.discovered=[];v.open(m,"alchemy");v.tab=0;v.pair=[4,4]
		await capture(m,out,"unknown_%d"%height)
		d.discover(d.recipe(4,4));await capture(m,out,"known_%d"%height)
		v.opened="";m.personal_dex.open(m);m.personal_dex.category="soldier"
		for id in [0,3,6,9,12]: d.discover(id)
		await capture(m,out,"codex_%d"%height)
		m.personal_dex.selected=d.recipe(4,4);await capture(m,out,"detail_%d"%height)
		m.personal_dex.opened=false
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("SOLDIER_DEX_PREVIEW failures=",failures);quit()
