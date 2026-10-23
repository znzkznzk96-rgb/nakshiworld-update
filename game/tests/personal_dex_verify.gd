extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false;m.TUT.done=true
	var d=m.personal_dex;d.restore({});m.DEX={m.fish_key(1):[0,4]};m.REC={m.fish_key(1):45.0}
	check(d.best(m,1,"grade")=={"grade":4,"legacy":true},"legacy highest grade preserved without fabricated specimen")
	check(d.best(m,1,"length")=={"len":45.0,"legacy":true} and d.best(m,1,"weight").is_empty(),"legacy length retained and weight unknown")
	d.observe(1,3,35,0.4,"2026-10-23");d.observe(1,1,47,0.8,"2026-10-24");d.observe(1,2,40,1.0,"2026-10-25")
	check(d.best(m,1,"grade").get("legacy",false),"new lower grade cannot replace old highest")
	check(d.best(m,1,"length").grade==1 and d.best(m,1,"weight").grade==2,"separate best specimens")
	d.observe(1,4,36,0.7,"2026-10-26")
	check(not d.best(m,1,"grade").has("legacy") and d.best(m,1,"grade").date=="2026-10-26","equal legacy grade acquires known new specimen")
	d.observe(5,1,13,0.03,"2026-10-26");d.observe(20,2,15,0.05,"2026-10-26")
	check(d.records.has(m.fish_key(5)) and d.records.has(m.fish_key(20)),"same species name in separate regions stays separate")
	var saved: Dictionary=d.serialize();m._save_game();d.restore({});m._load_game()
	check(d.serialize()==saved,"new records survive save round trip")
	m.bag=[];m.aqua=[null,null,null];m._save_game();m._load_game()
	check(d.serialize()==saved,"records independent of held and displayed fish")
	m.development_preview=true;m.bait=10;m.start_wait();m.S.sp=2;m.S.star=0;m.S.grade=1;m.S.lf=1.0;m.S.len=5.0;m.start_catch()
	var count: Array=m.fish_counts(2).duplicate();var once: Dictionary=d.serialize();m.start_catch()
	check(m.fish_counts(2)==count and d.serialize()==once,"duplicate completion does not duplicate record")
	d.open(m);d.draw(m,480);check(d.rects.fish.size()==20,"all20 species on short screen")
	d.press(m,d.rects.fish[1][0].get_center());d.draw(m,480)
	check(d.selected==1 and d.rects.tabs.size()==3,"species opens trophy detail")
	d.press(m,d.rects.tabs[2].get_center());check(d.trophy==2,"weight trophy selectable")
	d.press(m,d.rects.back.get_center());check(d.selected==-1,"return to collection")
	m.scene="fish";m.S={"phase":"idle"};m.clock=10;m._process(.03);check(m.clock==10,"dex modal pauses fishing")
	d.press(m,d.rects.close.get_center());check(not d.opened,"close works")
	d.restore({"records":{"r0_s01":{"weight":{"grade":3,"len":10,"w":-1}}}});check(d.records.is_empty(),"invalid saved specimen ignored")
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("PERSONAL_DEX_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
