extends SceneTree
func _initialize():call_deferred("run")
func capture(m,out:String,name:String):
 m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
 assert(root.get_texture().get_image().save_png(out.path_join(name+".png"))==OK)
func run():
 var out:String=OS.get_cmdline_user_args()[0];assert(DirAccess.make_dir_recursive_absolute(out)==OK)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
 var txt:=Node2D.new();txt.set_script(load("res://text_layer.gd"));ui.add_child(txt)
 var m=load("res://main.gd").new();m.text_layer=txt;m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame
 m.set_process(false);m.title_open=false;m.lesson_open=false;m.tip_t=0;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.scene="village";m.S={"phase":"idle"};m.V.enter(m)
 m.DEX={}
 for sp in 60:
  if sp%5!=4:m.DEX[m.fish_key(sp)]=[0,1,2,3] if sp%3==0 else [0,2] if sp%3==1 else [1]
 m.expedition.data.restore({})
 for id in 15:m.expedition.data.discover(id)
 for height in [480,540,660]:
  root.content_scale_size=Vector2i(270,height);root.size=Vector2i(540,height*2);await process_frame
  m.personal_dex.open(m)
  for region in [0,1,2,3,4,5]:
   m.personal_dex.region=region;await capture(m,out,"fish_%d_%d"%[region,height])
  m.personal_dex.category="soldier"
  for star in [1,2,3]:
   m.personal_dex.soldier_star=star;await capture(m,out,"soldier_%d_%d"%[star,height])
  m.personal_dex.selected=0;await capture(m,out,"detail_3_%d"%height)
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print("DEX_READABILITY_PREVIEW failures=[]");quit()
