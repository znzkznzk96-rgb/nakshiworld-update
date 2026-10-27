extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m=load("res://tests/pouch_test_main.gd").new();m.development_preview=true;m.SET.music=0;m.SET.sfx=0;root.add_child(m);await process_frame;m.set_process(false)
	m.title_open=false;m.TUT.done=true;m.trans={};m.market_open=true;m.market_sell=false;m.inventory.tab="inventory"
	var d=m.expedition.data;d.restore({});d.pouches=7
	m.inventory.draw(m)
	var rows: Array=m.equipment.rects.rows
	check(rows[0][1]=="pouch","pouch first visible inventory item")
	for pressed in [true,false]:
		var e=InputEventScreenTouch.new();e.position=rows[0][0].get_center()+Vector2(m.ox,0);e.pressed=pressed;m.inventory.input_event(m,e)
	var bag=m.inventory.pouch
	check(bag.opened,"inventory opens pouch dialog")
	var before: Dictionary=d.serialize().duplicate(true);m.fail_saves=true
	check(not bag.open_count(m,1) and d.serialize()==before and bag.result.is_empty(),"save failure restores all owned inventory")
	m.fail_saves=false
	check(bag.open_count(m,1) and d.pouches==6 and d.souls.reduce(func(a,b):return a+b,0)==1,"single open awards exactly once")
	check(not bag.open_count(m,1) and d.pouches==6,"double tap cannot consume again during or after animation")
	bag.draw(m);check(bag.rects.is_empty(),"animation has no active controls")
	m.ui_clock+=2;bag.draw(m);bag.press(m,bag.rects.confirm.get_center())
	check(not bag.opened,"result confirmation closes")
	bag.open(m);check(bag.open_count(m,0) and d.pouches==0 and d.souls.reduce(func(a,b):return a+b,0)==7,"all open preserves one soul per pouch")
	var saved: Dictionary=d.serialize().duplicate(true);d.restore({});m._load_game();check(d.serialize()==saved,"pouch and souls survive reload during animation")
	bag.open(m);bag.draw(m);check(not bag.rects.has("one") and not bag.rects.has("all"),"empty inventory buttons disabled")
	check(d.soldiers.is_empty() and m.bag.is_empty(),"does not create fish or soldiers")
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("POUCH_INVENTORY_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
