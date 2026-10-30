extends SceneTree
var failures: Array=[]
func _initialize() -> void: call_deferred("run")
func capture(m,out: String,name: String) -> void:
	m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name+".png"))
func run() -> void:
	var out: String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size=Vector2i(270,540);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.size=Vector2i(540,1080)
	var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
	var txt:=Node2D.new();txt.set_script(load("res://text_layer.gd"));ui.add_child(txt)
	var m=load("res://main.gd").new();m.text_layer=txt;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame
	m.development_preview=true;m.set_process(false);m.title_open=false;m.lesson_open=false;m.tip_t=0;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.scene="fish";m.S={"phase":"idle"}
	m.DEX={};m.REC={};m.personal_dex.restore({})
	for sp in range(14):
		m.DEX[m.fish_key(sp)]=[0,1,2,3,4] if sp%2==0 else [0,2];m.catch_counts[m.fish_key(sp)]=[10,2,1,0,0]
		m.personal_dex.observe(sp,2,m.FISH_LEN[sp]*1.05,.25,"2026-10-23")
		m.personal_dex.observe(sp,1,m.FISH_LEN[sp]*1.4,.5,"2026-10-23")
		m.personal_dex.observe(sp,0,m.FISH_LEN[sp]*1.2,.6,"2026-10-23")
	for height in [480,540,660]:
		root.content_scale_size=Vector2i(270,height);root.size=Vector2i(540,height*2);await process_frame
		m.personal_dex.open(m);await capture(m,out,"dex_collection_%d"%height)
		m.personal_dex.selected=1
		for trophy in 3:
			m.personal_dex.trophy=trophy;await capture(m,out,"dex_trophy_%d_%d"%[trophy,height])
		m.personal_dex.region=1;m.personal_dex.selected=-1;await capture(m,out,"dex_unknown_%d"%height)
	m.personal_dex.region=0;m.personal_dex.selected=18;m.DEX[m.fish_key(18)]=[0,3];m.REC[m.fish_key(18)]=82.0
	for trophy in 3:
		m.personal_dex.trophy=trophy;await capture(m,out,"dex_legacy_%d"%trophy)
	m.personal_dex.opened=false;m.scene="village";m.V.open_shop(m,"up");m.V.tab="bait";m.bait=50;m.region_shop.stocks[1]=5;m.region_shop.stocks[2]=8;m.gold=1000
	await capture(m,out,"bait_roles")
	for bait in 3:
		m.V.commerce.request(m.V,m,"bait:%d:5"%bait);await capture(m,out,"bait_purchase_%d"%bait);m.V.commerce.pending={}
	if absf(m.audio_feedback.village_music.stream.get_length()-27.0)>.1: failures.append("village loop duration")
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("RELEASE075_PREVIEW failures=",failures);quit(0 if failures.is_empty() else 1)
