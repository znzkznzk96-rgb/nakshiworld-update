extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String):
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 var app=load("res://tests/valley_native_root.gd").new();root.add_child(app);await app._start()
 var m=app.box.get_child(0).get_child(0);m.SET.music=0;m.SET.sfx=0;m.set_process(false)
 var tile=m.environment.tile;var decor=tile.scenery
 check(decor.get_parent()==tile.plate,"actual tile scenery attached")
 check(tile.plate.material.shader.resource_path.ends_with("tile_dream_tone.gdshader"),"approved plate-only tone")
 check(decor.clouds.size()==4 and decor.cloud_textures.size()==4,"four imported cloud forms")
 check(decor.tile_fish.size()==4,"four one-star decorative species")
 check(decor.bird_frames.size()==3,"three prefiltered bird depths")
 for level in 3:
  check(decor.bird_frames[level].size()==9,"nine imported motion frames")
  for frame in decor.bird_frames[level]:check(frame.get_size()==Vector2(decor.BIRD_NATIVE_SIZES[level]),"stable native size")
 seed(482);var expected=randf();seed(482)
 for t in [0,100,500,1000]:
  decor.elapsed=t;decor.update_clouds()
  for i in 4:
   var c=decor.cloud_motion[i];var x=decor.clouds[i].position.x
   check(x>=-c.width and x<=801+c.width,"wrapped beyond edges")
   check(c.variant>=0 and c.variant<4,"valid random form")
 check(randf()==expected,"decor RNG does not affect catch RNG")
 check(decor.support_node.position.y>977 and decor.support_node.show_behind_parent,"submerged support behind fish")
 for region in [0,1,2]:
  m.active_region=region;m._layout();m._switch_scene("fish")
  check(decor.is_visible_in_tree()==(region==2),"tile only visibility")
  var before=decor.elapsed;decor._process(.2)
  check((decor.elapsed>before)==(region==2),"visible-only animation")
 m._switch_scene("village");var before=decor.elapsed;decor._process(.2);check(decor.elapsed==before,"hidden clock paused")
 m.audio_feedback.dispose();app.queue_free();await process_frame;await process_frame
 check(not is_instance_valid(decor),"scenery disposed with native canvas")
 print("TILE_SCENERY_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
