extends SceneTree
var failures:Array=[]
func _initialize()->void:call_deferred("run")
func capture(m,path:String)->void:
	m.text_items=[];m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func configure(m,ids:Array,mode:String)->void:
	var v=m.expedition;var d=v.data;d.restore({});d.unlocked=10
	for id in ids:d.team.append(d.add_unit(id,3,[4,4,4]).uid)
	d.start(1,1000);d.battle.phase="fight";d.battle.enemy.hp=100000;d.battle.enemy.max_hp=100000;d.battle.clock=.4
	for f in d.battle.fighters:f.hp=int(f.max_hp)*.6
	if mode=="prepare":d.battle.skill_time=2.9;d.battle.skill_accumulator=.06
	else:
		d.battle.skill_time=3
		for f in d.battle.fighters:d.TIER_SKILLS.cast(d,f);f.skill_ready=99
		d.battle.skill_time=3.13;d.battle.fx.age=.13
	if mode=="mixed":
		for f in d.battle.fighters:d.battle.fx.attacks.append({"source":f.uid,"amount":123,"role":"attack"})
	for f in d.battle.fighters:
		if v.skill_feedback.cue(d,f).is_empty():failures.append("missing caster cue "+str(f.id))
func run()->void:
	var out:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
	var txt:=Node2D.new();txt.set_script(load("res://text_layer.gd"));ui.add_child(txt)
	var m=load("res://main.gd").new();m.text_layer=txt;m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
	m.title_open=false;m.lesson_open=false;m.tip_t=0;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.scene="village";m.S={"phase":"idle"};m.V.enter(m)
	for height in [480,540,660]:
		root.content_scale_size=Vector2i(270,height);root.size=Vector2i(540,height*2);await process_frame;m._layout()
		for mode in ["prepare","cast","support","mixed"]:
			configure(m,[3,7,12] if mode=="support" else [0,1,5],mode)
			m.expedition.open(m,"explore");m.expedition.explore_tab=0
			await capture(m,out.path_join("%s-detail-h%d.png"%[mode,height]))
			m.expedition.opened=""
			await capture(m,out.path_join("%s-strip-h%d.png"%[mode,height]))
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("SOLDIER_SKILL_CUES_PREVIEW failures=",failures);quit(0 if failures.is_empty() else 1)
