extends SceneTree
var failures:Array=[]
func _initialize()->void:call_deferred("run")
func capture(m,out:String,name:String)->void:
	m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name+".png"))
func run()->void:
	var out:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size=Vector2i(270,540);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.size=Vector2i(540,1080)
	var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
	var txt:=Node2D.new();txt.set_script(load("res://text_layer.gd"));ui.add_child(txt)
	var m=load("res://main.gd").new();m.text_layer=txt;m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame
	m.development_preview=true;m.set_process(false);m.title_open=false;m.lesson_open=false;m.tip_t=0;m.trans={};m.TUT.done=true;m.scene="village";m.S={"phase":"idle"};m.V.enter(m);m.gold=2500000;m.pearl=2
	for height in [480,660]:
		root.content_scale_size=Vector2i(270,height);root.size=Vector2i(540,height*2);await process_frame;m._layout()
		for lv in [0,2,5,6]:
			m.region_shop.unlocked=[0] if lv==2 else [0,1,2]
			m.aqua_lv=lv;m.boat_lv=lv;m.pond_cap_lv=lv;m.pond_regen_lv=lv;m.aqua=[];m.aqua.resize(m.aqua_capacity());m.pond_stock=m.pond_max()*0.65;m.pond_overflow=17 if lv==6 else 0
			m.aqua[0]={"sp":0,"star":0,"grade":1,"len":24.0,"w":0.1,"price":150}
			for shop in ["aqua","harbor","hall"]:
				m.V.open_shop(m,shop);m.text_items=[];m.V.draw_shop(m,height)
				for row in m.V.rects.rows:
					if not m.V.rects.panel.encloses(row[0]): failures.append("outside "+shop)
				await capture(m,out,"%s_lv%d_h%d"%[shop,lv,height])
	print("FACILITY_GROWTH_PREVIEW failures=",failures)
	m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
