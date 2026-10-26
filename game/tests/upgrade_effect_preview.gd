extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(m,out: String,name: String) -> void:
 m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out.path_join(name+".png"))
func run() -> void:
 var out: String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_size=Vector2i(270,540);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.size=Vector2i(540,1080)
 var ui=CanvasLayer.new();ui.layer=10;root.add_child(ui)
 var txt=Node2D.new();txt.set_script(load("res://text_layer.gd"));ui.add_child(txt)
 var m=load("res://main.gd").new();m.text_layer=txt;m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame
 m.set_process(false);m.title_open=false;m.lesson_open=false;m.tip_t=0;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.scene="village";m.S={"phase":"idle"};m.V.enter(m)
 var v=m.expedition;var d=v.data;d.restore({});d.souls=[50,50,50,50,50];m.gold=10000
 var unit=d.add_unit(5);v.effect_uid=int(unit.uid)
 for kind in ["alchemy","soldier"]:
  v.opened="alchemy" if kind=="alchemy" else "training";v.effect_kind=kind;v.training_uid=int(unit.uid);unit.level=1;v.effect_pair=[0,1]
  for f in 20:
   v.effect_time=f*.1;m.ui_clock=f*.1;await capture(m,out,kind+"_%02d"%f)
 v.effect_kind="";v.opened="";m.V.shop="forge";m.V.forge_tab="upgrade";m.forge_seen=true
 var e=m.V.enhancement;e.phase="working";e.record={"rod":0,"old":0,"next":1,"success":true,"protected":false}
 for f in 26:
  e.elapsed=f*.1;m.ui_clock=f*.1;await capture(m,out,"rod_%02d"%f)
 e.phase="";m.V.shop=""
 for id in [0,6]:d.add_unit(id)
 d.team=[1,2,3];d.start(1,Time.get_unix_time_from_system());v.opened=""
 for f in 25:
  d.battle.phase="approach";d.battle.phase_time=f*4.0/24;m.ui_clock=f*.16
  await capture(m,out,"pan_%02d"%f)
 for i in 10:
  if not v.textures.has("room%d"%i):continue
  d.battle={};d.unlocked=10;d.recovery_until=0;d.start(i+1,Time.get_unix_time_from_system());d.battle.phase_time=2.0;await capture(m,out,"room_%02d"%(i+1))
 m.audio_feedback.dispose();m.queue_free();await process_frame;ui.queue_free();await process_frame;quit()
