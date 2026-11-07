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
 var e=m.environment
 for region in [0,1,2]:
  m.active_region=region;m._layout();m._switch_scene("fish");e.elapsed=3;e.valley.elapsed=3;e.set_hour(12)
  var lamp=e.light_layer if region==0 else (e.valley.layers.underwater_light if region==1 else e.tile.light)
  lamp.hide();await capture(m,out,"region%d_without"%region);lamp.show()
  for t in [0.0,3.0]:
   e.elapsed=t;e.valley.elapsed=t;e.update(0)
   await capture(m,out,"region%d_t%d"%[region,int(t)])
  e.set_hour(0);await capture(m,out,"region%d_night"%region)
 m.audio_feedback.dispose();app.queue_free();await process_frame;quit()
