extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String):
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 var app=load("res://tests/valley_native_root.gd").new();root.add_child(app);app._start()
 var m=app.box.get_child(0).get_child(0);m.SET.music=0;m.SET.sfx=0;m.set_process(false);m.title_open=false
 var tile=m.environment.tile;var tex:Texture2D=tile.plate.texture
 var list:Array=[]
 for kind in ["surface","reflection","light","particles","flow","bubbles","pier","fish_mid","fish_near","plants_floor","plants_wall"]:
  var fx=load("res://tests/tile_water_layers.gd").new();fx.kind=kind;tile.plate.add_child(fx);list.append(fx)
 for height in [480,540,660]:
  root.content_scale_size=Vector2i(270,height);root.size=Vector2i(540,height*2);await process_frame;app._fit();await process_frame
  m.active_region=2;m._layout();m._switch_scene("fish");await process_frame
  check(tile.plate.texture==tex and tile.plate.get_child_count()==11,"original plate and eleven separate children")
  for fx in list:
   check(fx.is_visible_in_tree(),"tile effect visible at phone height")
   fx.animate=true;var before:float=fx.elapsed;fx._process(.25);fx.animate=false
   check(is_equal_approx(fx.elapsed,before+.25),"clock advances without game state changes")
  m._switch_scene("village")
  for fx in list:check(not fx.is_visible_in_tree(),"effects hidden outside fishing")
 var old_canvas=tile.native_canvas;m.audio_feedback.dispose();app.queue_free();await process_frame;await process_frame
 check(not is_instance_valid(old_canvas),"preview follows native disposal")
 print("TILE_LAYER_PREVIEW_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
