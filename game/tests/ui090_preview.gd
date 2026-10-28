extends SceneTree
func _initialize():call_deferred("run")
func capture(m,out,name):
 m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out.path_join(name+".png"))
func run():
 var out=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 var ui=CanvasLayer.new();root.add_child(ui);var txt=Node2D.new();txt.set_script(load("res://text_layer.gd"));ui.add_child(txt)
 var m=load("res://main.gd").new();m.text_layer=txt;m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 m.title_open=false;m.lesson_open=false;m.tip_t=0;m.trans={};m.TUT.done=true;m.scene="village";m.V.enter(m);m.gold=10000;m.expedition.data.restore({});m.expedition.data.souls=[20,20,20,20,20]
 for id in [0,1,2,3,4,5,6,7,12,14]:m.expedition.data.discover(id)
 for i in 20:m.expedition.data.add_unit(i%15,1,[4,5,6])
 m.aqua_lv=0;m.aqua=[]
 for i in 3:m.aqua.append({"sp":i,"grade":0,"len":23.5,"w":.01,"price":100})
 m.DEX={};m.REC={}
 for i in range(12):m.DEX[m.fish_key(i)]=[0,1];m.REC[m.fish_key(i)]=25.0
 for h in [480,660]:
  root.content_scale_size=Vector2i(270,h);root.size=Vector2i(540,h*2);await process_frame;m._layout()
  m.expedition.opened="";m.personal_dex.opened=false;m.V.open_shop(m,"aqua");m.V.aqua_manage=false;await capture(m,out,"aquarium_%d"%h)
  m.V.shop="";m.personal_dex.open(m);m.personal_dex.category="fish";await capture(m,out,"fish_list_%d"%h)
  m.personal_dex.category="soldier";await capture(m,out,"soldier_list_%d"%h)
  m.personal_dex.opened=false;m.expedition.open(m,"alchemy");m.expedition.tab=0;m.expedition.pair=[4,4];await capture(m,out,"alchemy_%d"%h)
  m.expedition.tab=1;await capture(m,out,"fusion_%d"%h)
  m.expedition.roster_scroll=m.expedition.roster_max_scroll;await capture(m,out,"fusion_last_%d"%h)
  m.expedition.tab=2;m.expedition.roster_scroll=0;await capture(m,out,"roster_%d"%h)
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit()
