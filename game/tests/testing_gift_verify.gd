extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
	m.testing_grants=[];m.gold=123;m.souls=7;m.expedition.data.souls=[1,2,3,4,5];m.bag=[{"sp":0,"star":0,"grade":0,"len":12,"w":0.08,"price":10,"shoulder":false}];m.aqua=[null,null,null]
	var Gift=load("res://addons/reservoir/testing_gift.gd")
	var dex: Dictionary=m.personal_dex.serialize();var counts: Dictionary=m.catch_counts.duplicate(true)
	check(Gift.claim(m),"claim persists")
	check(m.gold==1000123 and m.souls==1007 and m.expedition.data.souls==[51,52,53,54,55],"additive currency amounts")
	check(m.bag.size()==21 and m.bag[0].grade==0,"full bag preserves original and adds20")
	for i in 20: check(m.bag[i+1].sp==i and m.bag[i+1].grade==3,"one legendary per reservoir species")
	check(m.personal_dex.serialize()==dex and m.catch_counts==counts,"gift does not forge catch records")
	check(not Gift.claim(m),"repeat blocked")
	m._load_game();check(not Gift.claim(m) and m.bag.size()==21 and m.gold==1000123,"reload preserves claim and contents")
	m.testing_grants=[];var before: int=m.gold;var count: int=m.bag.size()
	DirAccess.make_dir_absolute("user://save.json.tmp")
	check(not Gift.claim(m) and m.gold==before and m.bag.size()==count and m.testing_grants.is_empty(),"failed save rolls back all grant contents")
	DirAccess.remove_absolute("user://save.json.tmp")
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("TESTING_GIFT_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
