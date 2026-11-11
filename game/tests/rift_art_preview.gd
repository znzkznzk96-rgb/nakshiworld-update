extends SceneTree
class Preview extends "res://main.gd":
	var sample_time:=0.0
	var sample_species:=-1
	func _draw()->void:
		if not boot_ready and cooperative_boot:return
		text_items=[];ui_commands=[];fish_grade_aura.begin_frame()
		if sample_species<0:
			for i in 20:
				var center:=Vector2(36+(i%4)*66,WATER+32+floori(i/4.0)*43)
				_shadow_fish(center,0,0,sample_time*1000,"swim",false,1,{},0,i+60,-1,1,46)
				_text("%02d"%(i+1),center+Vector2(0,18),6,Color("ede4ff"),true,60)
		else:
			_shadow_fish(Vector2(135,WATER+85),4,0,sample_time*1000,"swim",false,1,{},0,sample_species,-1,1,156)
		if text_layer:
			text_layer.items=text_items;text_layer.commands=ui_commands;text_layer.queue_redraw()
var failures:Array=[]
func _initialize():call_deferred("run")
func capture(path:String)->void:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var image:Image=root.get_texture().get_image()
	var actual:Color=image.get_pixel(image.get_width()/2,20)
	if actual.b<=actual.g or actual.r>=actual.b:failures.append("rift purple plate visible: "+path)
	image.save_png(path)
func run():
	var out:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size=Vector2i(270,660);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.size=Vector2i(540,1320)
	var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
	var text:=Node2D.new();text.set_script(load("res://text_layer.gd"));ui.add_child(text)
	var m=Preview.new();m.text_layer=text;m.SET.sfx=0;m.SET.music=0;m.development_preview=true;root.add_child(m);await process_frame;m.set_process(false)
	m.title_open=false;m.title_screen.leaving=false;m.title_screen.root.hide()
	m.active_region=3;m._layout();m.environment.show_scene(true)
	for frame in [0,4,8,12]:
		m.sample_time=(frame+.25)*.06;m.queue_redraw();await capture(out.path_join("gallery-%02d.png"%frame))
	for sp in [60,73,79]:
		m.sample_species=sp;m.sample_time=.255;m.queue_redraw();await capture(out.path_join("fight-%02d.png"%sp))
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("RIFT_ART_PREVIEW failures=",failures," renders=7");quit(0 if failures.is_empty() else 1)
