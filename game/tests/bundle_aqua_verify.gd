extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func fish(sp: int, grade: int=0) -> Dictionary:
	return {"sp":sp,"star":0,"grade":grade,"len":23.5,"w":0.01,"price":100+grade*100,"shoulder":false}
func run() -> void:
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false;m.lesson_open=false;m.scene="village";m.S={"phase":"idle"}
	var p=m.progression;p.restore({});m.gold=0;m.souls=0;m.pearl=0;m.bag=[]
	for sp in p.SUB_SPECIES[0]: m.bag.append(fish(sp))
	m.bag.push_front(fish(0,4));m.bag.append(fish(19))
	check(p.donate_all(m,0,1)==6,"bulk donates six needed specimens")
	check(m.bag.size()==2 and m.bag[0].grade==4,"bulk preserves rare duplicate and unrelated fish")
	check(m.gold==0 and m.souls==0 and p.bundle_done(0,1),"completion is pending")
	m._save_game();p.restore({});m._load_game()
	check(not p.claimed(0,1) and p.bundle_done(0,1),"pending survives reload")
	m.development_preview=true
	check(not p.claim_reward(m,0,1) and m.gold==0 and not p.claimed(0,1),"claim save failure rolls back")
	m.development_preview=false
	check(p.claim_reward(m,0,1) and m.gold==720 and m.souls==15,"claim exact reward")
	check(not p.claim_reward(m,0,1) and m.gold==720,"double claim blocked")
	m._save_game();p.restore({});m._load_game();check(not p.claim_reward(m,0,1),"double claim after reload blocked")
	p.restore({"extra_completed":{"0:1":true},"bundle_values":{"0:1":600}})
	check(p.claimed(0,1) and not p.claim_reward(m,0,1),"legacy automatic reward never duplicated")
	p.restore({});m.bag=[]
	for sp in p.MAIN_SPECIES[0]: m.bag.append(fish(sp))
	m.development_preview=true
	check(p.donate_all(m,0,0)==0 and m.bag.size()==6 and not p.bundle_done(0,0),"failed bulk save restores fish and progress")
	m.development_preview=false
	check(p.donate_all(m,0,0)==6 and not p.licensed(1),"certificate waits for claim")
	check(p.claim_reward(m,0,0) and p.licensed(1),"certificate claim unlocks eligibility")
	var v=m.V;var a=v.aquarium;v.open_shop(m,"aqua");a.act(v,m,"amanage");m.aqua=[null,null,null];m.bag=[fish(1),fish(2),fish(3),fish(4)]
	a.act(v,m,"put:0");check(v.shop=="aqua" and v.aqua_manage and a.list_bag and m.aqua_count()==1,"put stays on same list")
	a.act(v,m,"put:0");a.act(v,m,"put:0");a.act(v,m,"put:0")
	check(m.aqua_count()==3 and m.bag.size()==1,"full aquarium preserves remaining fish")
	a.act(v,m,"alist_tank");a.act(v,m,"take:1")
	check(v.aqua_manage and not a.list_bag and m.aqua_count()==2 and m.bag.size()==2,"take stays on displayed list")
	m.development_preview=true;a.act(v,m,"put:0")
	check(m.aqua_count()==2 and m.bag.size()==2,"failed transfer save rolls back")
	m.development_preview=false
	a.viewport=Rect2(24,220,222,120);a.count=30;a.scroll=0
	var wheel:=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN;wheel.pressed=true;wheel.position=Vector2(100+m.ox,250)
	check(a.input_event(v,m,wheel) and a.scroll==44,"wheel scroll")
	v.rects.rows=[[Rect2(30,230,180,36),"take:0"]]
	a.begin(v,m,Vector2(50,240));a.move(Vector2(50,260));a.finish(v,m,Vector2(50,240))
	check(m.aqua_count()==2,"drag does not transfer fish")
	# Recover completion with missing certificate, while preserving already paid old rewards.
	p.restore({"main_completed":[true],"certificates":[false]})
	check(not p.claimed(0,0) and p.claim_reward(m,0,0) and p.licensed(1),"missing legacy license can be received")
	p.restore({"donations":{"0":[1,1,1,1,1,1]},"extra_donations":{"0:1":[1,1,1,1,1,1]},"bundle_values":{"0:1":600}})
	check(p.bundle_done(0,0) and p.bundle_done(0,1) and not p.claimed(0,1),"complete donations with missing completion flag recover as pending")
	check(p.claim_reward(m,0,1),"recovered pending reward can be received")
	var balance: int=m.gold
	m._save_game();m._load_game();check(not p.claim_reward(m,0,1) and m.gold==balance,"recovered reward remains single receipt")
	p.restore({});m.bag=[]
	for sp in p.SUB_SPECIES[0]: m.bag.append(fish(sp))
	m.bag.push_front(fish(0,4))
	v.open_shop(m,"museum");var ui=v.bundle_preview;ui.region=0;ui.tab=1
	ui.draw(m,660);ui.press(m,ui.rects.register.get_center())
	check(ui.bulk_open and m.bag.size()==7 and ui.bulk_plan.size()==6,"first button previews without consuming")
	ui.draw(m,660);ui.press(m,ui.rects.bulk_cancel.get_center())
	check(m.bag.size()==7 and not ui.bulk_open,"cancel preserves all specimens")
	ui.draw(m,660);ui.press(m,ui.rects.register.get_center());ui.draw(m,660)
	var expected: Array=ui.bulk_plan.duplicate(true)
	m.bag[1].price=999
	check(p.donate_all(m,0,1,expected)==0 and m.bag.size()==7,"changed specimen invalidates preview")
	ui.bulk_plan=p.donation_plan(m,0,1);ui.draw(m,660)
	ui.press(m,ui.rects.bulk_confirm.get_center())
	check(ui.reward_open and m.bag.size()==1 and m.bag[0].grade==4,"confirmation consumes exactly shown low-grade fish")
	ui.draw(m,660);ui.press(m,ui.rects.claim.get_center())
	check(ui.just_claimed and ui.reward_open and p.claimed(0,1),"receipt remains visible after payout")
	balance=m.gold;ui.draw(m,660);ui.press(m,Vector2(60,660.0/2+72))
	check(m.gold==balance,"stale receive hitbox cannot pay again")
	# Verify actual rendered list bottom and native touch via the game's input route.
	v.open_shop(m,"aqua");a.act(v,m,"amanage");m.bag=[];m.aqua=[null,null,null]
	for i in 20: m.bag.append(fish(i))
	m.trans={};m.inventory.selected=-1;m.market_open=false;m.settings_open=false;m.lesson_open=false;m.guide.opened=false;m.mailbox.opened=false;m.expedition.opened=""
	v.draw_shop(m,660);a.scroll=a.maximum();v.draw_shop(m,660)
	check(v.rects.rows.any(func(row):return row[1]=="put:19"),"last specimen reachable by scroll")
	a.scroll=0;v.draw_shop(m,660)
	var touch:=InputEventScreenTouch.new();touch.index=0;touch.position=a.viewport.get_center()+Vector2(m.ox,0);touch.pressed=true
	m._unhandled_input(touch)
	var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=touch.position-Vector2(0,90)
	m._unhandled_input(drag);touch.position=drag.position;touch.pressed=false;m._unhandled_input(touch)
	check(a.scroll>0 and m.bag.size()==20,"native drag scrolls without transferring")
	v.draw_shop(m,660)
	var row: Array=v.rects.rows.filter(func(it):return str(it[1]).begins_with("put:"))[0]
	touch.position=row[0].get_center()+Vector2(m.ox,0);touch.pressed=true;m._unhandled_input(touch);touch.pressed=false;m._unhandled_input(touch)
	check(m.aqua_count()==1 and m.bag.size()==19 and v.aqua_manage and v.shop=="aqua","native tap inserts once and leaves UI open")
	m._load_game();check(m.aqua_count()==1 and m.bag.size()==19,"aquarium transfer persists")
	# Owner cap is by stable species, independent of grade/size/stored price.
	m.development_preview=false;m.boat_lv=0;m.aqua_lv=1;m.aqua=[fish(19),null,null,null,null,null]
	m.bag=[fish(19,4),fish(39),fish(59),fish(1),fish(1)]
	var before_bag:Array=m.bag.duplicate(true)
	a.act(v,m,"put:0")
	check(m.bag==before_bag and m.aqua_count()==1 and "1마리" in v.aqua_notice,"same owner grade variant blocked without losing fish")
	a.act(v,m,"put:1");a.act(v,m,"put:1")
	check(m.aqua_count()==3 and m.aqua[1].sp==39 and m.aqua[2].sp==59,"different regional owners coexist")
	a.act(v,m,"put:1");a.act(v,m,"put:1")
	check(m.aqua_count()==5,"ordinary duplicates remain allowed")
	a.act(v,m,"take:0");a.act(v,m,"put:0")
	check(m.aqua[0].sp==19 and m.aqua[0].grade==4,"withdraw then replace owner with better specimen")
	# Legacy duplicate migration preserves exact specimens even above bag capacity.
	var low:Dictionary=fish(59);low.price=500000;low.w=5.0
	var high:Dictionary=fish(59,4);high.price=1500000;high.w=5.0
	var tied:Dictionary=high.duplicate(true);tied.len=99.0
	m.aqua=[low,high,tied,fish(39),fish(19),fish(1)];m.bag=[fish(2)];m.bag[0].w=999.0
	check(is_equal_approx(m.aqua_rate(),(1500000.0+100+100+100)/300*.75),"duplicate owner cannot multiply live income before migration")
	check(m._save_game(),"legacy fixture saved")
	m._load_game()
	check(m.aqua_count()==4 and m.aqua[1]==JSON.parse_string(JSON.stringify(high)) and m.aqua[0]==null and m.aqua[2]==null,"highest owner retained, equal-price first slot wins")
	check(m.bag.size()==3 and m.bag[1]==JSON.parse_string(JSON.stringify(low)) and m.bag[2]==JSON.parse_string(JSON.stringify(tied)) and m.bag_weight()>m.bag_cap(),"legacy extras returned intact despite full bag")
	var saved_bag:Array=m.bag.duplicate(true);var saved_aqua:Array=m.aqua.duplicate(true)
	m._load_game();check(m.bag==saved_bag and m.aqua==saved_aqua,"migration survives restart without repeated returns")
	# Offline credit uses exactly the same one-per-species linked rate.
	var store=load("res://addons/reservoir/save_store.gd")
	var save:Dictionary=store.read("user://save.json");save.aqua=[low,high,tied,fish(39),fish(19),fish(1)];save.bag=[];save.gold=0;save.time=Time.get_unix_time_from_system()-4*3600
	check(store.write("user://save.json",save),"offline duplicate fixture saved")
	m._load_game()
	check(m.gold==int(m.aqua_rate()*180) and m.aqua_count()==4 and m.bag.size()==2,"offline three-hour credit excludes duplicate owner income")
	print("BUNDLE_AQUA_VERIFY failures=",failures)
	m.free();quit(0 if failures.is_empty() else 1)
