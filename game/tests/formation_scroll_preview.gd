extends SceneTree
var failures:Array=[]
func _initialize() -> void: call_deferred("run")
func capture(m,out: String,name: String) -> Image:
 m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
 var image:Image=root.get_texture().get_image()
 image.save_png(out.path_join(name+".png"));return image
func run() -> void:
 var out: String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 var layer=CanvasLayer.new();layer.layer=10;root.add_child(layer)
 var txt=Node2D.new();txt.set_script(load("res://text_layer.gd"));layer.add_child(txt)
 var m=load("res://main.gd").new();m.text_layer=txt;m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 m.title_open=false;m.lesson_open=false;m.tip_t=0;m.trans={};m.TUT.done=true;m.scene="village";m.S={"phase":"idle"};m.V.enter(m);m.market_open=false
 var v=m.expedition;var d=v.data;d.restore({});d.souls=[50,50,50,50,50];m.gold=959802
 for id in [5,6,7,4,14,5,6,7,4,14,5,6,7,4,14]:d.add_unit(id,1,[3,4,5])
 d.team=[1,5,2]
 for height in [480,540,660]:
  root.content_scale_size=Vector2i(270,height);root.size=Vector2i(540,height*2);await process_frame
  v.training_uid=5;v.opened="training";await capture(m,out,"training_%d"%height)
  v.open(m,"explore");v.explore_tab=1;await capture(m,out,"formation_%d"%height)
  var base:Image=root.get_texture().get_image()
  var area:Rect2=v.formation_viewport
  for offset in [1,33,47,69,70,71]:
   v.formation_scroll=offset
   var image:Image=await capture(m,out,"formation_h%d_scroll%d"%[height,offset])
   for edge in [area.position.y-8,area.end.y]:
    var band:=Rect2i(int(area.position.x*2),int(edge*2),int(area.size.x*2),16)
    if base.get_region(band).get_data()!=image.get_region(band).get_data():failures.append("clip bleed h%d offset%d edge%s"%[height,offset,edge])
  v.formation_scroll=v.formation_max_scroll;await capture(m,out,"formation_bottom_%d"%height)
  v.formation_scroll=0;v.role_filter="defense";await capture(m,out,"filter_%d"%height)
 v=null;d=null;m.audio_feedback.dispose();m.queue_free();await process_frame
 print("FORMATION_SCROLL_PREVIEW failures=",failures);quit(0 if failures.is_empty() else 1)
