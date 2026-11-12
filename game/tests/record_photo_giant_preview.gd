extends SceneTree
var output:String
var failures:Array=[]
func _initialize():call_deferred("run")
func render(m,path:String):
 m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
 var im:=root.get_texture().get_image()
 im.save_png(output.path_join(path+".png"))
func run():
 output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 root.content_scale_size=Vector2i(270,540);root.size=Vector2i(540,1080)
 var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
 var text:=Node2D.new();text.set_script(load("res://text_layer.gd"));ui.add_child(text)
 var m=load("res://main.gd").new();m.text_layer=text;m.SET.music=0;m.SET.sfx=0;root.add_child(m);await process_frame;m.set_process(false);m.position=Vector2(m.ox,0)
 m.title_open=false;m.title_screen.leaving=false;m.title_screen.root.hide();m.lesson_open=false;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.tip_t=0
 var d=m.personal_dex;d.open(m)
 for sp in [0,16,47,51,64,75]:
  d.observe(sp,4,320.7,111.1,"2026-11-13");d.photo.open(m,sp,"length")
  for t in [0.0,.5,1.5]:
   d.photo.preview_time=t;await render(m,"giant_%d_%d"%[sp,int(t*10)])
  var a:Image=await d.photo.create_image(m)
  d.photo.preview_time=.1;var b:Image=await d.photo.create_image(m)
  if a.get_data()!=b.get_data():failures.append("unstable giant export")
  if sp in [51,75]:a.save_png(output.path_join("giant_souvenir_%d.png"%sp))
 d.photo.open(m,51,"length")
 DirAccess.make_dir_recursive_absolute(output.path_join("intro"))
 for frame in 36:
  d.photo.preview_time=frame/12.0;await render(m,"intro/%03d"%frame)
 for h in [480,660]:
  root.content_scale_size=Vector2i(270,h);root.size=Vector2i(540,h*2);await process_frame;m.position=Vector2(m.ox,0)
  d.photo.open(m,75,"length");d.photo.preview_time=1.5;await render(m,"giant_height_%d"%h)
 d.photo.close();m.audio_feedback.dispose();m.queue_free();await process_frame
 print("RECORD_PHOTO_GIANT_PREVIEW failures=",failures," screens=20 intro_frames=36 stable_exports=12")
 quit(0 if failures.is_empty() else 1)
