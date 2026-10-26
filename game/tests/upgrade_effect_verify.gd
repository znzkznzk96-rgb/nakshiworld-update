extends SceneTree
var failures: Array=[]
var checks: int=0
class FailedSaveHost extends RefCounted:
 var gold: int=10000
 func _save_game() -> bool: return false
 func show_toast(_text,_color) -> void: pass
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok: failures.append(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 m.SET.sfx=0;m.SET.music=0;m.title_open=false;m.TUT.done=true
 var v=m.expedition;var d=v.data;d.restore({});d.souls=[50,50,50,50,50];m.gold=10000
 v.open(m,"alchemy");v.pair=[2,4];v.rects={"craft":Rect2(0,0,20,20)}
 v.press(m,Vector2(10,10));check(v.effect_kind=="alchemy","craft effect starts")
 check(v.effect_pair==[2,4],"selected elements retained")
 var uid: int=int(d.pending.uid);var n: int=d.soldiers.size();var souls=d.souls.duplicate()
 v.press(m,Vector2(10,10));check(d.soldiers.size()==n and d.souls==souls,"double craft blocked")
 var disk: Dictionary=load("res://addons/reservoir/save_store.gd").read("user://save.json")
 check(int(disk.expedition.pending.uid)==uid,"craft is on disk before effect completes")
 var reload=load("res://addons/expedition/model.gd").new();reload.restore(d.serialize())
 check(reload.pending.uid==uid and not reload.unit(uid).is_empty(),"result persists independently of effect")
 v.rects={"close":Rect2(0,0,20,20)};v.press(m,Vector2(10,10));check(v.effect_kind=="" and not d.pending.is_empty(),"close preserves craft result")
 d.pending={};v.opened="training";v.training_uid=uid;v.rects={"train":Rect2(0,0,20,20)}
 v.press(m,Vector2(10,10));check(v.effect_kind=="soldier" and int(d.unit(uid).level)==1,"training effect follows upgrade")
 disk=load("res://addons/reservoir/save_store.gd").read("user://save.json")
 check(int(disk.gold)==m.gold and int(disk.expedition.soldiers[0].level)==1,"training is on disk before effect completes")
 var gold: int=m.gold;v.press(m,Vector2(10,10));check(m.gold==gold and int(d.unit(uid).level)==1,"double train blocked")
 v.update(m,2.1);check(v.effect_kind=="" and int(d.unit(uid).level)==1,"effect ends without reapplying upgrade")
 for kind in ["alchemy","soldier"]:check(v.textures["fx_"+kind].get_size()==Vector2(1664,128),"effect atlas loaded "+kind)
 check(m.V.enhancement.animation.rod_sheet.get_size()==Vector2(2496,112),"rod atlas loaded")
 var host=FailedSaveHost.new();var other=load("res://addons/expedition/view.gd").new();other.data.restore({});other.data.souls=[10,10,10,10,10]
 other.rects={"craft":Rect2(0,0,20,20)};other.press(host,Vector2(10,10))
 check(other.data.soldiers.is_empty() and other.data.souls==[10,10,10,10,10] and other.effect_kind=="","craft rolls back failed save")
 var unit=other.data.add_unit(0);other.training_uid=int(unit.uid);other.rects={"train":Rect2(0,0,20,20)};other.press(host,Vector2(10,10))
 check(int(other.data.unit(unit.uid).level)==0 and host.gold==10000 and other.effect_kind=="","training rolls back failed save")
 for i in 10:
  check(v.textures.has("room%d"%i),"room asset loaded %d"%(i+1))
  if v.textures.has("room%d"%i):check(v.textures["room%d"%i].get_size()==Vector2(768,192),"native panorama size %d"%(i+1))
 for size in [Vector2(246,48),Vector2(224,88),Vector2(236,85)]:
  var a: Rect2=v.room_window(Vector2(768,192),size,0);var b: Rect2=v.room_window(Vector2(768,192),size,1)
  check(is_equal_approx(a.size.x/a.size.y,size.x/size.y),"pan preserves aspect")
  check(a.position.x==0 and b.position.x>0 and b.end.x<=769 and b.end.y<=192,"pan remains inside native image")
 m.audio_feedback.dispose();m.queue_free();await process_frame;await process_frame
 print("UPGRADE_EFFECT checks=",checks)
 print("UPGRADE_EFFECT_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
