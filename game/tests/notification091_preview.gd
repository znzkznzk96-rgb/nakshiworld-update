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
 m.title_open=false;m.lesson_open=false;m.tip_t=0;m.trans={};m.TUT.done=true;m.gold=10000;m.pearl=2;m.expedition.data.restore({});m.region_shop.restore({})
 for h in [480,660]:
  root.content_scale_size=Vector2i(270,h);root.size=Vector2i(540,h*2);await process_frame
  m.scene="village";m.S={"phase":"idle"};m.V.enter(m);m._layout();m.expedition.data.battle={};m.V.open_shop(m,"up");m.V.tab="bait"
  m.V.commerce.request(m.V,m,"bait:0:5");m.V.commerce.confirm(m.V,m);await capture(m,out,"purchase_%d"%h)
  m.V.commerce.report(m,"판매 완료 · +120 비늘",120);m.V.shop="";await capture(m,out,"closed_sale_%d"%h)
  m.V.commerce.notice="";m.scene="fish";m.active_region=0;m._layout();m.environment.show_scene(true);m.equipment.active_parts=["float","hook","line","reel"];m.progression.owner_gauge[0]=9;m.S={"phase":"idle"}
  m.expedition.data.battle={"status":"win","round":1,"progress":100};m.expedition.result_notice=6;await capture(m,out,"owner_complete_%d"%h)
  m.equipment.active_parts=[];await capture(m,out,"no_owner_complete_%d"%h)
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit()
