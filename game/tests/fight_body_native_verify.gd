extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String):
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 var out:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_size=Vector2i(270,540);root.size=Vector2i(810,1620)
 var app=load("res://tests/valley_native_root.gd").new();root.add_child(app);app._start()
 var m=app.box.get_child(0).get_child(0);m.development_preview=true;m.SET.sfx=0;m.SET.music=0;m.set_process(false)
 m.title_open=false;m.lesson_open=false;m.trans={};m.TUT.done=true;m.tip_t=0;m.toast_t=0;m.judge_t=0;m.visibility_flash=0
 for sp in [42,49,59]:
  m.active_region=2;m._layout();m._switch_scene("fish");m.S={"sp":sp,"star":0,"grade":0,"lf":1.0};m.start_fight()
  m.S.beh="swim";m.S.dist=35;m.S.fx=155;m.S.fy=m.WATER+95;m.S.dispY=m.S.fy;m.S.F=0.3;m._last_draw_t=-1;m.anim_t=0;m.clock=0
  m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(out.path_join("fight_%d.png"%sp))
  var expected:float=m._fight_body_length(sp,1.0,0)
  check(is_equal_approx(m.aura.L,expected),"actual fight body")
  check(is_equal_approx(m.S.lastF.body_length,expected),"landing snapshot")
  check(m.S.mouth.distance_to(m.fish_mouth)<0.001,"same frame mouth")
  m.S.phase="catch";m.S.t=0.2;m.S.netEnd=1.15;m.S.ok=true;m.S.newRec=false
  m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
  check(is_equal_approx(m.aura.L,expected),"actual landing body unchanged")
  root.get_texture().get_image().save_png(out.path_join("landing_%d.png"%sp))
 m.audio_feedback.dispose();app.queue_free();await process_frame
 print("FIGHT_BODY_NATIVE_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
