extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String):
 if not ok:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 var m=load("res://main.gd").new();m.SET.music=0;m.SET.sfx=0;root.add_child(m);await process_frame;m.set_process(false)
 m.title_open=false;m.trans={};m.TUT.done=true;m.scene="spots";m.active_region=0
 var s=m.spots;s.enter();s.index=1;s.scroll=1;s.rects={"enter":Rect2(10,10,100,30),"back":Rect2(10,60,100,30)}
 m.region_shop.unlocked=[0];m.progression.certificates[0]=true;m.progression.main_completed[0]=true
 m.gold=s.PRICES[1]-1;s.press(m,Vector2(20,20))
 check(not s.unlock_fx.active() and not m.region_shop.is_unlocked(1),"insufficient funds do not animate")
 m.gold=s.PRICES[1];m.development_preview=true;s.press(m,Vector2(20,20))
 check(not s.unlock_fx.active() and m.gold==s.PRICES[1] and not m.region_shop.is_unlocked(1),"save failure rolls back and does not animate")
 m.development_preview=false;s.press(m,Vector2(20,20))
 check(s.unlock_fx.active() and m.region_shop.is_unlocked(1) and m.gold==0,"successful saved purchase starts animation once")
 check(m.scene=="spots" and m.active_region==0 and m.trans.is_empty(),"purchase stays on selection screen")
 s.press(m,Vector2(20,20));s.press(m,Vector2(20,70));s.change(1)
 var e:=InputEventMouseButton.new();e.pressed=true
 check(s.input_event(m,e) and s.index==1 and m.gold==0 and m.trans.is_empty(),"animation blocks repeated buy navigation and touch")
 s.process(0.4,m);s.process(0.6,m);check(s.unlock_fx.active(),"animation progresses")
 s.process(3,m);check(not s.unlock_fx.active(),"large timestep completes without sticking")
 m.region_shop.unlocked=[0];m.gold=123;m._load_game()
 check(m.region_shop.is_unlocked(1) and m.gold==0,"unlock and single charge survive actual isolated reload")
 s.enter();check(not s.unlock_fx.active(),"reentry never replays purchase")
 for n in 6:
  s.unlock_fx.start(n)
  for i in 33:
   s.unlock_fx.elapsed=i/10.0
   check(s.unlock_fx.scale_at()>=0.991 and s.unlock_fx.scale_at()<=1.061,"bounded hero zoom")
 s.unlock_fx.reset()
 check(s.images[3].resource_path=="res://art/refresh53/rift.png","original rift selector art preserved")
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print("SPOT_UNLOCK_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
