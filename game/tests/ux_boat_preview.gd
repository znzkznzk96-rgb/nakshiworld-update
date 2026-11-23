extends SceneTree
func _initialize():call_deferred("run")
func capture(m,out:String,name:String):
 m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out.path_join(name+".png"))
func run():
 var out=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 var ui=CanvasLayer.new();ui.layer=10;root.add_child(ui)
 var txt=Node2D.new();txt.set_script(load("res://text_layer.gd"));ui.add_child(txt)
 var m=load("res://main.gd").new();m.text_layer=txt;m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame
 m.set_process(false);m.title_open=false;m.lesson_open=false;m.tip_t=0;m.trans={};m.TUT.done=true;m.scene="village";m.S={"phase":"idle"};m.V.enter(m)
 for h in [480,540,660]:
  root.content_scale_size=Vector2i(270,h);root.size=Vector2i(540,h*2);root.set_meta("ver","1.42");await process_frame;m._layout()
  m.title_open=true;m.title_screen.update(m,10.0);await capture(m,out,"title_h%d"%h);m.title_open=false;m.title_screen.update(m,0)
  m._switch_scene("fish");m.toast_t=0;m.judge_t=0;m.pond_stock=0.75;m.S={"phase":"idle"};m.equipment.rod_equipped=true;m.start_cast();await capture(m,out,"pond075_blocked_h%d"%h);m.tip_t=0
  m._switch_scene("village");m.toast_t=0;m.judge_t=0;m.active_region=3;m.region_shop.unlocked=[0,1,2,3];m.boat_lv=5;m.pond_cap_lv=6;m.pond_regen_lv=6
  m.gold=2000000
  for shop in ["harbor","hall"]:
   m.V.open_shop(m,shop);await capture(m,out,"rift_%s_h%d"%[shop,h])
  m.V.shop="";m.show_tip("", "기존 저장을 읽을 수 없어 자동 저장을 중지했어요.");await capture(m,out,"save_warning_h%d"%h);m.tip_t=0
  m.show_tip("", "어장이 비었어요. 1마리 이상 회복되면 낚시할 수 있어요");await capture(m,out,"pond_notice_h%d"%h);m.tip_t=0
  m.tip_t=0;m.V.shop=""
  m.guide.open_home();m.guide.tab=2;m.guide.topic=0;m.guide.change_screen("article");await capture(m,out,"guide_pond_h%d"%h)
  m.guide.tab=3;m.guide.topic=0;m.guide.change_screen("article");await capture(m,out,"guide_boat_h%d"%h)
  m.guide.opened=false;m.guide.sync_layer()
 print("UX_BOAT_PREVIEW_DONE")
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit()
