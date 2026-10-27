extends SceneTree
func _initialize() -> void:call_deferred("run")
func capture(m,out: String,name: String) -> void:
 m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out.path_join(name+".png"))
func run() -> void:
 var out: String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_size=Vector2i(270,540);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.size=Vector2i(540,1080)
 var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
 var txt:=Node2D.new();txt.set_script(load("res://text_layer.gd"));ui.add_child(txt)
 var m=load("res://main.gd").new();m.text_layer=txt;m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame
 m.development_preview=true;m.set_process(false);m.title_open=false;m.lesson_open=false;m.tip_t=0;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.scene="village";m.S={"phase":"idle"};m.V.enter(m)
 var d=m.personal_dex;m.expedition.data.restore({})
 for id in [0,2,4,5,6,7,12,14]:m.expedition.data.discover(id)
 d.restore({});m.DEX={m.fish_key(1):[0,1]};m.REC={m.fish_key(1):26.0};d.observe(1,0,24.9,.078,"")
 for h in [480,660]:
  root.content_scale_size=Vector2i(270,h);root.size=Vector2i(540,h*2);await process_frame;m._layout()
  d.open(m);d.region=2;await capture(m,out,"soldiers_%d"%h)
  d.scroll=104;await capture(m,out,"soldiers_scroll_%d"%h)
  d.selected=6;await capture(m,out,"soldier_detail_%d"%h)
  d.selected=-1;d.region=0;d.scroll=0;await capture(m,out,"fish_list_%d"%h)
  d.selected=1;await capture(m,out,"fish_detail_%d"%h)
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit()
