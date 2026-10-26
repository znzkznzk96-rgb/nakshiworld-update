extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
 if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func paint(m) -> void:
 m.text_items=[];m.ui_commands=[];m.inventory.draw(m);m.inventory.detail(m)
func event(m,p: Vector2,down: bool,emulated: bool) -> void:
 var e: InputEvent
 if emulated:
  e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.device=-1
 else:e=InputEventScreenTouch.new();e.index=0
 e.position=p+Vector2(m.ox,0);e.pressed=down;m._unhandled_input(e)
func engine_tap(m,p: Vector2) -> void:
 # Godot 4.4.1 input.cpp dispatches the emulated mouse BEFORE native touch.
 for down in [true,false]:
  event(m,p,down,true);event(m,p,down,false)
func native_engine_tap(p: Vector2) -> void:
 for down in [true,false]:
  var e=InputEventScreenTouch.new();e.index=0;e.position=p;e.pressed=down
  Input.parse_input_event(e);Input.flush_buffered_events()
func run() -> void:
 var m=load("res://main.gd").new();m.development_preview=true;root.add_child(m);await process_frame;m.set_process(false)
 m.title_open=false;m.lesson_open=false;m.trans={};m.scene="village";m.V.shop="";m.market_sell=false;m.bag=[{"sp":0,"grade":0,"w":0.1,"len":10.0,"price":100}]
 m.market_open=true;paint(m);m.ui_clock+=1
 m.inventory.open_group(0,0);paint(m);m.inventory.last_native_touch=-100000
 engine_tap(m,m.inventory.list_view.detail_rects.close.get_center())
 check(m.inventory.selected==-1,"idle then detail close works on first tap")
 check(not m.inventory.pointer,"native up never leaves mouse pointer stuck")
 m.inventory.cancel_pointer();m.inventory.selected=-1;paint(m);m.inventory.last_native_touch=-100000
 engine_tap(m,m.inventory.rects.close.get_center())
 check(not m.market_open,"idle then bag close works on first tap")
 # The native half of the menu opening gesture belongs to the old screen.
 m.market_open=true;m.inventory.displayed=false;m.inventory.cancel_pointer();m.inventory.last_native_touch=-100000
 event(m,Vector2(70,450),true,false);paint(m);event(m,Vector2(70,450),false,false)
 check(m.market_open and m.inventory.selected<0 and not m.inventory.pointer,"menu opening release never selects or closes bag")
 # Repeated idle -> detail -> close uses the same real ordering, without clocks/timeouts.
 for i in 100:
  m.inventory.selected=-1;m.inventory.cancel_pointer();paint(m);m.inventory.last_native_touch=-100000
  engine_tap(m,m.inventory.list_view.rows[0].rect.get_center());paint(m)
  check(m.inventory.selected==0,"fish opens after idle %d"%i)
  m.inventory.last_native_touch=-100000;engine_tap(m,m.inventory.list_view.detail_rects.close.get_center())
  check(m.inventory.selected==-1 and not m.inventory.pointer,"close after idle %d"%i)
 Input.emulate_mouse_from_touch=true;Input.use_accumulated_input=false
 for i in 10:
  m.inventory.selected=-1;m.inventory.cancel_pointer();paint(m);m.inventory.last_native_touch=-100000
  native_engine_tap(m.inventory.list_view.rows[0].rect.get_center()+Vector2(m.ox,0));paint(m)
  check(m.inventory.selected==0,"real engine selects fish %d"%i)
  m.inventory.last_native_touch=-100000;native_engine_tap(m.inventory.list_view.detail_rects.close.get_center()+Vector2(m.ox,0))
  check(m.inventory.selected==-1 and not m.inventory.pointer,"real engine closes detail %d"%i)
 print("BAG_EVENT_ORDER_VERIFY failures=",failures);m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
