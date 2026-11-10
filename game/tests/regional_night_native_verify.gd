extends SceneTree
func _initialize():call_deferred("run")
func run():
 var args=OS.get_cmdline_user_args();var out:String=args[0];var before:bool=args.size()>1 and args[1]=="before"
 DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_size=Vector2i(270,540);root.size=Vector2i(810,1620)
 var app=load("res://tests/valley_native_root.gd").new();root.add_child(app);await app._start()
 var m=app.box.get_child(0).get_child(0);m.development_preview=true;m.SET.sfx=0;m.SET.music=0;m.set_process(false)
 m.title_open=false;m.lesson_open=false;m.trans={};m.TUT.done=true;m.tip_t=0;m.toast_t=0;m.judge_t=0;m.S={"phase":"idle"};m.anim_t=0;m.clock=0
 var e=m.environment;e.elapsed=3;e.valley.elapsed=3;e.tile.scenery.animated=false;e.tile.scenery.elapsed=3;e.tile.surface_water.animated=false;e.tile.surface_water.set_time(3)
 for height in ([540] if before else [480,540,660]):
  root.content_scale_size=Vector2i(270,height);root.size=Vector2i(810,height*3);await process_frame;app._fit();await process_frame
  for region in [1,2]:
   m.active_region=region;m._layout();m._switch_scene("fish")
   for hour in ([12] if before else [12,18.5,0]):
    e.set_hour(hour);m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(out.path_join("r%d_h%d_t%s.png"%[region,height,str(hour)]))
 m.audio_feedback.dispose();app.queue_free();await process_frame
 print("REGIONAL_NIGHT_NATIVE_VERIFY failures=[]");quit()
