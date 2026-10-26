extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(m,out: String,name: String) -> void:
 m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out.path_join(name+".png"))
func run() -> void:
 var out: String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 var layer=CanvasLayer.new();layer.layer=10;root.add_child(layer)
 var txt=Node2D.new();txt.set_script(load("res://text_layer.gd"));layer.add_child(txt)
 var m=load("res://main.gd").new();m.text_layer=txt;root.add_child(m);await process_frame;m.set_process(false)
 m.title_open=false;m.lesson_open=false;m.tip_t=0;m.trans={};m.TUT.done=true;m.scene="village";m.S={"phase":"idle"};m.V.enter(m);m.market_open=false
 var v=m.expedition;var d=v.data;d.restore({});d.souls=[50,50,50,50,50];m.gold=959802
 for id in [5,6,7,4,14,5,6,7,4,14,5,6,7,4,14]:d.add_unit(id,1,[3,4,5])
 d.team=[1,5,2]
 for height in [480,660]:
  root.content_scale_size=Vector2i(270,height);root.size=Vector2i(540,height*2);await process_frame
  v.training_uid=5;v.opened="training";await capture(m,out,"training_%d"%height)
  v.open(m,"explore");v.explore_tab=1;await capture(m,out,"formation_%d"%height)
  v.formation_scroll=v.formation_max_scroll;await capture(m,out,"formation_bottom_%d"%height)
  v.formation_scroll=0;v.role_filter="defense";await capture(m,out,"filter_%d"%height)
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit()
