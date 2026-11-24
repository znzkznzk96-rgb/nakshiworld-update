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
  root.content_scale_size=Vector2i(270,h);root.size=Vector2i(540,h*2);await process_frame;m._layout()
  for money in [0,999999999]:
   m.gold=money
   for shop in ["up","work","aqua","harbor","hall","forge","museum"]:
    m.V.open_shop(m,shop)
    await capture(m,out,"%s_money%d_h%d"%[shop,money,h])
   m.V.open_shop(m,"up")
   for tab in ["bait","pouches","gear_sell"]:
    m.V.tab=tab;await capture(m,out,"shop_%s_money%d_h%d"%[tab,money,h])
  m.V.shop="";m.settings_open=true
  for page in ["main","license","book"]:
   m.set_view=page;await capture(m,out,"settings_%s_h%d"%[page,h])
  m.set_view="main";m.reset_confirm=true;await capture(m,out,"reset_confirm_h%d"%h);m.reset_confirm=false;m.settings_open=false
  m.capture_robot.opened=true
  for owned in [false,true]:
   m.capture_robot.owned=owned
   for tab in 3:
    m.capture_robot.shop_tab=tab;await capture(m,out,"robot_%s_tab%d_h%d"%[owned,tab,h])
  m.capture_robot.opened=false
  m.guide.open_home();await capture(m,out,"guide_home_h%d"%h)
  m.guide.tab=2;m.guide.topic=0;m.guide.change_screen("article");await capture(m,out,"guide_pond_h%d"%h);m.guide.opened=false;m.guide.sync_layer()
  m.scene="spots";await capture(m,out,"spots_h%d"%h);m.scene="village"
 print("EXTRA_PREVIEW_DONE")
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit()
