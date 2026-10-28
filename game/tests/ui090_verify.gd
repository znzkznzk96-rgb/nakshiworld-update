extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
 if not ok: failures.append(label);push_error(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var m=load("res://main.gd").new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false
 var v=m.expedition;v.data.restore({});v.data.souls=[100,100,100,100,100]
 for i in 60:v.data.add_unit(i%15,1,[4,5,6])
 var original=v.data.serialize().duplicate(true)
 for h in [480,660]:
  v.open(m,"alchemy");v.tab=0;v.pair=[4,4];v.draw(m,h)
  check(v.panel_bounds.end.y<=h-40,"alchemy bottom breathing room")
  check(v.rects.craft.position.y-float(v.flow_layout.owned_y)<=65,"craft immediately below owned souls")
  for category in [1,2]:
   v.tab=category;v.roster_scroll=0;v.draw(m,h)
   var point: Vector2=v.roster_viewport.get_center()+Vector2(m.ox,0)
   var wheel=InputEventMouseButton.new();wheel.position=point;wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN;wheel.pressed=true;v.roster_native_until=0;v.input_event(m,wheel)
   check(v.roster_scroll==56,"wheel moves one roster row")
   for i in 100:v.input_event(m,wheel)
   v.draw(m,h)
   check(v.rects.has("select:%d"%int(v.data.soldiers[-1].uid)),"last soldier reachable with wheel")
   v.roster_scroll=0;v.draw(m,h)
   var press=InputEventScreenTouch.new();press.position=point;press.index=0;press.pressed=true;v.input_event(m,press)
   var drag=InputEventScreenDrag.new();drag.position=point-Vector2(0,90);drag.index=0;v.input_event(m,drag)
   press.position=drag.position;press.pressed=false;v.input_event(m,press)
   check(v.roster_scroll>0 and v.selected.is_empty(),"touch drag scrolls without selecting")
   check(v.panel_bounds.end.y<=h-40,"roster bottom breathing room")
 check(original==v.data.serialize(),"scroll and layout leave game data unchanged")
 v=null;m.audio_feedback.dispose();m.queue_free();await process_frame
 print("UI090_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
