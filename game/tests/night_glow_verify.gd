extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String):
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 var app=load("res://tests/valley_native_root.gd").new();root.add_child(app);app._start()
 var m=app.box.get_child(0).get_child(0);m.SET.music=0;m.SET.sfx=0;m.set_process(false);m.title_open=false
 var e=m.environment
 var glows=[e.valley.night_glow,e.tile.night_glow]
 for region in [1,2]:
  m.active_region=region;m._layout();m._switch_scene("fish");var glow=glows[region-1]
  check(glow.get_parent()==(e.valley.plate if region==1 else e.tile.plate),"source coordinates inherit cover mapping")
  check(glow.field.mouse_filter==Control.MOUSE_FILTER_IGNORE,"glow cannot block fishing input")
  e.set_hour(12);check(not glow.visible and is_zero_approx(glow.strength),"no added daylight pixels")
  e.set_hour(0);check(glow.is_visible_in_tree() and glow.strength==1,"night glow on")
  var previous:float=0
  for minute in 181:
   e.set_hour(17.0+minute/60.0)
   check(glow.strength>=previous and absf(glow.strength-previous)<0.009,"continuous evening gradient")
   previous=glow.strength
  previous=1
  for minute in 181:
   e.set_hour(5.0+minute/60.0)
   check(glow.strength<=previous and absf(glow.strength-previous)<0.009,"continuous dawn gradient")
   previous=glow.strength
  e.set_hour(0);m._switch_scene("village");check(not glow.is_visible_in_tree(),"hide outside fishing")
 seed(1108);var expected:float=randf();seed(1108);e.set_hour(19.4);check(randf()==expected,"no catch RNG use")
 m.audio_feedback.dispose();app.queue_free();await process_frame;await process_frame
 for glow in glows:check(not is_instance_valid(glow),"glow disposed with scene")
 print("NIGHT_GLOW_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
