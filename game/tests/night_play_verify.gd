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
  check(m.environment.actor_tint().g>.78 and m.environment.actor_tint().b>.90,"actor readable without blanket yellow tint")
  var ground=m.environment.valley if region==1 else m.environment.tile
  check(ground.night_glow.shader_material.get_shader_parameter("lantern_uv").x>0,"lamp mapped into source")
  var center:Vector2=ground.night_glow.shader_material.get_shader_parameter("lantern_uv")
  check((ground.map_rect.position+center*ground.map_rect.size).distance_to(m.night_play.flame(m))<.01,"background emission centered exactly on sprite flame")
  var expected_flame:Vector2=m.night_play.anchor(m)-Vector2(4.5,7)+(Vector2(168.455,166.886)-Vector2(85,0))/Vector2(171,280)*Vector2(9,14)
  check(m.night_play.flame(m).distance_to(expected_flame)<.001,"hotspot follows actual source-to-display transform")
  var span:Vector2=ground.night_glow.shader_material.get_shader_parameter("lantern_span")
  check((span*ground.map_rect.size).is_equal_approx(Vector2(22,17)),"narrow glow instead of chair-sized spotlight")
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
