extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String):
 if not ok:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 var args:=OS.get_cmdline_user_args();var out:String=args[0] if not args.is_empty() else ""
 if out!="":DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
 var text:=Node2D.new();text.set_script(load("res://text_layer.gd"));ui.add_child(text)
 var m=load("res://main.gd").new();m.text_layer=text;m.SET.music=0;m.SET.sfx=0;m.development_preview=true;root.add_child(m);await process_frame;m.set_process(false);m.development_preview=true
 m.title_open=false;m.title_screen.root.hide();m.lesson_open=false;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.tip_t=0;m.toast_t=0;m._switch_scene("village")
 var e=m.expedition;e.data.restore({})
 for h in [480,540,660]:
  root.content_scale_size=Vector2i(270,h);root.size=Vector2i(540,h*2);await process_frame
  m.ui_clock=10;e.open(m,"explore");e.explore_tab=0;m.text_items=[];m.ui_commands=[];e.draw(m,h)
  check(e.rects.has("start"),"real start button exists")
  e.press(m,e.rects.start.get_center())
  check(e.data.team.is_empty() and e.data.battle.is_empty(),"failed launch preserves empty party")
  check(e.notice=="병사 3마리를 편성하고 회복을 기다리세요" and e.start_notice_until==13,"failure uses timed foreground notice")
  check(m.toast_t==0,"no duplicate village toast")
  m.text_items=[];m.ui_commands=[];e.draw(m,h)
  var r:Rect2=e.start_notice_rect(h)
  check(absf(r.get_center().y-h/2.0)<.51 and r.position.x==16,"notice centered and in bounds")
  check(m.ui_commands[-1][0]=="style" and m.ui_commands[-1][2]==r,"notice surface is drawn after expedition contents")
  check(m.text_items[-1][0]!=null,"foreground text present")
  if out!="" and DisplayServer.get_name()!="headless":
   m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(out.path_join("notice-%d.png"%h))
  m.ui_clock=14;m.text_items=[];m.ui_commands=[];e.draw(m,h)
  check(not m.ui_commands.any(func(c):return c[0]=="style" and c[2]==r),"notice expires")
  e.open(m,"explore");check(e.start_notice_until==0,"opening clears stale notice")
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print("EXPEDITION_START_NOTICE_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
