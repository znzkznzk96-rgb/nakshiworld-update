extends SceneTree
var failures:Array=[]
func _initialize():call_deferred("run")
func shot(out:String,name:String):
 await process_frame;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png(out.path_join(name+".png"))==OK)
func run():
 Engine.max_fps=60
 var out:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_size=Vector2i(270,660);root.size=Vector2i(540,1320)
 var boot=load("res://root.gd").new();boot.preview_only=true;root.add_child(boot);await process_frame
 boot.update_phase="ready";boot.status="최신 버전입니다 · 곧 시작합니다"
 var tick:=Time.get_ticks_msec();boot._start()
 await create_timer(.25).timeout
 if boot.box!=null and boot.box.modulate.a>0:failures.append("game appeared before minimum splash")
 await shot(out,"no_update")
 var captured:bool=false
 while boot.status!="" and Time.get_ticks_msec()-tick<30000:
  if boot.box!=null and not captured:
   await shot(out,"loading");captured=true
  await process_frame
 var elapsed:=Time.get_ticks_msec()-tick
 if elapsed<2000:failures.append("minimum splash bypassed")
 if boot.status!="":failures.append("boot timed out")
 await shot(out,"game")
 print("UPDATER_SMOOTHNESS_PREVIEW failures=",failures," elapsed_ms=",elapsed," stages=",boot.boot_timings)
 for n in root.find_children("*","Node2D",true,false):
  if n.get_script()!=null and n.get_script().resource_path=="res://main.gd":n.set_process(false);n.audio_feedback.dispose()
 for player in root.find_children("*","AudioStreamPlayer",true,false):player.stop();player.stream=null
 await create_timer(.25).timeout
 boot.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
