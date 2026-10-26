extends SceneTree
func _initialize() -> void: call_deferred("run")
func fish(sp: int) -> Dictionary: return {"sp":sp,"grade":0,"star":0,"len":23.5,"w":0.01,"price":100}
func capture(m,out: String,name: String) -> void:
 m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out.path_join(name+".png"))
func run() -> void:
 var out: String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 var layer:=CanvasLayer.new();layer.layer=10;root.add_child(layer)
 var txt:=Node2D.new();txt.set_script(load("res://text_layer.gd"));layer.add_child(txt)
 var m=load("res://main.gd").new();m.text_layer=txt;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame
 m.set_process(false);m.title_open=false;m.lesson_open=false;m.tip_t=0;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.scene="village";m.S={"phase":"idle"};m.V.enter(m)
 var p=m.progression;var v=m.V;var u=v.bundle_preview
 for height in [480,660]:
  root.content_scale_size=Vector2i(270,height);root.size=Vector2i(540,height*2);await process_frame
  p.restore({});m.bag=[];m.gold=0;m.souls=0;m.pearl=0
  for sp in p.SUB_SPECIES[0]:m.bag.append(fish(sp))
  v.open_shop(m,"museum");u.region=0;u.tab=1
  await capture(m,out,"bundle_%d"%height)
  u.press(m,u.rects.register.get_center());await capture(m,out,"donate_preview_%d"%height)
  u.press(m,u.rects.bulk_confirm.get_center());await capture(m,out,"reward_pending_%d"%height)
  u.press(m,u.rects.claim.get_center());await capture(m,out,"reward_received_%d"%height)
  p.restore({"main_completed":[true],"certificates":[false]});v.open_shop(m,"museum");u.tab=0;u.reward_open=true
  await capture(m,out,"license_pending_%d"%height)
  u.press(m,u.rects.claim.get_center());await capture(m,out,"license_received_%d"%height)
  v.open_shop(m,"aqua");v.aquarium.act(v,m,"amanage");m.bag=[];m.aqua=[null,null,null]
  for i in 20:m.bag.append(fish(i))
  await capture(m,out,"aquarium_top_%d"%height)
  v.aquarium.scroll=v.aquarium.maximum();await capture(m,out,"aquarium_bottom_%d"%height)
  v.aquarium.act(v,m,"put:19");await capture(m,out,"aquarium_inserted_%d"%height)
 m.audio_feedback.dispose();m.queue_free();await process_frame;layer.queue_free();await process_frame
 print("BUNDLE_AQUA_PREVIEW complete");quit()
