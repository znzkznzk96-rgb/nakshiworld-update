extends SceneTree
func _initialize():call_deferred("run")
func capture(path:String):
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(path)
func run():
 var out:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
 var text:=Node2D.new();text.set_script(load("res://text_layer.gd"));ui.add_child(text)
 var m=load("res://main.gd").new();m.text_layer=text;m.SET.music=0;m.SET.sfx=0;m.development_preview=true;root.add_child(m);await process_frame;m.set_process(false);m.development_preview=true
 m.title_open=false;m.title_screen.root.hide();m.lesson_open=false;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.tip_t=0
 root.content_scale_size=Vector2i(270,660);root.size=Vector2i(540,1320);await process_frame
 m._switch_scene("spots");m.region_shop.unlocked=[0,1,2,3];m.spots.index=3;m.spots.scroll=3;m.spots.shift=0
 for i in 96:
  m.spots.unlock_fx.start(3);m.spots.unlock_fx.elapsed=minf(i/30.0,3.15);m.queue_redraw()
  await capture(out.path_join("frame-%03d.png"%i))
 for h in [480,540,660]:
  root.content_scale_size=Vector2i(270,h);root.size=Vector2i(540,h*2);await process_frame
  for n in 6:
   m.spots.index=n;m.spots.scroll=n;m.spots.unlock_fx.start(n);m.spots.unlock_fx.elapsed=1.5;m.queue_redraw()
   await capture(out.path_join("layout-%d-%d.png"%[h,n]))
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print("SPOT_UNLOCK_PREVIEW_OK 96 frames 18 layout cases");quit()
