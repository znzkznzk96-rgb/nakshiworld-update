extends SceneTree
func _initialize():call_deferred('run')
func run():
 var out=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 root.content_scale_size=Vector2i(270,660);root.size=Vector2i(810,1980)
 var ui=CanvasLayer.new();root.add_child(ui);var txt=Node2D.new();txt.set_script(load('res://text_layer.gd'));ui.add_child(txt)
 var m=load('res://main.gd').new();m.text_layer=txt;m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 m.title_open=false;m.lesson_open=false;m.tip_t=0;m.trans={};m.TUT.done=true;m.gold=3998;m.souls=15
 m._switch_scene('village');m.V.shop='';m._layout()
 
 var v=m.expedition;var d=v.data;d.restore({});d.soldiers=[];d.team=[]
 for i in 9:
  var u=d.add_unit([0,1,7,5,0,6,14,2,3][i],[3,1,3,3,1,2,2,1,1][i],[0,0,0]);u.level=[0,0,2,0,1,0,2,0,0][i]
  if i<3:d.team.append(u.uid)
 v.open(m,'explore');v.explore_tab=1
 for h in [480,540,660]:
  root.content_scale_size=Vector2i(270,h);root.size=Vector2i(810,h*3);await process_frame;m._layout()
  for modal in [false,true]:
   v.formation_uid=d.soldiers[3].uid if modal else -1;v.formation_target=0
   m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(out.path_join(('compare' if modal else 'basic')+'_%d.png'%h))
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit()
