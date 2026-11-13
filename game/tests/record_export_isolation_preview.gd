extends SceneTree
var output:String
var failures:Array=[]
func _initialize():call_deferred("run")
func capture(m,name:String):
 m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
 if root.get_texture().get_image().save_png(output.path_join(name+".png"))!=OK:failures.append(name)
func run():
 seed(132)
 output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
 var text:=Node2D.new();text.set_script(load("res://text_layer.gd"));ui.add_child(text)
 var m=load("res://main.gd").new();m.text_layer=text;m.SET.music=0;m.SET.sfx=0;root.add_child(m);await process_frame;m.set_process(false)
 m.title_open=false;m.title_screen.leaving=false;m.title_screen.root.hide();m.lesson_open=false;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.tip_t=0
 var d=m.personal_dex;d.open(m);d.selected=0;d.observe(0,0,8.9,.111,"2026-11-13")
 root.content_scale_size=Vector2i(270,540);root.size=Vector2i(810,1620);await process_frame;m.position=Vector2(m.ox,0)
 d.photo.open(m,0,"length")
 var before:Image=await d.photo.create_image(m)
 var blocker:=ColorRect.new();blocker.color=Color.MAGENTA;blocker.size=Vector2(1080,1380);ui.add_child(blocker)
 var after:Image=await d.photo.create_image(m)
 if before.get_data()!=after.get_data():failures.append("main canvas leaked into photograph")
 if after.get_size()!=Vector2i(1080,1380):failures.append("export dimensions")
 after.save_png(output.path_join("isolated_souvenir.png"))
 blocker.queue_free();await process_frame
 d.photo.close();await capture(m,"record_button")
 d.photo.open(m,0,"length");await capture(m,"record_screen")
 for t in [4.6+.4,4.6+.75,4.6+1.2]:
  if m.title_screen.flash_at(t).pulse<=.1:failures.append("repeat lightning beat")
 d.photo.close();m.audio_feedback.dispose();m.queue_free();await process_frame
 print("RECORD_EXPORT_ISOLATION_PREVIEW failures=",failures," screens=2 canvas_contamination_pixel_equality=true repeat_cycle=4.6")
 quit(0 if failures.is_empty() else 1)
