extends SceneTree
func _initialize():call_deferred("run")
func capture(m,out,name):
 m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out.path_join(name+".png"))
func run():
 var out=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 var ui=CanvasLayer.new();root.add_child(ui);var txt=Node2D.new();txt.set_script(load("res://text_layer.gd"));ui.add_child(txt)
 var m=load("res://main.gd").new();m.text_layer=txt;m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 m.title_open=false;m.lesson_open=false;m.trans={};m.TUT.done=true;m.tip_t=0;m.gold=6600;m.region_shop.selected_bait=-1
 for h in [480,660]:
  root.content_scale_size=Vector2i(270,h);root.size=Vector2i(540,h*2);await process_frame;m._layout();m._switch_scene("village")
  m.mailbox.opened=true;m.mailbox.detail="0.93";await capture(m,out,"mail_%d"%h);m.mailbox.opened=false
  m._switch_scene("fish");await capture(m,out,"empty_%d"%h)
  m.start_wait();await capture(m,out,"fishing_%d"%h)
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit()
