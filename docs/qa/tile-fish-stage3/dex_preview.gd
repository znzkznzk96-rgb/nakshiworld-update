extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String):
	if not ok: failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func capture(m,out: String,name: String):
	m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name+".png"))
func run():
	var out: String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_size=Vector2i(270,540);root.size=Vector2i(810,1620)
	var app=load("res://tests/valley_native_root.gd").new();root.add_child(app);app._start()
	var m=app.box.get_child(0).get_child(0)
	m.development_preview=true;m.SET.sfx=0;m.SET.music=0;m.set_process(false)
	m.title_open=false;m.lesson_open=false;m.trans={};m.TUT.done=true;m.tip_t=0;m.S={"phase":"idle"}
	m.active_region=2;m._layout();m._switch_scene("village")
	var d=m.personal_dex;d.restore({});m.DEX={};m.REC={};m.catch_counts={}
	for sp in range(40,60):
		m.DEX[m.fish_key(sp)]=[0];m.REC[m.fish_key(sp)]=float(m.FISH_LEN[sp])
		m.catch_counts[m.fish_key(sp)]=[1,0,0,0,0]
		d.observe(sp,0,float(m.FISH_LEN[sp]),0.1,"TEST")
	d.open(m)
	check(d.area_ids()==range(40,60),"tile collection has exact stable IDs 40..59")
	for h in [480,540,660]:
		root.content_scale_size=Vector2i(270,h);root.size=Vector2i(810,h*3)
		await process_frame;app._fit();await process_frame;m._layout()
		d.selected=-1;d.scroll=0;await capture(m,out,"list_%d_00"%h)
		check(d.rows_total==20,"all20 rows at height %d"%h)
		var seen: Array=[]
		var pages: int=ceili(20.0/d.visible_rows)
		for page in pages:
			d.scroll=minf(float(page*d.visible_rows*d.row_height),d.maximum())
			await capture(m,out,"list_%d_%02d"%[h,page])
			for item in d.rects.fish:
				if item[1] not in seen:seen.append(item[1])
		check(seen.size()==20,"scroll covers every species at height %d"%h)
		var details: Array=range(40,60) if h==540 else [51,56]
		for sp in details:
			d.selected=sp
			await capture(m,out,"detail_%d_%02d"%[h,sp-39])
			check(m.text_items.any(func(it):return str(it[2])=="최대 무게"),"detail record cards shown")
			check(not d.best(m,sp,"grade").is_empty(),"regional specimen recorded")
		d.selected=-1
	d.restore({});m.DEX={};m.REC={};m.catch_counts={}
	d.open(m);d.scroll=0
	await capture(m,out,"unknown_660")
	check(d.rows_total==20 and m.text_items.any(func(it):return str(it[2])=="미발견"),"unknown species remain undiscovered")
	m.audio_feedback.dispose();app.queue_free();await process_frame;await process_frame
	print("TILE_DEX_STAGE3_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
