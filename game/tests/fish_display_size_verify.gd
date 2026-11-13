extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String):
 if not ok and label not in failures:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 var cases:=0
 var box:=Rect2(39,100,192,62)
 for sp in 80:
  var source:Vector2=m.rift_art.source_rect(sp,0).size if m.rift_art.has_species(sp) else Vector2(m.fish_used[sp].size)
  var previous:=Vector2.ZERO
  for ratio in [0.5,0.75,1.0,1.35,1.65]:
   var r:Rect2=m._result_fish_rect(sp,float(m.FISH_LEN[sp])*ratio,box)
   check(r.size.x>0 and r.size.y>0,"positive result size")
   check(box.encloses(r) and r.get_center().distance_to(box.get_center())<.001,"result centered and bounded")
   check(r.size.x/source.x<=2.0001 and r.size.y/source.y<=2.0001,"no source enlarged beyond2x")
   check(absf(r.size.x/r.size.y-source.x/source.y)<.001,"original aspect preserved")
   check(r.size.x>=previous.x-.001 and r.size.y>=previous.y-.001,"larger individual never drawn smaller")
   m.ui_commands=[];var actual:Rect2=m._ui_fish(sp,r)
   check(actual.size.distance_to(r.size)<.001,"actual result painter uses requested dimensions")
   previous=r.size;cases+=1
 for sp in [2,19,60,75]:print("SIZE_SAMPLE sp=",sp," mean_cm=",m.FISH_LEN[sp]," result=",m._result_fish_rect(sp,m.FISH_LEN[sp],box).size)
 check(m._result_fish_rect(19,m.FISH_LEN[19],box).size.length()>m._result_fish_rect(2,m.FISH_LEN[2],box).size.length(),"large catch reads larger than small catch")
 for i in 4:check(m._bite_preview_length(i)>=[36,42,48,54][i],"readable bite class minimum")
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print("FISH_DISPLAY_SIZE_VERIFY failures=",failures," cases=",cases);quit(0 if failures.is_empty() else 1)
