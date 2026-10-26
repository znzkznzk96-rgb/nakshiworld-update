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
 var v=m.expedition;var d=v.data
 d.soldiers=[];d.team=[];d.battle={};d.pending={};d.recovery_until=0;d.unlocked=2
 for id in [3,1,7]:
  var u=d.add_unit(id,1,[4,4,4]);d.team.append(u.uid)
 d.start(2,1000);d.battle.index=2;d.spawn_enemy()
 for height in [480,660]:
  root.content_scale_size=Vector2i(270,height);root.size=Vector2i(540,height*2);await process_frame
  v.opened=""
  await capture(m,out,"stage_1_2_encounter_3_%d"%height)
 m.audio_feedback.dispose();m.queue_free();await process_frame;layer.queue_free();await process_frame
 print("EXPEDITION_LABEL_PREVIEW complete");quit()
