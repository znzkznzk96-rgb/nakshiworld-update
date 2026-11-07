extends SceneTree
func _initialize():call_deferred("run")
func capture(m,out: String,name: String):
	m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name+".png"))
func run():
	var args=OS.get_cmdline_user_args();var h: int=int(args[1]);var out: String=args[0]
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_size=Vector2i(270,h);root.size=Vector2i(810,h*3)
	var app=load("res://tests/valley_native_root.gd").new();root.add_child(app);app._start()
	var m=app.box.get_child(0).get_child(0)
	m.SET.sfx=0;m.SET.music=0;m.set_process(false);m.title_open=false;m.TUT.done=true;m.lesson_open=false;m.trans={};m.S={"phase":"idle"}
	m.testing_grants=["reservoir-legendary-20261029-093"];m.gold=123;m.bag=[]
	m._switch_scene("village");m.V.shop=""
	m.mailbox.opened=true;m.mailbox.detail="1.08";m.mailbox.topic=0;m.mailbox.full_text=false;m._layout()
	await capture(m,out,"mail_"+str(h)+"_before")
	m.mailbox.press(m,m.mailbox.rects.gift.get_center())
	assert(m.gold==1000123 and m.bag.size()==20)
	await capture(m,out,"mail_"+str(h)+"_claimed")
	m.mailbox.full_text=true;await capture(m,out,"mail_"+str(h)+"_detail")
	m.audio_feedback.dispose();app.queue_free();await process_frame;await process_frame
	print("VALLEY_GIFT108_PREVIEW failures=[]");quit()
