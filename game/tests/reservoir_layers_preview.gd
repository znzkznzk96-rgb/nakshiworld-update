extends SceneTree
func _initialize() -> void:call_deferred("run")
func capture(m,out: String,name: String) -> void:
	m.environment.update(0);m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	image.save_png(out.path_join(name+".png"))
	print("CAPTURE ",name," ",image.get_size())
func run() -> void:
	var out: String=OS.get_cmdline_user_args()[0]
	root.content_scale_size=Vector2i(270,660);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.size=Vector2i(1080,2640)
	var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
	var txt:=Node2D.new();txt.set_script(load("res://text_layer.gd"));ui.add_child(txt)
	var m=load("res://main.gd").new();m.text_layer=txt;m.SET.sfx=0;m.SET.music=0;m.title_open=false;root.add_child(m);await process_frame
	m.development_preview=true;m.set_process(false);m.title_open=false;m.TUT.done=true;m.lesson_open=false;m.tip_t=0;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.scene="fish";m.bait=100;m.gold=12345;m.pearl=2
	m.S={"phase":"idle"};m.active_region=0;m._layout();m.environment.show_scene(true);m.equipment.active_parts=[]
	for h in [12.0,18.5,22.0]:
		m.environment.set_hour(h);m.environment.elapsed=12.0;m.environment.update(0)
		await capture(m,out,"reservoir_%s"%str(h).replace(".","_"))
	m.environment.set_hour(12);m.environment.elapsed=27;m.environment.update(0);await capture(m,out,"reservoir_sand_bury")
	m.environment.elapsed=35;m.environment.update(0);await capture(m,out,"reservoir_sand_hidden")
	m.environment.elapsed=43;m.environment.update(0);await capture(m,out,"reservoir_sand_emerge")
	m.environment.elapsed=12;m.environment.update(0)
	for kind in m.environment.layers:m.environment.layers[kind].enabled=false
	m.environment.moon.hide();await capture(m,out,"reservoir_static_base")
	for kind in m.environment.layers:m.environment.layers[kind].enabled=true
	m.environment.moon.show();m.environment.light_layer.enabled=false;await capture(m,out,"reservoir_rays_off")
	m.environment.light_layer.enabled=true
	m.equipment.active_parts=["float","hook","line","reel"];m.progression.owner_gauge[0]=73
	await capture(m,out,"reservoir_owner")
	m.start_wait();m.S.grade=0;m.start_hook();await capture(m,out,"reservoir_hook")
	m.start_fight();m.S.dist=30.0;await capture(m,out,"reservoir_fight")
	m.S={"phase":"idle"};m.equipment.active_parts=[]
	root.content_scale_size=Vector2i(270,480);root.size=Vector2i(1080,1920);await process_frame;m._layout();m.environment.set_hour(22)
	await capture(m,out,"reservoir_short_night")
	m.active_region=1;m._layout();m.environment.show_scene(true);await capture(m,out,"valley_unchanged")
	m.environment.show_scene(false);m.scene="village";await capture(m,out,"village_no_reservoir_layers")
	print("RESERVOIR_LAYERS_PREVIEW complete")
	m.queue_free();await process_frame;quit()
