extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func specimen(sp: int,grade: int,w: float) -> Dictionary:
	return {"sp":sp,"star":0,"grade":grade,"w":w,"len":12.5+w*10,"price":100+grade*10,"shoulder":false}
func paint(m) -> void:
	m.text_items=[];m.ui_commands=[];m.inventory.draw(m)
func run() -> void:
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;m.title_open=false;root.add_child(m);await process_frame;m.set_process(false)
	m.title_open=false;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.settings_open=false;m.equipment.pending_sale={};m.V.commerce.pending={}
	m.bag=[specimen(7,0,0.022),specimen(7,0,0.026),specimen(7,1,0.031)]
	for i in range(1,20): m.bag.append(specimen(i,i%5,0.01))
	var before: Array=m.bag.duplicate(true)
	m.market_open=true;m.market_sell=false;m.inventory.tab="fish";m.ui_clock=20;m.inventory.sync(m);m.ui_clock=21
	var view=m.inventory.list_view
	paint(m)
	var initial: Array=view.groups_cache.duplicate(true)
	check(initial[0].indices==[0,1] and initial[1].grade==1,"species+grade grouping preserves original specimens")
	check(view.max_scroll()>0 and view.rows.size()>=5,"list virtualizes long inventory")
	for item in view.image_bounds:
		check(item.image.position.x>=item.row.position.x+12 and item.image.end.x<=item.row.end.x-12,"fish image fully inset from row border")
	for item in view.badge_bounds:
		check(item.text_center.x==item.rect.get_center().x,"grade label horizontally centered")
		check(item.text_center.y>item.rect.position.y and item.text_center.y<item.rect.end.y,"grade baseline inside badge")
	var wheel:=InputEventMouseButton.new();wheel.position=view.viewport.get_center()+Vector2(m.ox,0);wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN;wheel.pressed=true
	m._unhandled_input(wheel);check(view.scroll==50,"wheel routed through main input")
	view.scroll=view.max_scroll();paint(m)
	var last: Dictionary=view.groups_cache.back()
	check(view.rows.any(func(row):return row.sp==last.sp and row.grade==last.grade),"last grouped row is reachable")
	# Dragging must not accidentally open the row underneath the release.
	view.scroll=0;paint(m)
	var down:=InputEventMouseButton.new();down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;down.position=view.viewport.get_center()+Vector2(m.ox,0)
	m._unhandled_input(down)
	var move:=InputEventMouseMotion.new();move.position=down.position-Vector2(0,80);m._unhandled_input(move)
	down.pressed=false;down.position=move.position;m._unhandled_input(down)
	check(view.scroll>0 and m.inventory.selected<0,"mouse drag scrolls without selection")
	# Native Android touch path, independent of emulated mouse events.
	view.scroll=0;paint(m)
	var touch:=InputEventScreenTouch.new();touch.index=0;touch.position=view.viewport.get_center()+Vector2(m.ox,0);touch.pressed=true;m._unhandled_input(touch)
	var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=touch.position-Vector2(0,90);m._unhandled_input(drag)
	touch.pressed=false;touch.position=drag.position;m._unhandled_input(touch)
	check(view.scroll>0 and m.inventory.selected<0,"native touch drag scrolls without selecting")
	view.scroll=0;paint(m)
	var row: Dictionary=view.rows[0]
	m.inventory.press(m,row.rect.get_center())
	check(m.inventory.selected==7 and m.inventory.selected_grade==0,"tap opens selected grade instead of all grades")
	m.inventory.detail(m)
	check(view.detail_indices==[0,1],"individual weight/length details remain separate")
	check(m.text_items.any(func(it):return "22g" in str(it[2])) and m.text_items.any(func(it):return "26g" in str(it[2])),"both individual weights displayed")
	m.inventory.detail_press(view.detail_rects.stats.get_center())
	check(m.inventory.selected_grade==-1 and m.inventory.selected==7,"legacy species statistics remain available")
	m.inventory.detail(m);m.inventory.detail_press(m.inventory.rects.detail_close.get_center())
	check(m.inventory.selected==-1,"old statistics close normally")
	paint(m);m.inventory.press(m,m.inventory.tab_rects.inventory.get_center());paint(m)
	check(m.inventory.tab=="inventory","existing inventory tab preserved")
	m.inventory.press(m,m.inventory.tab_rects.equipment.get_center());paint(m)
	check(m.inventory.tab=="equipment","equipment tab preserved")
	m.inventory.press(m,m.inventory.tab_rects.fish.get_center());paint(m)
	check(m.inventory.tab=="fish" and view.groups_cache.size()==initial.size(),"return from other tabs keeps all groups")
	check(m.bag==before,"all scrolling grouping and inspection is view-only")
	m.bag=[];paint(m);check(view.scroll==0 and view.rows.is_empty(),"empty bag resets scrollbar safely")
	print("BAG_LIST_VERIFY failures=",failures)
	m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
