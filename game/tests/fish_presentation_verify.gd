extends SceneTree
class FishProbe extends "res://main.gd":
 func _fish_effect_rect(_r:Rect2,_c:Color)->void:pass
 func _fish_effect_circle(_p:Vector2,_r:float,_c:Color)->void:pass
var failures: Array=[]
func check(ok:bool,label:String):
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 var m=FishProbe.new();m.SET.music=0;m.SET.sfx=0;root.add_child(m);await process_frame;m.set_process(false)
 for sp in 60:
  m.ui_commands=[];var r:Rect2=m._ui_fish(sp,Rect2(10,10,100,50));var cmd:Array=m.ui_commands[-1]
  if sp>=40:
   check(cmd[0]=="polygon" and cmd[3][0].x>cmd[3][1].x,"tile static faces right")
  else:check(cmd[0]=="region","preserve historical non-tile orientation")
  var base:float=clampf((6.0+3.0*sqrt(float(m.FISH_LEN[sp])))*2.2,18,120)
  var actual:float=m._fish_display_length(0,2.2,false,sp)
  if m.FISH_LEN[sp]<=50:check(is_equal_approx(base,actual),"small fish v109 size unchanged")
  else:check(actual>base and actual<=156,"only large fish bigger and bounded")
  check(is_equal_approx(m._fish_display_length(0,1,true,sp),clampf(6+3*sqrt(float(m.FISH_LEN[sp])),12,80)),"generic display helper unchanged")
  for z in 4:
   for timing in ["approach","contact","hook"]:
    m.clock=9.0 if timing=="approach" else 10.05
    m.S={"phase":"hook" if timing=="hook" else "wait","sp":sp,"star":int(sp%5),"size":z,"biteAt":10.0,"fakes":[]}
    m.ui_commands=[];m._draw_bite_shadow(10000,150,0)
    check(is_equal_approx(m.aura.L,float([28,30,32,34][z])),"actual bobber renderer gets normalized body length")
    check(m.aura.L>=28 and m.aura.L<=34,"all species readable and similarly sized before fight")
 check(m._bite_preview_length(-1)==28 and m._bite_preview_length(9)==34,"preview class safely bounded")
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print("FISH_PRESENTATION_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
