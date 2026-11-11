extends SceneTree
class Probe extends "res://main.gd":
 func _fish_effect_rect(_r:Rect2,_c:Color)->void:pass
 func _fish_effect_circle(_p:Vector2,_r:float,_c:Color)->void:pass
func _initialize():call_deferred("run")
func run():
 var m=Probe.new();m.text_layer=Node2D.new();m.text_layer.set_script(load("res://text_layer.gd"));root.add_child(m.text_layer);m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.development_preview=true
 m.start_wait();m.S.sp=19;m.S.len=m.FISH_LEN[19];m.start_fight();m.S.tut=false;m.S.lesson="";m.S.beh="tell";m.S.bt=.5;m.S.lf=1.0;m.S.pose={};m.clock=15;m.fight_telegraph.note_behavior(m)
 var length=156.0;var c=Vector2(135,340);var hud=m._fish_tension_position(c,1,0,length);m.aura_cue_context={"center":c,"group":false,"hud":hud}
 for grade in [1,2,3,4]:
  var times=[]
  for frame in 12:
   m.ui_commands=[]
   var at=Time.get_ticks_usec()
   m._shadow_fish(c,m.S.star,grade,15000+frame*16,"tell",false,2.2,{},1.2,19,1.0,1.0,length)
   times.append((Time.get_ticks_usec()-at)/1000.0)
  print("AURA_CPU grade=",grade," mean_ms=",times.reduce(func(a,b):return a+b)/times.size()," max_ms=",times.max()," vertices=",m.fish_grade_aura.points.size())
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit()
