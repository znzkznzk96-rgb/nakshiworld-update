extends SceneTree
var failures: Array = []
func check(ok: bool, label: String):
	if not ok:
		failures.append(label)
		push_error(label)
func _initialize():
	call_deferred("run")
func capture(path: String):
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(path)
func run():
	var out: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_size=Vector2i(270,660)
	root.size=Vector2i(1080,2640)
	var app=load("res://tests/valley_native_root.gd").new()
	root.add_child(app)
	await app._start()
	var sv: SubViewport=app.box.get_child(0)
	var m=sv.get_child(0)
	m.development_preview=true;m.SET.sfx=0;m.SET.music=0
	m.title_open=false;m.lesson_open=false;m.trans={};m.TUT.done=true;m.tip_t=0
	m.set_process(false)
	var valley=m.environment.valley
	check(valley.native,"actual app enables native scenery")
	check(valley.root.get_viewport()==root,"background bypasses low resolution viewport")
	check(valley.native_canvas.layer<0,"background canvas below actor composite")
	check(m.get_viewport()==sv,"actor raster resolution unchanged")
	for h in [480,540,660]:
		root.content_scale_size=Vector2i(270,h)
		root.size=Vector2i(1080,h*4)
		await process_frame
		app._fit();await process_frame
		m.active_region=1;m._layout();m._switch_scene("fish")
		m.environment.valley.elapsed=5.0
		# Processing is paused for deterministic captures; refresh actor draw commands after layout.
		m.queue_redraw()
		check(sv.size==Vector2i(270,h),"actor viewport stays logical at %d"%h)
		check(sv.transparent_bg and valley.root.visible,"native scenery composite visible %d"%h)
		check(absf(valley.map_rect.position.y+valley.map_rect.size.y*0.565-m.WATER)<=0.5,"water anchor matches %d"%h)
		await capture(out.path_join("after_%d.png"%h))
		# Reproduce v1.05 parentage with the same artwork, state and frame.
		valley.root.reparent(m,false)
		await capture(out.path_join("before_%d.png"%h))
		valley.root.reparent(valley.native_canvas,false)
		m.active_region=0;m._layout()
		check(not valley.root.visible and not sv.transparent_bg,"reservoir transition %d"%h)
		m.active_region=1;m._layout();m._switch_scene("village")
		check(not valley.root.visible,"village hides external scenery %d"%h)
		m._switch_scene("fish")
		check(valley.root.visible,"return to valley %d"%h)
	var canvas=valley.native_canvas
	m.audio_feedback.dispose();app.queue_free()
	await process_frame;await process_frame
	check(not is_instance_valid(canvas),"external canvas cleaned up with game")
	print("VALLEY_NATIVE_VERIFY failures=",failures)
	quit(0 if failures.is_empty() else 1)
