extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func paint(m) -> void:
	m.text_items=[];m.ui_commands=[];m.inventory.draw(m);m.inventory.detail(m)
func mouse(m,p: Vector2,pressed: bool,device: int=0) -> void:
	var e=InputEventMouseButton.new();e.position=p+Vector2(m.ox,0);e.pressed=pressed;e.button_index=MOUSE_BUTTON_LEFT;e.device=device;m._unhandled_input(e)
func touch(m,p: Vector2,pressed: bool) -> void:
	var e=InputEventScreenTouch.new();e.index=0;e.position=p+Vector2(m.ox,0);e.pressed=pressed;m._unhandled_input(e)
func run() -> void:
	var m=load("res://main.gd").new();m.title_open=false;root.add_child(m);await process_frame;m.set_process(false)
	m.title_open=false;m.trans={};m.scene="village";m.V.shop="";m.settings_open=false;m.market_open=true;m.market_sell=false;m.ui_clock=20;m.inventory.sync(m);m.ui_clock=21
	m.bag=[]
	for i in 20: m.bag.append({"sp":i,"grade":0,"w":0.01,"len":10.0,"price":100,"star":0,"shoulder":false})
	var original: Array=m.bag.duplicate(true)
	for i in 20:
		m.inventory.open_group(i,0);paint(m)
		var p: Vector2=m.inventory.list_view.detail_rects.close.get_center()
		touch(m,p,true)
		# Godot's emulated mouse can arrive both before and after native release.
		mouse(m,p,true,-1);mouse(m,p,false,-1)
		touch(m,p,false);mouse(m,p,true,-1);mouse(m,p,false,-1)
		check(m.inventory.selected==-1,"native close stays closed %d"%i)
		check(m.market_open,"closing detail preserves bag")
		m.inventory.open_group(i,0);paint(m);mouse(m,p,true);mouse(m,p,false)
		check(m.inventory.selected==-1,"mouse close stays closed %d"%i)
	m.inventory.open_species(7);paint(m)
	var stats_close: Vector2=m.inventory.rects.detail_close.get_center()
	touch(m,stats_close,true);touch(m,stats_close,false);mouse(m,stats_close,true,-1);mouse(m,stats_close,false,-1)
	check(m.inventory.selected==-1,"statistics close also blocks click-through")
	# Inventory and equipment share bounded scrolling; dragging must not equip.
	m.equipment.rods=[0,1,2,3,4,5];m.equipment.bags=[0,1,2,3];m.bag_lv=0
	m.parts_owned=["float","hook","line","reel"];m.equipment.active_parts=[]
	for tab in ["inventory","equipment"]:
		m.inventory.tab=tab
		if tab=="equipment":
			# Legacy saves may contain active parts from more than one region.
			for slot in 4: m.parts_owned.append(m.region_shop.part_key(1,slot))
			m.equipment.active_parts=m.parts_owned.duplicate();m.bag_lv=3
		paint(m)
		check(m.equipment.inventory_max_scroll()>0,tab+" overflow fixture")
		var area: Rect2=m.equipment.inventory_viewport
		var old: Dictionary=m.equipment.serialize().duplicate(true)
		var wheel=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN;wheel.pressed=true;wheel.position=area.get_center()+Vector2(m.ox,0)
		m._unhandled_input(wheel)
		check(float(m.equipment.inventory_scroll[tab])==minf(36,m.equipment.inventory_max_scroll()),tab+" wheel scroll/clamp")
		m.equipment.scroll_inventory(100000);paint(m)
		check(float(m.equipment.inventory_scroll[tab])==m.equipment.inventory_max_scroll(),tab+" last row reachable")
		for row in m.equipment.rects.rows: check(area.encloses(row[0]),tab+" hit buttons stay inside viewport")
		m.equipment.scroll_inventory(-100000);paint(m)
		var p: Vector2=area.get_center();touch(m,p,true)
		var drag=InputEventScreenDrag.new();drag.index=0;drag.position=p-Vector2(0,80)+Vector2(m.ox,0);m._unhandled_input(drag)
		touch(m,p-Vector2(0,80),false);mouse(m,p-Vector2(0,80),true,-1);mouse(m,p-Vector2(0,80),false,-1)
		check(m.equipment.serialize()==old,tab+" drag does not equip/unequip")
	check(m.bag==original,"view interactions preserve all fish")
	check(preload("res://addons/reservoir/soul_pouch_shop.gd").icon().atlas.resource_path=="res://art/items/soul_pouch_brown.png","selected original pouch is wired")
	print("BAG_INTERACTION_VERIFY failures=",failures);m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
