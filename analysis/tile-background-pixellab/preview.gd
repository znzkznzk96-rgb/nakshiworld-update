extends SceneTree
func _initialize():call_deferred("run")
func capture(m,out:String,name:String):
 m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out.path_join(name+".png"))
func run():
 var out:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_size=Vector2i(270,660);root.size=Vector2i(540,1320)
 var app=load("res://tests/valley_native_root.gd").new();root.add_child(app);app._start()
 var m=app.box.get_child(0).get_child(0);m.development_preview=true;m.SET.music=0;m.SET.sfx=0;m.set_process(false);m.title_open=false;m.lesson_open=false;m.trans={};m.TUT.done=true;m.tip_t=0;m.S={"phase":"idle"}
 m.active_region=2;m._layout();m._switch_scene("fish");m.environment.elapsed=3;m.environment.set_hour(12)
 var wave=m.environment.tile.surface_water;wave.animated=false;wave.set_time(3)
 await capture(m,out,"before")
 var decor=load("res://tests/tile_background_preview_layer.gd").new();m.environment.tile.plate.add_child(decor)
 for frame in [0,45,90]:
  decor.elapsed=frame/15.0;decor.queue_redraw()
  await capture(m,out,"frame_%04d"%frame)
 m.audio_feedback.dispose();app.queue_free();await process_frame;quit()
