extends SceneTree
var errors: Array=[]
func check(ok: bool,label: String):
 if not ok: errors.append(label);push_error(label)
func _initialize(): call_deferred("run")
func run():
 var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false;m.TUT.done=true;m.trans={};m.lesson_open=false
 var b=m.capture_robot;b.restore({});m.gold=5000;m.development_preview=true
 check(not b.transact(m,"buy") and m.gold==5000 and not b.owned,"purchase failure rollback")
 m.development_preview=false
 check(b.transact(m,"buy") and b.owned and m.gold==4000,"purchase persisted")
 m.pond_stock=.25;b.update(m,1)
 check(is_equal_approx(b.escrow,.25) and m.pond_stock==0 and b.job.is_empty(),"partial recovery protected")
 m.pond_stock=.75;b.update(m,1)
 check(b.job.size()>0 and b.escrow==0 and m.pond_stock==0,"one fish reserved")
 var job=b.job.duplicate(true)
 b.update(m,298);check(b.fish.size()==0,"no early completion")
 b.update(m,1);check(b.fish.size()==1 and b.job.is_empty(),"one completed fish")
 m.bag=[];m.bag_lv=8
 check(b.transact(m,"collect") and b.fish.is_empty() and m.bag.size()==1,"collect once")
 check(b.transact(m,"collect") and m.bag.size()==1,"no double collection")
 check(m.DEX.has(m.fish_key(int(job.sp))),"collection registers dex")
 m.pond_stock=1;b.update(m,1);var snapshot=b.serialize();var restored=load("res://addons/reservoir/capture_robot.gd").new();restored.restore(snapshot)
 check(restored.job==b.job and restored.progress==b.progress,"pending work roundtrip")
 b.transact(m,"toggle");var progress=b.progress;b.update(m,500)
 check(b.progress==progress and not b.job.is_empty(),"OFF preserves job")
 b.transact(m,"toggle");m.development_preview=true;b.update(m,400)
 check(b.fish.is_empty() and not b.job.is_empty() and not b.enabled,"completion save failure rollback pauses")
 m.development_preview=false;b.restore({"owned":true,"enabled":true});m.pond_stock=40
 b.fish=[]
 for i in 20: b.fish.append(job.duplicate())
 b.update(m,1000);check(m.pond_stock==40 and b.job.is_empty(),"full storage reserves nothing")
 b.fish=[job.duplicate()];m.bag_lv=0;m.bag=[job.duplicate()];m.bag[0].w=10
 b.transact(m,"collect");check(b.fish.size()==1,"full player bag retains robot fish")
 b.restore({"owned":true,"enabled":true});m.gold=999999;b.speed=3
 check(not b.transact(m,"speed"),"license gates speed")
 m.progression.certificates[0]=true;m.progression.main_completed[0]=true
 check(b.transact(m,"speed") and b.speed==4,"licensed speed purchase")
 check(b.transact(m,"precision") and b.precision==1,"licensed precision")
 m.active_region=1;m.pond_stock=1;b.update(m,1);var sp: int=b.job.sp;m.active_region=0;b.update(m,1000)
 check(int(b.fish[0].sp)==sp and sp>=20,"location change keeps reserved fish")
 for h in [480,660]:
  m.V.rects.rows=[];b.draw_shop(m,Rect2(8,70,254,h-80),120)
  for row in m.V.rects.rows: check(row[0].end.y<h,"shop fits viewport")
 m.S={"phase":"fight"};m.scene="fish";b.draw_surface(m);check(b.button.size==Vector2.ZERO,"hidden during fight")
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print("CAPTURE_ROBOT_VERIFY failures=",errors)
 quit(0 if errors.is_empty() else 1)
