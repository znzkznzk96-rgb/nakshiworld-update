extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
 if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func paint(m) -> void:
 m.text_items=[];m.ui_commands=[];m.inventory.draw(m)
func tap(m,p: Vector2) -> void:
 for down in [true,false]:
  var e=InputEventScreenTouch.new();e.position=p+Vector2(m.ox,0);e.pressed=down;m._unhandled_input(e)
func run() -> void:
 var m=load("res://main.gd").new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 m.title_open=false;m.lesson_open=false;m.trans={};m.scene="village";m.V.shop="";m.market_sell=false;m.bag=[]
 for i in 180: m.bag.append({"sp":i%17,"grade":0,"w":0.1,"len":10.0,"price":100})
 m.market_open=true;paint(m)
 var texts: Array=m.text_items.duplicate(true)
 tap(m,m.inventory.list_view.rows[0].rect.get_center())
 check(m.inventory.selected>=0,"fish opens immediately without clock advance")
 m.inventory.detail(m);tap(m,m.inventory.list_view.detail_rects.close.get_center())
 check(m.inventory.selected<0 and m.market_open,"detail closes immediately")
 paint(m);tap(m,m.inventory.rects.close.get_center());check(not m.market_open,"bag closes immediately")
 m.market_open=true;paint(m)
 var first: Array=m.text_items.duplicate(true);m.ui_clock+=0.12;paint(m)
 check(first==m.text_items,"no opening text rescale or opacity animation")
 m.market_open=false
 var v=m.expedition;var d=v.data;d.restore({})
 for role in v.ROLES:check(v.textures["role_"+role]!=null and v.textures["role_"+role].get_size()==Vector2(32,32),"PixelLab role texture "+role)
 for i in 25: d.add_unit([5,14,6][i%3],1,[0,0,0])
 d.team=[1,2,3];v.open(m,"explore");v.explore_tab=1
 for height in [480,660]:
  v.rects={};v.formation_scroll=0;v.role_filter="all";v.draw_formation(m,139,height-8)
  check(v.rects["slot:2"].position.x<v.rects["slot:1"].position.x and v.rects["slot:1"].position.x<v.rects["slot:0"].position.x,"rear middle front order")
  check(d.team==[1,2,3],"display preserves combat order")
  check(not v.rects.has("prev") and v.formation_max_scroll>0,"scroll replaces pagination")
  var wheel=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN;wheel.pressed=true;wheel.position=v.formation_viewport.get_center()+Vector2(m.ox,0)
  v.formation_input(m,wheel);check(v.formation_scroll>0,"wheel scrolls")
  v.formation_begin(v.formation_viewport.get_center(),0);v.formation_move(v.formation_viewport.get_center()-Vector2(0,80));v.formation_release(m,v.formation_viewport.get_center()-Vector2(0,80))
  check(d.team==[1,2,3],"drag does not equip or remove")
  v.formation_scroll=99999;v.rects={};v.draw_formation(m,139,height-8)
  check(v.rects.has("formation_unit:25"),"last soldier reachable")
  v.press(m,v.rects["role_filter:defense"].get_center());check(v.formation_scroll==0,"filter resets scroll")
  v.rects={};v.draw_formation(m,139,height-8)
  for key in v.rects:
   if key.begins_with("formation_unit:"):check(d.catalog.soldiers[int(d.unit(int(key.split(":")[1])).id)].role=="defense","filter correct")
 # Direct card removal, overlap priority, touch/drag and running lock.
 for slot in [0,1,2]:
  d.team=[1,2,3];d.battle={};v.role_filter="all";v.rects={};v.draw_formation(m,139,472)
  var p: Vector2=v.rects["clear_slot:%d"%slot].get_center()
  v.formation_begin(p,0);v.formation_release(m,p)
  var expected: Array=[1,2,3];expected.remove_at(slot)
  check(d.team==expected,"card removes correct slot %d"%slot)
  check(d.soldiers.size()==25,"removal preserves owned soldiers")
 d.team=[1,2,3];v.rects={};v.draw_formation(m,139,472)
 var clear_pos: Vector2=v.rects["clear_slot:0"].get_center()
 v.formation_begin(clear_pos,0);v.formation_move(clear_pos+Vector2(0,12));v.formation_release(m,clear_pos+Vector2(0,12))
 check(d.team==[1,2,3],"drag from remove does not remove or swap")
 d.start(1,1000);v.press(m,clear_pos)
 check(d.team==[1,2,3],"active expedition removal blocked")
 print("BAG_FORMATION_VERIFY failures=",failures);m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
