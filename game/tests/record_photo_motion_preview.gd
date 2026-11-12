extends SceneTree
var output:String
var failures:Array=[]
func _initialize():call_deferred("run")
func run():
 output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 root.content_scale_size=Vector2i(270,540);root.size=Vector2i(540,1080)
 var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
 var text:=Node2D.new();text.set_script(load("res://text_layer.gd"));ui.add_child(text)
 var m=load("res://main.gd").new();m.text_layer=text;m.SET.music=0;m.SET.sfx=0;root.add_child(m);await process_frame;m.set_process(false)
 m.position=Vector2(m.ox,0)
 m.title_open=false;m.title_screen.leaving=false;m.title_screen.root.hide();m.lesson_open=false;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.tip_t=0
 var d=m.personal_dex;d.open(m)
 for sp in [0,16,47,51,64,75]:
  d.observe(sp,2,28.9,1.111,"2026-11-13");d.photo.open(m,sp,"length")
  var before:=JSON.stringify(d.photo.specimen)
  var folder:=output.path_join(str(sp));DirAccess.make_dir_recursive_absolute(folder)
  for frame in 48:
   d.photo.preview_time=frame/9.0
   m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
   var image:=root.get_texture().get_image()
   # Actual rendered game window, cropped only for a compact motion review.
   image.get_region(Rect2i(24,130,492,510)).save_png(folder.path_join("%03d.png"%frame))
   if frame==3:image.save_png(output.path_join("record_motion_%d.png"%sp))
  d.photo.preview_time=.4
  var a:Image=await d.photo.create_image(m)
  d.photo.preview_time=3.0
  var b:Image=await d.photo.create_image(m)
  if a.get_data()!=b.get_data():failures.append("unstable export %d"%sp)
  if JSON.stringify(d.photo.specimen)!=before:failures.append("record changed")
  if sp==64:a.save_png(output.path_join("stable_souvenir.png"))
 d.photo.close();m.audio_feedback.dispose();m.queue_free();await process_frame
 print("RECORD_PHOTO_MOTION_PREVIEW failures=",failures," profiles=6 frames=288 stable_exports=12")
 quit(0 if failures.is_empty() else 1)
