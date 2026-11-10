extends SceneTree
var failures:Array=[]
func _initialize():call_deferred("run")
func capture(m,out:String,name:String):
 m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png(out.path_join(name+".png"))==OK)
 for row in m.V.rects.rows:
  if not m.V.rects.panel.encloses(row[0]):failures.append("outside button "+name+" "+str(row[1]))
func run():
 var out:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
 var txt:=Node2D.new();txt.set_script(load("res://text_layer.gd"));ui.add_child(txt)
 var m=load("res://main.gd").new();m.text_layer=txt;m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame
 m.set_process(false);m.title_open=false;m.lesson_open=false;m.tip_t=0;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.scene="village";m.S={"phase":"idle"};m.V.enter(m)
 m.gold=32075;m.pearl=2;m.souls=100;m.region_shop.unlocked=[0,1,2];m.active_region=0;m.pond_cap_lv=2;m.pond_regen_lv=0;m.pond_stock=50;m.pond_overflow=110
 m.equipment.rods=[0,1,2];m.rod_owned=2;m.rod_lv=2;m.equipment.rod_equipped=true
 m.expedition.data.add_unit(0,1,[0,0,0])
 for height in [480,540,660]:
  root.content_scale_size=Vector2i(270,height);root.size=Vector2i(540,height*2);await process_frame;m._layout()
  for shop in ["hall","forge","museum"]:
   m.V.open_shop(m,shop);await capture(m,out,"%s_%d"%[shop,height])
  m.V.shop="";m.market_open=true;m.inventory.tab="inventory";await capture(m,out,"bag_%d"%height);m.market_open=false
  m.personal_dex.open(m);m.personal_dex.category="fish";await capture(m,out,"dex_%d"%height);m.personal_dex.opened=false
  m.expedition.opened="explore";m.expedition.explore_tab=1;m.expedition.formation_uid=int(m.expedition.data.soldiers[0].uid);m.expedition.formation_target=0
  await capture(m,out,"roster_%d"%height);m.expedition.opened=""
 print("CLOSE_CONTROLS_PREVIEW failures=",failures)
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
