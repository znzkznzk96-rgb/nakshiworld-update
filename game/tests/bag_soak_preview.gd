extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_size=Vector2i(270,660);root.size=Vector2i(540,1320)
	var layer=CanvasLayer.new();layer.layer=10;root.add_child(layer)
	var txt=Node2D.new();txt.set_script(load("res://text_layer.gd"));layer.add_child(txt)
	var m=load("res://main.gd").new();m.development_preview=true;m.text_layer=txt;root.add_child(m);await process_frame
	print("READY");m.title_open=false;m.title_screen.leaving=false;m.lesson_open=false;m.trans={};m.TUT.done=true;m.SET.sfx=0;m.SET.music=0;m.bag=[]
	for i in 100: m.bag.append({"sp":i%20,"grade":i/20,"w":0.1,"len":10.0,"price":100})
	for scene in ["fish","village"]:
		print("SCENE ",scene)
		m.scene=scene;m.S={"phase":"idle"};m.V.shop="";m.market_open=false;m.inventory.selected=-1;m.inventory.tab="fish";m.menu_open=true;m.menu_t=-1
		await process_frame;await process_frame
		print("OPEN MENU ",m.ui_rects);m._menu_press(m.ui_rects.m_items[1].get_center());print("OPENED")
		var began: int=Time.get_ticks_msec();var n: int=0
		while Time.get_ticks_msec()-began<30000:
			await process_frame;n+=1
			if n%300==0: print("SOAK ",scene," ms=",Time.get_ticks_msec()-began," frames=",n," memory=",OS.get_static_memory_usage()," commands=",m.ui_commands.size()," text=",m.text_items.size())
		m.inventory.press(m,m.inventory.rects.close.get_center());print("CLOSE ",scene," open=",m.market_open)
	m.audio_feedback.dispose();m.queue_free();await process_frame;quit()
