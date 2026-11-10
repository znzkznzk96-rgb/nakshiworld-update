extends SceneTree
var failures:Array=[]
func _initialize()->void:call_deferred("run")
func run()->void:
 var out:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 var m=load("res://root.gd").new();m.preview_only=true;root.add_child(m);await process_frame;m.set_process(false)
 for h in [480,660,740]:
  root.content_scale_size=Vector2i(270,h);root.size=Vector2i(540,h*2);await process_frame
  for phase in ["checking","download"]:
   m.update_phase=phase;m.status="업데이트 확인 중…" if phase=="checking" else "새 버전 1.18 받는 중…";m.expected_size=650541;m.received_bytes=487905;m.progress=.75;m.animation_time=1.2;m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(out.path_join("%s-h%d.png"%[phase,h]))
  if h==660:
   for frame in 16:
    m.animation_time=frame*(TAU/1.55)/16;m.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(out.path_join("chase-%02d.png"%frame))
 print("UPDATER_PREVIEW failures=",failures);m.queue_free();await process_frame;quit()
