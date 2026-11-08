extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String):
 if not ok: failures.append(label)
func _initialize():call_deferred("run")
func capture(path:String):
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(path)
func run():
 var args=OS.get_cmdline_user_args();var out:String=args[0];var before:bool=args.size()>1 and args[1]=="before"
 DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_size=Vector2i(270,540);root.size=Vector2i(810,1620)
 var app=load("res://tests/valley_native_root.gd").new();root.add_child(app);app._start()
 var m=app.box.get_child(0).get_child(0);m.development_preview=true;m.SET.sfx=0;m.SET.music=0;m.set_process(false)
 m.title_open=false;m.lesson_open=false;m.trans={};m.TUT.done=true;m.tip_t=0;m.toast_t=0;m.judge_t=0;m.S={"phase":"idle"}
 m.progression.restore({});m.region_shop.unlocked=[0,1,2];m.progression.bundle_values={"0:2":17600}
 m._switch_scene("village");m.V.open_shop(m,"museum")
 var cases=[[0,2,"reservoir_owner",5940],[1,1,"valley_sub",31200],[1,2,"valley_owner",93600]]
 for item in cases:
  m.V.bundle_preview.region=item[0];m.V.bundle_preview.tab=item[1];m.queue_redraw()
  await capture(out.path_join(item[2]+".png"))
  if not before:check(m.V.bundle_preview.reward_preview_amount(m,item[0],item[1])==item[3],"exact displayed payout "+item[2])
 m.V.shop="";m._switch_scene("spots");m.spots.index=2;m.spots.scroll=2;m.spots.shift=0;m.queue_redraw()
 await capture(out.path_join("selection.png"))
 if not before:check(m.spots.images[2].resource_path=="res://art/refresh53/tile_sea.png","legacy selection")
 m.active_region=2;m._layout();m._switch_scene("fish");m.queue_redraw();await process_frame
 check(m.environment.tile.plate.texture.resource_path=="res://art/bg/tile_sea_approved_20261107.png","fishing background retained")
 m.audio_feedback.dispose();app.queue_free();await process_frame
 print("BUNDLE_NEXT_UNLOCK_NATIVE_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
