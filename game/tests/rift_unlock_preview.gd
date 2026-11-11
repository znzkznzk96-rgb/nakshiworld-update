extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String)->void:
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func capture(path:String)->void:
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(path)
func run():
 var out:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
 var text:=Node2D.new();text.set_script(load("res://text_layer.gd"));ui.add_child(text)
 var m=load("res://main.gd").new();m.text_layer=text;m.SET.music=0;m.SET.sfx=0;root.add_child(m);await process_frame;m.set_process(false)
 m.title_open=false;m.title_screen.leaving=false;m.title_screen.root.hide();m.lesson_open=false;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.tip_t=0
 m.region_shop.unlocked=[0,1,2];m.progression.restore({"main_completed":[true,true,true],"certificates":[true,true,true]});m.gold=4635000
 m.spots.index=3;m.spots.scroll=3;m.spots.shift=0
 var renders:int=0
 for h in [480,540,660]:
  root.content_scale_size=Vector2i(270,h);root.size=Vector2i(540,h*2);await process_frame
  m._switch_scene("spots");m.trans={};m.queue_redraw();await capture(out.path_join("unlock-%d.png"%h));renders+=1
  if not m.region_shop.is_unlocked(3):
   m.spots.press(m,m.spots.rects.enter.get_center());m.trans={}
   check(m.region_shop.is_unlocked(3) and m.active_region==3,"real button entered")
  m._switch_scene("fish");m.trans={};m.active_region=3;m._layout();m.equipment.active_parts=["r3_float","r3_hook","r3_line","r3_reel"]
  for sp in [60,73,79]:
   m.S={"sp":sp,"star":4 if sp==79 else 0,"grade":2,"lf":1.0,"len":float(m.FISH_LEN[sp]),"owner":sp==79};m.start_fight();m.S.t=2;m.S.bt=99;m.queue_redraw();await capture(out.path_join("fight-%d-%d.png"%[h,sp]));renders+=1
   check(m.environment.rift.root.visible,"rift environment active")
  m._switch_scene("village");m.V.open_shop(m,"museum");m.V.bundle_preview.region=2;m.V.bundle_preview.tab=0;m.queue_redraw();await capture(out.path_join("tile-complete-%d.png"%h));renders+=1
  check(m.progression.bundle_counts(2,0)==[1,1,1,1,1,1],"tile completed slots preserved")
  m.V.shop=""
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print("RIFT_UNLOCK_PREVIEW failures=",JSON.stringify(failures)," renders=",renders);quit(0 if failures.is_empty() else 1)
