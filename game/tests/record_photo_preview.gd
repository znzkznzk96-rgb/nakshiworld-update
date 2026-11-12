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
 for h in [480,540,660]:
  root.content_scale_size=Vector2i(270,h);root.size=Vector2i(810,h*3);await process_frame;m.position=Vector2(m.ox,0)
  for kind in ["grade","length","weight"]:
   d.photo.open(m,0,kind)
   await capture(m,"record_%d_%s"%[h,kind])
 root.content_scale_size=Vector2i(270,540);root.size=Vector2i(810,1620);await process_frame;m.position=Vector2(m.ox,0)
 d.photo.close();await capture(m,"record_entry")
 for sp in [0,40,60,79]:
  var length:float=[8.9,54.2,161.5,243.1][[0,40,60,79].find(sp)]
  d.observe(sp,0 if sp==0 else 4,length,.111 if sp==0 else 8.7,"2026-11-13")
  d.photo.open(m,sp,"length");await capture(m,"record_species_%d"%sp)
  var image:Image=await d.photo.create_image(m)
  if image.get_size()!=Vector2i(1080,1380):failures.append("export dimensions")
  if image.save_png(output.path_join("souvenir_%d.png"%sp))!=OK:failures.append("export write")
  var a:Image=Image.load_from_file(output.path_join("souvenir_%d.png"%sp))
  if a.is_empty():failures.append("export decode")
 d.photo.open(m,0,"grade");d.photo.specimen={"grade":3,"legacy":true};await capture(m,"record_legacy")
 d.photo.close();m.audio_feedback.dispose();m.queue_free();await process_frame
 print("RECORD_PHOTO_PREVIEW failures=",failures," screens=15 souvenir_exports=4")
 quit(0 if failures.is_empty() else 1)
