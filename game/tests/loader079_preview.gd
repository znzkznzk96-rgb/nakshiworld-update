extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var out: String=OS.get_cmdline_user_args()[0]
	root.content_scale_size=Vector2i(270,660);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.size=Vector2i(540,1320)
	var loader=load("res://root.gd").new();root.add_child(loader);loader.http.cancel_request();loader.set_process(false);loader.started=true;loader.status="업데이트 확인 중…"
	print("IMAGE ",loader.update_art.get_size()," PIXEL ",loader.update_art.get_image().get_pixel(350,800))
	loader.queue_redraw()
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("updater.png"));quit()
