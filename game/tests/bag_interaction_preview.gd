extends SceneTree
func _initialize() -> void:call_deferred("run")
func capture(m,out: String,name: String) -> void:
 m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out.path_join(name+".png"))
func run() -> void:
 var out: String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 var layer=CanvasLayer.new();layer.layer=10;root.add_child(layer);var txt=Node2D.new();txt.set_script(load("res://text_layer.gd"));layer.add_child(txt)
 var m=load("res://main.gd").new();m.development_preview=true;m.text_layer=txt;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false;m.lesson_open=false;m.tip_t=0;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.scene="village";m.S={"phase":"idle"};m.V.enter(m)
 for height in [480,660]:
  root.content_scale_size=Vector2i(270,height);root.size=Vector2i(540,height*2);await process_frame
  var d=m.expedition.data;d.restore({});m.gold=5000;d.pouches=12
  m.expedition.opened="";m.V.open_shop(m,"up");m.V.tab="pouches";await capture(m,out,"pouch_shop_%d"%height)
  m.V.commerce.request(m.V,m,"soul_pouch:5");await capture(m,out,"pouch_buy_%d"%height);m.V.commerce.confirm(m.V,m)
  preload("res://addons/reservoir/soul_pouch_shop.gd").open(m.V,m,0);await capture(m,out,"pouch_open_%d"%height)
  m.V.shop="";m.V.commerce.pending={};m.market_open=true;m.market_sell=false;m.inventory.sync(m);m.ui_clock+=1
  m.equipment.rods=[0,1,2,3,4,5];m.equipment.bags=[0,1,2,3];m.parts_owned=["float","hook","line","reel"];m.equipment.active_parts=[]
  for tab in ["inventory","equipment"]:
   m.inventory.tab=tab
   if tab=="equipment":m.equipment.active_parts=m.parts_owned.duplicate();m.bag_lv=3
   await capture(m,out,tab+"_top_%d"%height)
   m.equipment.scroll_inventory(10000);await capture(m,out,tab+"_bottom_%d"%height)
  m.market_open=false
 m.audio_feedback.dispose();m.queue_free();await process_frame;layer.queue_free();await process_frame;print("SOUL_POUCH_PREVIEW complete");quit()
