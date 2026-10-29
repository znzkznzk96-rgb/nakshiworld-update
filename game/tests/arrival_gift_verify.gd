extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
	m.testing_grants=["testing-20261026-078"];m.gold=123;m.souls=7;m.expedition.data.souls=[1,2,3,4,5];m.bag=[{"sp":0,"star":0,"grade":0,"len":12,"w":0.08,"price":10,"shoulder":false}];m.aqua=[null,null,null]
	var Gift=load("res://addons/reservoir/arrival_gift.gd")
	var dex: Dictionary=m.personal_dex.serialize();var counts: Dictionary=m.catch_counts.duplicate(true)
	check(Gift.claim(m),"claim persists")
	check(m.gold==100123 and m.souls==7 and m.expedition.data.souls==[1,2,3,4,5],"additive currency amounts")
	check(m.bag.size()==21 and m.bag[0].grade==0,"full bag preserves original and adds20")
	for i in 20: check(m.bag[i+1].sp==i and m.bag[i+1].grade==3,"one legendary per reservoir species")
	check(m.personal_dex.serialize()==dex and m.catch_counts==counts,"gift does not forge catch records")
	check(not Gift.claim(m),"repeat blocked")
	check("testing-20261026-078" in m.testing_grants,"old gift marker preserved")
	m.mailbox.detail="0.93";m.mailbox.draw(m,660);check(m.mailbox.rects.has("gift"),"new mail exposes claim button")
	m.scene="fish";m.title_open=false;m.trans={};m.TUT.done=true;m.lesson_open=false;m.mailbox.opened=false
	for phase in ["cast","wait","hook","pre","fight","catch","fail"]:
		m.S={"phase":phase};m.bait_picker.draw_button(m,500);check(not m.bait_picker.visible(m) and m.bait_picker.button.size==Vector2.ZERO,"bait hidden during "+phase)
	m.S={"phase":"idle"};m.region_shop.selected_bait=-1;m.text_items=[];m.ui_commands=[];m.bait_picker.draw_button(m,500)
	check(m.ui_commands.size()==1 and m.text_items.is_empty(),"bare hook shows only empty slot frame")
	m._load_game();check(not Gift.claim(m) and m.bag.size()==21 and m.gold==100123,"reload preserves claim and contents")
	m.testing_grants=[];var before: int=m.gold;var count: int=m.bag.size()
	DirAccess.make_dir_absolute("user://save.json.tmp")
	check(not Gift.claim(m) and m.gold==before and m.bag.size()==count and m.testing_grants.is_empty(),"failed save rolls back all grant contents")
	DirAccess.remove_absolute("user://save.json.tmp")
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("ARRIVAL_GIFT_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
