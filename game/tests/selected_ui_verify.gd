extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func touch(m,p: Vector2,pressed: bool,index: int=0,canceled: bool=false) -> void:
	var e=InputEventScreenTouch.new();e.position=p+Vector2(m.ox,0);e.pressed=pressed;e.index=index;e.canceled=canceled;m._unhandled_input(e)
func paint(m) -> void:
	m.text_items=[];m.ui_commands=[];m.inventory.draw(m)
func run() -> void:
	var m=load("res://main.gd").new();m.development_preview=true;m.SET.music=0;m.SET.sfx=0;root.add_child(m);await process_frame;m.set_process(false)
	m.title_open=false;m.lesson_open=false;m.trans={};m.scene="village";m.V.shop="";m.market_open=true;m.market_sell=false;m.inventory.sync(m);m.ui_clock+=1
	m.bag=[]
	for i in 100: m.bag.append({"sp":i%20,"grade":i/20,"w":0.1,"len":10.0,"price":100})
	paint(m)
	var close: Vector2=m.inventory.rects.close.get_center()
	# A cancelled release must never activate the control under the finger.
	touch(m,close,true);touch(m,close,false,0,true)
	check(m.market_open and not m.inventory.pointer,"cancel clears gesture without closing")
	# Lost release with a different subsequent touch ID previously trapped all taps.
	touch(m,close,true,0);m.inventory.pointer_started-=3000
	touch(m,close,true,1);touch(m,close,false,1)
	check(not m.market_open,"tap recovers after stale Android gesture")
	m.market_open=true;m.inventory.sync(m);m.ui_clock+=1;paint(m)
	touch(m,close,true);m._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not m.inventory.pointer,"focus loss clears retained pointer")
	var count: int=m.inventory.list_view.regroup_count
	for i in 600: paint(m)
	check(m.inventory.list_view.regroup_count==count,"unchanged bag does not regroup for 600 frames")
	m.bag[0].w=0.2;paint(m)
	check(m.inventory.list_view.regroup_count==count+1,"in-place specimen change invalidates cache")
	m.market_open=false
	var v=m.expedition;var d=v.data;d.restore({});d.souls=[100,100,100,100,100];m.gold=100000
	for id in [5,6,7,4,14]:d.add_unit(id,1,[3,4,5])
	d.team=[3,2,4];var before: Dictionary=d.serialize().duplicate(true)
	for height in [480,660]:
		v.training_uid=5;m.text_items=[];m.ui_commands=[];v.rects={};v.draw_training(m,108,height-8)
		for row in v.training_rows: check(row.next-row.current==row.delta,"exact increase "+row.key)
		check(v.rects.train.end.y<v.rects.training_back.position.y-30,"raised upgrade action %d"%height)
		v.rects={};v.role_filter="all";v.draw_formation(m,139,height-8)
		check(v.role_badges[0].role=="support","front slot shows actual support role")
		for r in v.rects.values():check(r.end.y<=height,"formation bounds")
		v.rects={};v.role_filter="defense";v.draw_formation(m,139,height-8)
		check(v.rects.has("formation_unit:5") and not v.rects.has("formation_unit:1"),"role filter isolates defenders")
	check(d.serialize()==before,"UI rendering preserves all soldier state")
	print("SELECTED_UI_VERIFY failures=",failures);m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
