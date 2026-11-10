extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String):
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 var app=load("res://tests/valley_native_root.gd").new();root.add_child(app);await app._start()
 var m=app.box.get_child(0).get_child(0);m.SET.music=0;m.SET.sfx=0;m.set_process(false);m.title_open=false
 var e=m.environment
 check(e.light_layer.material.shader.resource_path.ends_with("vertical_water_light.gdshader"),"reservoir shared shader")
 check(e.valley.layers.underwater_light.get_parent()==e.valley.plate,"valley native source parent")
 check(e.tile.light.get_parent()==e.tile.plate,"tile native source parent")
 for height in [480,540,660]:
  root.content_scale_size=Vector2i(270,height);root.size=Vector2i(540,height*2);await process_frame;app._fit();await process_frame
  for region in [0,1,2]:
   m.active_region=region;m._layout();m._switch_scene("fish");e.set_hour(12)
   var mat:ShaderMaterial=e.light_layer.material if region==0 else (e.valley.layers.underwater_light.shader_material if region==1 else e.tile.light.shader_material)
   var lamp=e.light_layer if region==0 else (e.valley.layers.underwater_light if region==1 else e.tile.light)
   check(lamp.is_visible_in_tree(),"region light visible at screen height")
   check(mat.shader.resource_path.ends_with("vertical_water_light.gdshader"),"one shader for all")
   check(mat.get_shader_parameter("light_intensity")>.99,"noon light on")
   e.set_hour(0);check(is_zero_approx(mat.get_shader_parameter("light_intensity")),"night light off")
   m._switch_scene("village");check(not lamp.is_visible_in_tree(),"light hidden outside fishing")
 seed(729);var expected:float=randf();seed(729);e.update(.25);check(randf()==expected,"catch RNG preserved")
 var valley_light=e.valley.layers.underwater_light;var tile_light=e.tile.light
 m.audio_feedback.dispose();app.queue_free();await process_frame;await process_frame
 check(not is_instance_valid(valley_light) and not is_instance_valid(tile_light),"native fields disposed")
 print("SHARED_VERTICAL_LIGHT_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
