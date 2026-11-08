extends SceneTree
class Probe extends "res://main.gd":
 func _fish_effect_rect(_r:Rect2,_c:Color)->void:pass
 func _fish_effect_circle(_p:Vector2,_r:float,_c:Color)->void:pass
var failures:Array=[]
func check(ok:bool,label:String):
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 var m=Probe.new();m.SET.music=0;m.SET.sfx=0;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false;m.scene="fish"
 var saved:Dictionary=m.progression.serialize().duplicate(true);var gold:int=m.gold
 for region in [1,2]:
  m.active_region=region;m._layout();m.S={"phase":"idle"};m.environment.set_hour(12);m.ui_commands=[];m.night_play.draw(m)
  check(m.ui_commands.is_empty(),"day has no lamp or particles")
  m.environment.set_hour(0);m.ui_commands=[];m.night_play.draw(m)
  check(m.ui_commands.size()>1,"night lamp and water particles present")
  check(m.environment.actor_tint().r>.8 and m.environment.actor_tint().g>.8,"nearby actor readable in warm light")
  var ground=m.environment.valley if region==1 else m.environment.tile
  check(ground.night_glow.shader_material.get_shader_parameter("lantern_uv").x>0,"lamp mapped into source")
  m.S={"phase":"fight","star":0,"sp":21 if region==1 else 42,"lastF":{"p":Vector2(135,330),"body_length":90}}
  m.environment.update(0);check(ground.night_glow.shader_material.get_shader_parameter("fighting")==1,"fight quiet region enabled")
  m.ui_commands=[];m._shadow_fish(Vector2(135,330),0,0,0,"swim",false,2.2,{},0,m.S.sp,1,1)
  var bodies=m.ui_commands.filter(func(c):return c[0]=="polygon" and c[4]==m.fish_tex[m.S.sp])
  check(not bodies.is_empty() and bodies[-1][2][0]==Color.WHITE,"hooked body retains full original brightness")
 m.active_region=0;m._layout();m.ui_commands=[];m.night_play.draw(m);check(m.ui_commands.is_empty(),"reservoir original lighting preserved")
 seed(1109);var expected:float=randf();seed(1109);m.active_region=1;m.ui_commands=[];m.night_play.draw(m);check(randf()==expected,"particles preserve catch RNG")
 check(m.gold==gold and m.progression.serialize()==saved,"currency and receipts untouched")
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print("NIGHT_PLAY_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
