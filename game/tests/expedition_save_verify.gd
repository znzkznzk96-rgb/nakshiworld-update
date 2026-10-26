extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label)
func same(a: Dictionary,b: Dictionary) -> bool:
	return JSON.parse_string(JSON.stringify(a))==JSON.parse_string(JSON.stringify(b))
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
	m.title_open=false;m.TUT.done=true;m.lesson_open=false;m.S={"phase":"idle"};m.scene="village"
	var v=m.expedition;var d=v.data;var store=load("res://addons/reservoir/save_store.gd")
	m.gold=1000;m.souls=77;m._save_game()
	var legacy: Dictionary=store.read("user://save.json");legacy.erase("expedition");store.write("user://save.json",legacy);m._load_game()
	check(d.soldiers.is_empty() and m.souls==77 and m.gold==1000,"legacy save preserves wallet")
	d.souls=[30,30,30,30,30];d.add_unit(0,2,[8,0,3]);d.add_unit(3,2,[0,8,4]);d.add_unit(6,1,[2,2,2]);d.team=[2,1,3]
	var before: Dictionary=d.serialize();check(d.begin_merge(1,2,0).is_empty() and d.serialize()==before,"unaffordable merge changes nothing")
	v.selected=[1,2];v.rects={"merge_confirm":Rect2(0,0,20,20)};v.press(m,Vector2(10,10))
	check(m.gold==800 and d.pending.kind=="merge" and d.soldiers.size()==1,"UI consumes both materials and fee atomically")
	var pending: Dictionary=d.serialize();d.restore({});m.gold=0;m._load_game()
	check(same(d.serialize(),pending) and m.gold==800 and m.souls==77,"pending result and payment survive actual disk reload")
	v.rects={"inherit:0":Rect2(0,0,20,20)};v.press(m,Vector2(10,10));var u: Dictionary=d.unit(int(d.pending.uid))
	check(u.iv==[8,0,3] and int(u.star)==3 and int(u.uid)==4,"inherit keeps IV vector and stable next UID")
	v.rects={"pending_done":Rect2(0,0,20,20)};v.press(m,Vector2(10,10));d.add_unit(1,1,[0,0,0]);d.team.append(5);m._save_game()
	var snap: Dictionary=d.serialize();m._load_game();check(same(d.serialize(),snap),"result confirmation cannot reroll")
	v.open(m,"explore");v.rects={"slot:0":Rect2(0,0,30,30),"slot:1":Rect2(40,0,30,30)}
	var a: int=d.team[0];var b: int=d.team[1]
	var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=true;e.position=Vector2(10+m.ox,10);check(v.input_event(m,e),"modal captures input")
	e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=false;e.position=Vector2(50+m.ox,10);v.input_event(m,e)
	check(d.team[0]==b and d.team[1]==a,"drag swaps front order")
	v.opened="";check(not v.input_event(m,InputEventMouseMotion.new()),"closed modal returns world input")
	check(d.start(1,Time.get_unix_time_from_system()),"start team")
	m.scene="fishing";v.update(m,.9);v.update(m,1.5);check(d.battle.ticks==1,"battle advances while fishing")
	m._save_game();snap=d.serialize();d.restore({});m._load_game();check(same(d.serialize(),snap),"combat resumes exact saved health and phase")
	for i in 1000:
		if not d.active(): break
		v.update(m,.2)
	var earned: int=d.battle.reward;var oldgold: int=m.gold
	v.rects={"claim":Rect2(0,0,20,20)};v.press(m,Vector2(10,10));v.press(m,Vector2(10,10));m._load_game()
	check(m.gold==oldgold+earned and d.battle.is_empty(),"reward claimed exactly once across reload")
	check(m.souls==77,"new materials never spend existing souls")
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("EXPEDITION_SAVE_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
