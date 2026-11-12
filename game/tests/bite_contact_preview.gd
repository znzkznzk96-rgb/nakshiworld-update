extends SceneTree
class Preview extends "res://main.gd":
	var gallery := false
	var sample_time := 0.0
	func _draw() -> void:
		if not gallery: super._draw();return
		ui_demo=true;text_items=[];ui_commands=[];fish_grade_aura.begin_frame()
		draw_rect(Rect2(0,0,270,660),Color("224857"))
		for sp in 80:
			var center:=Vector2(27+(sp%5)*54,12+floori(sp/5.0)*40)
			WATER=center.y
			S={"phase":"hook","sp":sp,"star":sp%5,"size":sp%4}
			var face:=1.0 if sp%2==0 else -1.0
			bite_preview.draw(self,center+Vector2(-8,12),sample_time*1000,face,.8,{"amp":.08,"curl":0.0,"tilt":-1.1,"stretch":1.0,"tailAmp":1.4,"freq":3.0},sample_time*TAU*3,center+Vector2(0,1),1)
			_draw_bobber(center.x,center.y)
			_text("%02d"%(sp+1),center+Vector2(0,27),6,Color("d8e6dc"),true,45)
		if text_layer:text_layer.items=text_items;text_layer.commands=ui_commands;text_layer.queue_redraw()
var failures:Array=[]
var output:String
func _initialize() -> void:call_deferred("run")
func capture(m,name:String) -> void:
	m._last_draw_t=-1;m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output.path_join(name+".png"))!=OK:failures.append(name)
func run() -> void:
	output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_size=Vector2i(270,660);root.size=Vector2i(810,1980)
	var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
	var text:=Node2D.new();text.set_script(load("res://text_layer.gd"));ui.add_child(text)
	var m=Preview.new();m.text_layer=text;m.development_preview=true;m.SET.music=0;m.SET.sfx=0;root.add_child(m);await process_frame;m.set_process(false)
	m.title_open=false;m.title_screen.leaving=false;m.title_screen.root.hide();m.lesson_open=false;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.tip_t=0;m.scene="fish";m.bg_node.visible=true
	m.environment.set_hour(18);m.environment.update(0)
	for height in ([] if OS.get_cmdline_user_args().has("--gallery-only") else [480,540,660]):
		root.content_scale_size=Vector2i(270,height);root.size=Vector2i(810,height*3);await process_frame
		for sp in [2,19,20,39,40,59,60,65,72,75,77,79]:
			m.active_region=mini(3,sp/20);m._layout();m.environment.show_scene(true);m.start_wait();m.S.sp=sp;m.S.size=sp%4;m.S.star=sp%5;m.S.grade=0;m.S.biteAt=10;m.S.realUntil=12;m.S.fakes=[];m.clock=10.4;m.start_hook();m.reveal_pending=false;m.reveal_t=0;m.judge_t=0;m.visibility_flash=0
			await capture(m,"phone_%d_%02d"%[height,sp])
	root.content_scale_size=Vector2i(270,660);root.size=Vector2i(810,1980);await process_frame
	m.active_region=3;m._layout();m.environment.show_scene(true);m.start_wait();m.S.sp=75;m.S.size=3;m.S.biteAt=10;m.S.fakes=[];m.clock=10.4;m.start_hook()
	for frame in (0 if OS.get_cmdline_user_args().has("--gallery-only") else 32):
		m.clock=10.4+frame*.06;await capture(m,"motion_%02d"%frame)
	m.gallery=true;m.ui_demo=true;m.environment.show_scene(false);m.bg_node.visible=false
	for frame in [0,4,8,12]:
		m.sample_time=(frame+.25)*.06;await capture(m,"gallery_%02d"%frame)
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("BITE_CONTACT_PREVIEW failures=",failures," native_screens=",4 if OS.get_cmdline_user_args().has("--gallery-only") else 72)
	quit(0 if failures.is_empty() else 1)
