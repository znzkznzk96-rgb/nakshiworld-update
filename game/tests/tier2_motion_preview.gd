extends SceneTree
func _initialize():call_deferred('run')
func snap(m,out,name):
 m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out.path_join(name+'.png'))
func run():
 var out=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 var ui=CanvasLayer.new();root.add_child(ui);var txt=Node2D.new();txt.set_script(load('res://text_layer.gd'));ui.add_child(txt)
 var m=load('res://main.gd').new();m.text_layer=txt;m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 m.title_open=false;m.lesson_open=false;m.tip_t=0;m.trans={};m.TUT.done=true;m.gold=5000;m.expedition.data.restore({})
 var v=m.expedition;var d=v.data
 d.restore({});d.souls=[30,30,30,30,30]
 for i in 15:
  var u=d.add_unit(i,2,[1,2,3]);u.level=3 if i<2 else 0
 d.team=[d.soldiers[4].uid,d.soldiers[5].uid,d.soldiers[6].uid]
 for h in [480,540,660]:
  root.content_scale_size=Vector2i(270,h);root.size=Vector2i(810,h*3);await process_frame;await process_frame;await process_frame;m._layout();m._switch_scene('village');m.V.shop=''
  v.open(m,'alchemy');v.tab=0;v.pair=[2,2];await snap(m,out,'craft_%d'%h)
  v.tab=1;v.selected=[d.soldiers[0].uid,d.soldiers[1].uid];await snap(m,out,'merge_%d'%h)
  v.tab=2;await snap(m,out,'roster_%d'%h)
  v.opened='management';v.management.uid=d.soldiers[2].uid;v.management.confirm=false;await snap(m,out,'detail_%d'%h)
  v.management.confirm=true;await snap(m,out,'salvage_%d'%h)
  v.opened='alchemy';d.pending={'kind':'craft','uid':d.soldiers[2].uid};await snap(m,out,'result_%d'%h);d.pending={}
  v.open(m,'explore');v.explore_tab=1;v.formation_uid=d.soldiers[0].uid;v.formation_target=0;await snap(m,out,'formation_%d'%h)
 v.opened='explore';v.explore_tab=0
 for group in 5:
  d.team=[]
  for j in 3:d.team.append(d.soldiers[group*3+j].uid)
  d.battle={};d.recovery_until=0;d.start(1,Time.get_unix_time_from_system())
  d.battle.phase='fight';d.battle.phase_time=0;d.battle.fx={}
  for step in [0,6,8,14]:
   d.battle.clock=step/10.0
   await snap(m,out,'battle_%d_%02d'%[group,step])
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit()
