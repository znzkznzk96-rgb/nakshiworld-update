extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String):
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 var app=load("res://tests/valley_native_root.gd").new();root.add_child(app);await app._start()
 var m=app.box.get_child(0).get_child(0);m.SET.music=0;m.SET.sfx=0;m.set_process(false);m.title_open=false
 var e=m.environment;var saved:Dictionary=m.progression.serialize().duplicate(true)
 var before:float=m.gold
 for region in [0,1,2]:
  m.active_region=region;m._layout();m._switch_scene("fish")
  e.set_hour(12);check(is_zero_approx(e.night_strength()),"noon unchanged")
  check(e.actor_tint()==Color.WHITE,"noon actor preserved")
  for h in [18.0,19.0,20.0,0.0,5.0,6.0,8.0]:
   e.set_hour(h)
   if region in [1,2]:
    var ground=e.valley if region==1 else e.tile
    check(is_equal_approx(float(ground.plate.material.get_shader_parameter("night_strength")),e.night_strength()),"plate follows shared clock")
   if h==0:
    check(e.actor_tint()!=Color.WHITE,"regional actor light")
    var light=e.valley.layers.underwater_light if region==1 else e.tile.light if region==2 else null
    if light!=null:check(is_zero_approx(light.shader_material.get_shader_parameter("light_intensity")),"sun stays off at night")
  e.set_hour(8);check(e.actor_tint()==Color.WHITE,"dawn restores original actor")
 seed(926);var expected:float=randf();seed(926);e.update(.25);check(randf()==expected,"decor clock preserves catch RNG")
 check(m.gold==before and m.progression.serialize()==saved,"no currency or receipt mutations")
 m.audio_feedback.dispose();app.queue_free();await process_frame;await process_frame
 print("REGIONAL_NIGHT_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
