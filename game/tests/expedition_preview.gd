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
	var m=load("res://main.gd").new();m.text_layer=txt;m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame
	m.development_preview=true;m.set_process(false);m.title_open=false;m.lesson_open=false;m.tip_t=0;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.scene="village";m.S={"phase":"idle"};m.V.enter(m)
	var v=m.expedition;var d=v.data;d.souls=[24,18,15,12,9];d.unlocked=10
	for i in 15: d.add_unit(i,2 if i in [0,3] else 1,[4,6,8])
	d.team=[4,1,7];v.selected_round=10
	for height in [480,540,660]:
		root.content_scale_size=Vector2i(270,height);root.size=Vector2i(540,height*2);await process_frame
		v.open(m,"explore");await capture(m,out,"route_%d"%height)
		v.open(m,"alchemy");v.tab=0;await capture(m,out,"alchemy_%d"%height)
		v.tab=2;await capture(m,out,"soldiers_%d"%height)
		v.tab=1;v.selected=[1,4];await capture(m,out,"merge_%d"%height)
		v.opened="merge_confirm";await capture(m,out,"confirm_%d"%height)
	v.opened="";m.menu_open=true;m.menu_t=-10;await capture(m,out,"menu")
	m.menu_open=false;d.start(10,Time.get_unix_time_from_system());d.battle.index=2;d.spawn_enemy();d.battle.phase="fight";d.battle.clock=.8
	await capture(m,out,"village_battle")
	v.open(m,"explore");await capture(m,out,"battle_detail")
	d.battle={};d.begin_merge(1,4,1000);v.open(m,"alchemy");await capture(m,out,"inherit")
	d.finish_merge(1);await capture(m,out,"result")
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("EXPEDITION_PREVIEW failures=",failures);quit()
