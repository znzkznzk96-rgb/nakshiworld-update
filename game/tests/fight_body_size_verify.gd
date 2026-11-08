extends SceneTree
class FishProbe extends "res://main.gd":
 func _fish_effect_rect(_r:Rect2,_c:Color)->void:pass
 func _fish_effect_circle(_p:Vector2,_r:float,_c:Color)->void:pass
var failures: Array=[]
func check(ok:bool,label:String):
 if not ok: failures.append(label)
func _initialize():call_deferred("run")
func run():
 var m=FishProbe.new();m.SET.music=0;m.SET.sfx=0;root.add_child(m);await process_frame;m.set_process(false)
 m.S={"phase":"fight","star":0,"sp":0}
 for sp in 60:
  for lf in [0.75,1.0,1.4,1.65]:
   var base:float=m._fish_display_length(0,m._fight_fish_scale(lf),false,sp)
   var actual:float=m._fight_body_length(sp,lf,0)
   if m.FISH_LEN[sp]*lf<=20:check(is_equal_approx(base,actual),"small unchanged")
   else:check(actual>base or is_equal_approx(base,156.0),"larger physical fish grows")
   check(actual<=156,"bounded")
   check(is_equal_approx(actual,m._fight_body_length(sp,lf,4)),"star does not resize body")
   for face in [-1.0,1.0]:
    m.ui_commands=[];m._shadow_fish(Vector2(135,330),0,0,0,"swim",false,m._fight_fish_scale(lf),{},0,sp,face,1,actual)
    check(is_equal_approx(m.aura.L,actual),"renderer uses explicit length")
    check(m.fish_mouth.distance_to(m.aura.pts[0])<actual*.04,"mouth anchored")
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print("FIGHT_BODY_SIZE_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
