extends SceneTree
func _initialize():call_deferred("run")
func capture(m,path:String):
 m._last_draw_t=-1;m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(path)
func run():
 var out:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
 var text:=Node2D.new();text.set_script(load("res://text_layer.gd"));ui.add_child(text)
 var m=load("res://main.gd").new();m.text_layer=text;m.development_preview=true;m.SET.music=0;m.SET.sfx=0;root.add_child(m);await process_frame;m.set_process(false);m.development_preview=true
 m.title_open=false;m.title_screen.root.hide();m.lesson_open=false;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.tip_t=0;m.toast_t=0
 for h in [480,540,660]:
  root.content_scale_size=Vector2i(270,h);root.size=Vector2i(540,h*2);await process_frame
  m.active_region=3;m._layout();m._switch_scene("fish");m.environment.set_hour(18);m.environment.update(0)
  for sp in [2,3,19,75]:
   m.S={"phase":"result","ok":true,"sp":sp,"star":0,"grade":0,"len":float(m.FISH_LEN[sp]),"weight":.1,"lf":1.0,"persona":"보통","judge":"성공","newRec":false};m.result_t=.3
   await capture(m,out.path_join("result-%d-%d.png"%[h,sp]))
  for sp in [2,75]:
   m.start_wait();m.S.sp=sp;m.S.size=0 if sp==2 else 3;m.S.star=0;m.S.grade=0;m.S.biteAt=10;m.S.realUntil=12;m.S.fakes=[];m.clock=10.4;m.start_hook();m.reveal_pending=false;m.reveal_t=0;m.judge_t=0;m.visibility_flash=0
   await capture(m,out.path_join("bite-%d-%d.png"%[h,sp]))
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print("FISH_DISPLAY_SIZE_PREVIEW failures=[] screens=18");quit()
