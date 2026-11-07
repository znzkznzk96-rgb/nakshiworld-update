extends SceneTree
func _initialize():call_deferred("run")
func run():
 var layer=load("res://tests/tile_cloud_birds_layer.gd").new();root.add_child(layer)
 assert(layer.clouds.size()==4 and layer.cloud_textures.size()==4)
 assert(layer.bird_frames.size()==3)
 for level in 3:
  assert(layer.bird_frames[level].size()==9)
  for frame in layer.bird_frames[level]:assert(frame.get_size()==Vector2(layer.BIRD_NATIVE_SIZES[level]))
 var seen={};var snapshots=[]
 for t in [0,100,250,500,1000]:
  layer.elapsed=t;layer.update_clouds();var forms=[]
  for i in 4:
   var c=layer.cloud_motion[i];var pos=layer.clouds[i].position
   assert(pos.x>=-c.width and pos.x<=801+c.width)
   assert(c.speed>0 if i%2==0 else c.speed<0)
   assert(c.variant>=0 and c.variant<4);forms.append(c.variant);seen[c.variant]=true
  snapshots.append({"seconds":t,"forms":forms})
 assert(seen.size()==4)
 print("CLOUD_BIRD_CHECK ",JSON.stringify({"passed":true,"snapshots":snapshots,"native_bird_levels":3,"frames_each":9}))
 layer.queue_free();await process_frame;quit()
