extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var d=load("res://addons/expedition/model.gd").new()
	d.restore({});check(d.discovered.is_empty(),"new save unknown")
	d.souls=[10,10,10,10,10];check(d.craft(0,0),"craft succeeds")
	var id: int=d.recipe(0,0);check(d.is_discovered(id),"craft records discovery")
	d.pending={};var second: Dictionary=d.add_unit(1)
	var old: Dictionary=d.serialize();old.erase("discovered");d.restore(old)
	check(d.is_discovered(id) and d.is_discovered(1),"legacy held soldiers migrated")
	for u in d.soldiers: u.level=3
	d.begin_merge(int(d.soldiers[0].uid),int(second.uid),1000)
	var saved: Dictionary=JSON.parse_string(JSON.stringify(d.serialize()));d.restore(saved)
	check(d.is_discovered(id) and d.is_discovered(1),"consumed material discoveries persist through pending merge reload")
	check(d.finish_merge(0),"pending merge resumes")
	check(d.is_discovered(int(d.soldiers[0].id)),"merge result discovered")
	d.restore({"discovered":[-1,15,2,2,2.5,"3",null]});check(d.discovered==[2],"invalid and duplicate records ignored")
	var m=load("res://main.gd").new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false
	m.expedition.data.restore({});m.personal_dex.open(m);m.personal_dex.draw(m,480)
	m.personal_dex.press(m,m.personal_dex.rects.regions[2].get_center());m.personal_dex.draw(m,480)
	check(m.personal_dex.region==2 and m.personal_dex.rects.fish.is_empty(),"soldier tab hides unknown details")
	m.expedition.data.add_unit(0);m.personal_dex.draw(m,480)
	check(m.personal_dex.rects.fish.size()==1,"only discovered soldier clickable")
	m.personal_dex.press(m,m.personal_dex.rects.fish[0][0].get_center());m.personal_dex.draw(m,480)
	check(m.personal_dex.rects.back.size.x>0,"soldier detail navigation")
	m.personal_dex.press(m,m.personal_dex.rects.back.get_center());m.personal_dex.draw(m,480)
	m.personal_dex.press(m,m.personal_dex.rects.regions[0].get_center());m.personal_dex.draw(m,480)
	check(m.personal_dex.rows_total==20,"fish tab retained")
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("SOLDIER_DEX_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
