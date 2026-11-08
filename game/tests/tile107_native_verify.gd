extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String):
	if not ok: failures.append(label);push_error(label)
func _initialize(): call_deferred("run")
func capture(path: String):
	await process_frame;await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(path)
func run():
	var out: String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_size=Vector2i(270,660);root.size=Vector2i(810,1980)
	var app=load("res://tests/valley_native_root.gd").new();root.add_child(app);app._start()
	var sv: SubViewport=app.box.get_child(0);var m=sv.get_child(0)
	m.development_preview=true;m.SET.sfx=0;m.SET.music=0;m.set_process(false)
	m.title_open=false;m.lesson_open=false;m.trans={};m.TUT.done=true;m.tip_t=0;m.S={"phase":"idle"}
	var tile=m.environment.tile
	check(tile.native and tile.root.get_viewport()==root,"native plate bypasses actor viewport")
	check(tile.root.get_child_count()==1 and tile.plate.get_child_count()==4,"one approved plate with sunlight, surface, scenery and night glow")
	tile.scenery.animated=false;tile.scenery.elapsed=3;tile.scenery.queue_redraw()
	for h in [480,540,660]:
		root.content_scale_size=Vector2i(270,h);root.size=Vector2i(810,h*3)
		await process_frame;app._fit();await process_frame
		m.active_region=2;m._layout();m._switch_scene("fish");m.queue_redraw()
		check(sv.size==Vector2i(270,h) and sv.transparent_bg and tile.root.visible,"native composite at %d"%h)
		check(absf(tile.map_rect.position.y+tile.map_rect.size.y*tile.WATER_Y/tile.SOURCE.y-m.WATER)<=0.5,"water aligned at %d"%h)
		check(m.SURF<m.WATER and m.uw_bot>m.WATER,"usable underwater area %d"%h)
		await capture(out.path_join("tile_%d.png"%h))
		m._switch_scene("spots");m.spots.index=2;m.spots.scroll=2;m.spots.shift=0;m.queue_redraw()
		check(m.spots.images[2].resource_path=="res://art/refresh53/tile_sea.png","selection uses restored legacy picture at %d"%h)
		await capture(out.path_join("selection_%d.png"%h))
		m._switch_scene("village");check(not tile.root.visible,"village hides native plate")
		m.V.open_shop(m,"museum");m.V.bundle_preview.region=2
		for kind in 3:
			m.V.bundle_preview.tab=kind;m.queue_redraw()
			await capture(out.path_join("bundle_%d_%d.png"%[h,kind]))
		m.V.shop="";m.active_region=1;m._layout();m._switch_scene("fish")
		check(not tile.root.visible and m.environment.valley.root.visible,"valley transition")
		m.active_region=0;m._layout()
		check(not tile.root.visible and not sv.transparent_bg,"reservoir transition")
	var canvas=tile.native_canvas;m.audio_feedback.dispose();app.queue_free();await process_frame;await process_frame
	check(not is_instance_valid(canvas),"native canvas disposed")
	print("TILE107_NATIVE_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
