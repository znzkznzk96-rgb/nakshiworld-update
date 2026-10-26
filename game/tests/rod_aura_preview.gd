extends SceneTree
var failures: Array=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var out: String=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size=Vector2i(270,660);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.size=Vector2i(540,1320)
	var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
	var text:=Node2D.new();text.set_script(load("res://text_layer.gd"));ui.add_child(text)
	var m=load("res://main.gd").new();m.text_layer=text;m.SET.sfx=0;m.SET.music=0;m.title_open=false;root.add_child(m);await process_frame
	m.development_preview=true;m.set_process(false);m.title_open=false;m.lesson_open=false;m.tip_t=0;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.TUT.seen=m.BOOK_KEYS.duplicate()
	var cases: Array=[]
	for rod in 6:cases.append(["rod_%d_max"%rod,"wait",0.0,rod,false,.4])
	cases.append_array([["silver2_day","wait",0.0,5,false,0.0],["blue4_day","wait",0.0,5,false,0.0],["silver2_night","wait",0.0,5,false,0.0],["blue4_night","wait",0.0,5,false,0.0],["cast20","cast",.67,5,false,0.0],["fight20","fight",0.0,5,true,.85],["small","wait",0.0,5,false,0.0]])
	for c in cases:
		if c[0]=="small":root.content_scale_size=Vector2i(270,480);root.size=Vector2i(540,960)
		elif c[0]=="valley":root.content_scale_size=Vector2i(270,660);root.size=Vector2i(540,1320);m.active_region=1
		await process_frame;m._layout();m.environment.set_hour(22.0 if "night" in c[0] else 10.0)
		m.rod_lv=c[3];m.forge_lv=2 if "silver" in c[0] else (4 if "blue" in c[0] else m.ROD_MAX[m.rod_lv]);m.equipment.rod_equipped=true;m.start_wait();m.S.judge="GREAT";m.S.sp=1;m.S.star=0;m.S.grade=0;m.S.lf=1.0;m.S.len=25.0
		if c[1] in ["fight","catch"]:m.start_fight()
		if c[1]=="catch":m.start_catch()
		m.S.phase=c[1];m.S.t=c[2];m.holding=c[4];m.S.tension=c[5]*100;m.clock=1.0;m.cat_t=1.0;m.fclock=1.0;m.tip_t=0;m.judge_t=0;m.lesson_open=false
		m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
		var d: Dictionary=m.angler_scene.debug
		if d.get("aura_tier",-1)!=int(m.forge_lv/2):failures.append(c[0]+" actual enhancement tier")
		if not d.get("tip",Vector2(INF,INF)).is_finite():failures.append(c[0]+" finite tip")
		if float(d.get("front_error",1))>.001 or float(d.get("rear_error",1))>.001:failures.append(c[0]+" arm reach")
		root.get_texture().get_image().save_png(out.path_join(c[0]+".png"))
	m.audio_feedback.dispose();print("ROD_AURA_PREVIEW failures=",failures);quit(0 if failures.is_empty() else 1)
