extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func fish(sp: int, value: int=100, grade: int=0) -> Dictionary:
	var star:=0
	for i in 5:
		if sp%20 in preload("res://addons/reservoir/regional_catalog.gd").BY_STAR[i]: star=i
	return {"sp":sp,"star":star,"grade":grade,"len":23.5,"w":0.1,"price":value,"shoulder":false}
func run() -> void:
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;m.title_open=false;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false;m.scene="village";m.S={"phase":"idle"}
	m.progression.restore({});m.buyback.restore({});m.bag=[];m.aqua=[null,null,null];m.gold=10000;m.souls=0;m.pearl=0
	var p=m.progression
	for area in 2:
		check(p.bundle_targets(area,0).size()==6 and p.bundle_targets(area,1).size()==6,"six species per main and sub")
		for sp in p.MAIN_SPECIES[area]: check(sp not in p.SUB_SPECIES[area],"main/sub do not overlap")
		var main_gold: int=m.gold
		# Side bundle can complete first; mixed individual grades/prices are valued exactly.
		for i in 6:
			m.bag=[fish(p.SUB_SPECIES[area][i],100+i*10,i%5)]
			check(p.donate_bundle(m,area,1,0,i),"incremental side donation")
			check(m.bag.is_empty(),"only actual submitted specimen is consumed")
			if i==2:
				m._save_game();p.restore({});m._load_game()
				check(p.bundle_counts(area,1)[2]==1,"partial side progress survives restart")
		check(m.gold==main_gold+900 and m.souls==(15 if area==0 else 45),"side rewards actual 750 sale value times120% and correct souls")
		check(not p.main_completed[area],"side completion needs no main completion")
		m.bag=[fish(p.SUB_SPECIES[area][0])]
		check(not p.donate_bundle(m,area,1,0,0) and m.bag.size()==1,"repeat side cannot consume or pay again")
		main_gold=m.gold
		m.bag=[fish(20 if area==0 else 5)]
		check(not p.donate_bundle(m,area,0,0,0),"wrong regional species rejected")
		for i in 6:
			m.bag=[fish(p.MAIN_SPECIES[area][i])]
			check(p.donate_bundle(m,area,0,0,i),"main incremental donation accepts normal")
		check(m.gold==main_gold and p.certificates[area],"main pays certificate only")
		check(not p.donate_bundle(m,area,0,0,0),"main completion immutable")
		var prior_pearl: int=m.pearl
		m.bag=[fish(area*20+19,1001,4)]
		check(p.donate_bundle(m,area,2,0,0),"owner accepts any grade")
		check(m.gold==main_gold+1502 and m.pearl==prior_pearl+2,"owner 150% nearest integer plus two pearls")
		m._save_game();p.restore({});m._load_game()
		check(p.bundle_done(area,2) and p.bundle_done(area,1) and p.bundle_done(area,0),"all completed flags persist")
		m.bag=[fish(area*20+19)]
		check(not p.donate_bundle(m,area,2,0,0),"owner duplicate reward blocked after reload")
	# Real sale entry points, retention, exact specimen, price and modal behavior.
	m.buyback.restore({});m.bag=[]
	for i in 12: m.bag.append(fish(i,101+i,i%5))
	m.sell_all()
	check(m.bag.is_empty() and m.buyback.entries.size()==10,"bulk sale retained only ten specimens")
	check(m.buyback.entries[0].fish.sp==11 and m.buyback.entries[9].fish.sp==2,"latest sold ordering")
	var e: Dictionary=m.buyback.entries[0].duplicate(true)
	check(m.buyback.price(e)==135,"buyback 112 sale costs135 (round up)")
	var c=m.V.commerce;var gold: int=m.gold
	check(c.request(m.V,m,"buyback:%d"%int(e.id)),"reuse existing commerce confirmation")
	c.pending={};check(m.gold==gold and m.bag.is_empty(),"cancel changes no balances or fish")
	c.request(m.V,m,"buyback:%d"%int(e.id));m.gold=0
	check(not c.confirm(m.V,m) and m.buyback.entries.size()==10,"insufficient funds preserve listing")
	m.gold=gold
	check(c.confirm(m.V,m),"confirmed repurchase succeeds")
	check(m.gold==gold-135 and m.bag[0]==e.fish and m.buyback.entries.size()==9,"exact sold specimen restored and listing consumed")
	check(not c.confirm(m.V,m),"double confirmation cannot duplicate fish")
	# Modal has stable identity even when the ten-entry limit evicts its item.
	var oldest: Dictionary=m.buyback.entries.back();c.request(m.V,m,"buyback:%d"%int(oldest.id))
	for i in 10: m.buyback.remember(fish(i))
	gold=m.gold
	check(not c.confirm(m.V,m) and m.gold==gold,"stale confirmation cannot buy another row")
	m.bag=[fish(3,777,2)];m.V._act(m,"sell:0")
	check(m.buyback.entries[0].sold_price==777 and m.bag.is_empty(),"individual market sale remembers actual specimen")
	m._save_game();var saved: Dictionary=m.buyback.serialize();m.buyback.restore({});m._load_game()
	check(m.buyback.serialize()==JSON.parse_string(JSON.stringify(saved)),"buyback saved with wallet and bag")
	m.V.open_shop(m,"work");m.V.tab="buyback";m.text_items=[];m.ui_commands=[];m.V.draw_shop(m,660)
	check(m.buyback.max_scroll()>0,"ten rows require vertical scroll")
	var wheel:=InputEventMouseButton.new();wheel.position=m.buyback.viewport.get_center()+Vector2(m.ox,0);wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN;wheel.pressed=true
	check(m.buyback.input_event(m,wheel) and m.buyback.scroll>0,"mouse wheel scroll works")
	var down:=InputEventMouseButton.new();down.position=wheel.position;down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true
	m.buyback.input_event(m,down)
	var motion:=InputEventMouseMotion.new();motion.position=down.position-Vector2(0,100);m.buyback.input_event(m,motion)
	check(m.buyback.dragged and m.buyback.scroll>36,"emulated touch mouse drag scrolls")
	down.pressed=false;down.position=motion.position;m.buyback.input_event(m,down)
	check(c.pending.is_empty(),"drag release does not purchase")
	m.buyback.scroll=m.buyback.max_scroll();m.text_items=[];m.ui_commands=[];m.V.draw_shop(m,660)
	var oldest_id: int=m.buyback.entries.back().id
	check(m.V.rects.rows.any(func(row):return row[1]=="buyback:%d"%oldest_id),"oldest tenth item reachable by scrolling")
	# Backward-compatible saves initialize empty new fields, keeping original money and bag.
	p.restore({"owner_gauge":[44]});m.buyback.restore({})
	check(p.owner_gauge[0]==44 and not p.bundle_done(0,1) and m.buyback.entries.is_empty(),"old save initializes new fields without invented history")
	check(p.available_regions==[0] and p.owner_rules.is_empty(),"unapproved valley entry and owner gain stay disabled")
	print("BUNDLES_BUYBACK_VERIFY failures=",failures)
	m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
