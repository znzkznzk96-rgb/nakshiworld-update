extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(m, dir: String, name: String) -> void:
	m.queue_redraw()
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	assert(not m.text_items.is_empty() and not m.ui_commands.is_empty(),"UI commands must be present in preview")
	root.get_texture().get_image().save_png(dir.path_join(name+".png"))
func run() -> void:
	var out: String=OS.get_cmdline_user_args()[0]
	root.content_scale_size=Vector2i(270,540)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.size=Vector2i(540,1080)
	var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
	var txt:=Node2D.new();txt.set_script(load("res://text_layer.gd"));ui.add_child(txt)
	var m=load("res://main.gd").new();m.text_layer=txt;m.SET.sfx=0;m.SET.music=0;m.title_open=false;root.add_child(m);await process_frame
	m.development_preview=true;m.set_process(false);m.title_open=false;m.lesson_open=false;m.tip_t=0;m.guide.opened=false;m.mailbox.opened=false;m.trans={}
	m._switch_scene("village");m.S={"phase":"idle"};m.ui_clock=10;m.gold=10000
	m.progression.restore({});m.V.open_shop(m,"museum")
	for area in 2:
		m.V.bundle_preview.region=area
		for kind in 3:
			m.V.bundle_preview.tab=kind
			await capture(m,out,"museum_%d_%d"%[area,kind])
	m.V.bundle_preview.region=0;m.V.bundle_preview.tab=0;m.V.bundle_preview.selected=0
	m.bag=[{"sp":1,"star":0,"grade":0,"len":24.0,"w":0.1,"price":13},{"sp":1,"star":0,"grade":2,"len":30.0,"w":0.2,"price":110}]
	await capture(m,out,"donation_choice")
	m.V.bundle_preview.selected=-1;m.V.open_shop(m,"work");m.V.tab="buyback";m.buyback.restore({})
	for i in 10: m.buyback.remember({"sp":i,"star":0 if i<8 else 1,"grade":i%5,"len":15.0+i,"w":0.1,"price":100+i*10})
	await capture(m,out,"buyback_top")
	m.buyback.scroll=m.buyback.max_scroll();await capture(m,out,"buyback_bottom")
	m.V.commerce.request(m.V,m,"buyback:%d"%int(m.buyback.entries[0].id));await capture(m,out,"buyback_confirm")
	m.V.commerce.pending={};m.V.open_shop(m,"museum");m.V.bundle_preview.region=1;m.V.bundle_preview.tab=0
	root.content_scale_size=Vector2i(270,480);root.size=Vector2i(540,960)
	await process_frame;await capture(m,out,"museum_short")
	print("BUNDLES_UI_PREVIEW complete")
	m.audio_feedback.dispose();m.queue_free();await process_frame;quit()
