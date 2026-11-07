extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String):
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 var app=load("res://tests/valley_native_root.gd").new();root.add_child(app);app._start()
 var m=app.box.get_child(0).get_child(0);m.SET.music=0;m.SET.sfx=0;m.set_process(false);m.title_open=false
 var e=m.environment;var wave=e.tile.surface_water
 check(wave.get_parent()==e.tile.plate,"source plate parent")
 check(wave.layers.size()==2,"two bounded layers")
 var back:ShaderMaterial=wave.layers[0].material;var front:ShaderMaterial=wave.layers[1].material
 check(back!=front and back.get_shader_parameter("flow_direction")>0 and front.get_shader_parameter("flow_direction")<0,"independent opposite flows")
 check(back.get_shader_parameter("speed")<front.get_shader_parameter("speed"),"parallax speeds")
 seed(482);var expected:float=randf();seed(482);wave.make_pattern(20261108);check(randf()==expected,"local generator preserves catch RNG")
 for height in [480,540,660]:
  root.content_scale_size=Vector2i(270,height);root.size=Vector2i(540,height*2);await process_frame;app._fit();await process_frame
  for region in [0,1,2]:
   m.active_region=region;m._layout();m._switch_scene("fish")
   check(wave.is_visible_in_tree()==(region==2),"tile only visibility")
  wave.animated=false;wave.set_time(3);check(is_equal_approx(front.get_shader_parameter("elapsed"),3.0),"shader clock")
  m._switch_scene("village");check(not wave.is_visible_in_tree(),"menu hidden")
 m.audio_feedback.dispose();app.queue_free();await process_frame;await process_frame
 check(not is_instance_valid(wave),"native wave disposed")
 print("TILE_SURFACE_WATER_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
