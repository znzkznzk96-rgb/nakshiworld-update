extends SceneTree
var failures=[]
func check(ok,label):
 if not ok:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 m.title_open=false;m.trans={};m.progression.restore({});m.region_shop.restore({});m.gold=10000
 check(m.progression.available_regions==[0,1],"only completed regions enabled")
 check(not m.region_shop.unlock(m,1) and m.gold==10000,"no certificate no charge")
 m.progression.restore({"main_completed":[true],"certificates":[true]})
 m.development_preview=true
 check(not m.region_shop.unlock(m,1) and m.gold==10000 and not m.region_shop.is_unlocked(1),"failed persistence rolls back charge and flag")
 m.development_preview=false;m.gold=6599
 check(not m.region_shop.unlock(m,1) and m.gold==6599,"insufficient funds no partial payment")
 m.gold=6600;m.scene="spots";m.spots.index=1;m.spots.rects.enter=Rect2(20,200,200,30)
 m.spots.press(m,Vector2(100,215))
 check(m.active_region==1 and m.region_shop.is_unlocked(1) and m.gold==0 and m.trans.get("to","")=="fish","real selection opens licensed valley for exact price")
 m._switch_scene("fish");m.trans={};m.active_region=0;m.region_shop.restore({});m.progression.restore({});m._load_game()
 check(m.active_region==1 and m.region_shop.is_unlocked(1) and m.progression.licensed(1),"old license and new unlock survive save reload")
 check(m.region_shop.unlock(m,1) and m.gold==0,"repeat entry free")
 m.gold=999999999;m.progression.main_completed[1]=true;m.progression.certificates[1]=true
 check(not m.region_shop.unlock(m,2),"unfinished tile sea remains locked even licensed")
 check(m.environment.valley.root.get_parent()==m and m.environment.valley.root.z_index<0,"background stays behind actors in world canvas")
 for h in [480,660]:
  m.text_items=[];m.ui_commands=[];m.spots.scroll=1;m.spots.draw(m,h)
  check(not m.spots.rects.enter.intersects(m.spots.rects.back),"unlock and back never overlap")
 m.environment.show_scene(true);check(m.environment.valley.root.visible,"approved valley scene visible")
 m.equipment.active_parts=[];m.TUT.done=true;m.lesson_open=false;m.S={"phase":"idle"}
 for i in 20:
  m.start_wait();check(int(m.S.sp)>=20 and int(m.S.sp)<40,"valley encounters use valley catalog")
 m.audio_feedback.dispose();m.queue_free();await process_frame;print("VALLEY093 failures=",failures);quit(0 if failures.is_empty() else 1)
