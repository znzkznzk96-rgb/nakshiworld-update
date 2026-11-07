extends SceneTree
func _initialize():call_deferred("run")
func capture(m,out:String,name:String):
 m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out.path_join(name+".png"))
func run():
 var out:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_size=Vector2i(270,660);root.size=Vector2i(540,1320)
 var app=load("res://tests/valley_native_root.gd").new();root.add_child(app);app._start()
 var sv:SubViewport=app.box.get_child(0);var m=sv.get_child(0)
 m.development_preview=true;m.SET.music=0;m.SET.sfx=0;m.set_process(false);m.title_open=false;m.lesson_open=false;m.trans={};m.TUT.done=true;m.tip_t=0;m.S={"phase":"idle"}
 m.active_region=2;m._layout();m._switch_scene("fish")
 await capture(m,out,"before")
 var layers:Array=[]
 for kind in ["surface","reflection","light","caustics","particles","flow","bubbles","pier","fish_mid","fish_near","plants_floor","plants_wall"]:
  var node=load("res://tests/tile_water_layers.gd").new();node.kind=kind;node.name="Preview_"+kind;node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
  for id in [0,2,5]:node.fish_textures.append(load("res://art/fish/l2_%02d.png"%id))
  if kind=="plants_floor" or kind=="plants_wall":
   var prefix:String="floor" if kind=="plants_floor" else "wall"
   for id in [1,2]:
    var path:String="res://tests/tile_layer_assets/%s-plant-%02d.png"%[prefix,id]
    if FileAccess.file_exists(path):node.plant_textures.append(ImageTexture.create_from_image(Image.load_from_file(path)))
  m.environment.tile.plate.add_child(node);layers.append(node)
 for t in [0.0,3.0,6.0]:
  for layer in layers:layer.elapsed=t;layer.queue_redraw()
  await capture(m,out,"water_%d"%int(t))
 m.audio_feedback.dispose();app.queue_free();await process_frame;quit()
