extends SceneTree
func _initialize():call_deferred('run')
func snap(m,path):
 m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(path)
func run():
 var out=OS.get_cmdline_user_args()[0]
 DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 root.content_scale_size=Vector2i(270,540);root.size=Vector2i(810,1620)
 var ui=CanvasLayer.new();root.add_child(ui);var txt=Node2D.new();txt.set_script(load('res://text_layer.gd'));ui.add_child(txt)
 var m=load('res://main.gd').new();m.text_layer=txt;m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 m.title_open=false;m.lesson_open=false;m.tip_t=0;m.trans={};m.TUT.done=true;m.gold=5000;m.expedition.data.restore({});m._layout();m._switch_scene('village');m.V.shop=''
 var v=m.expedition;var d=v.data
 for star in [1,2,3]:
  d.restore({});var u=d.add_unit(0,star,[4,4,4]);v.open(m,'alchemy');v.opened='management';v.management.uid=u.uid;v.management.confirm=false
  await snap(m,out+'/tier%d-detail.png'%star)
 d.restore({})
 for id in [3,0,7]:d.team.append(d.add_unit(id,3,[4,4,4]).uid)
 d.start(1,1000);d.battle.enemy.hp=100000;d.battle.enemy.max_hp=100000;d.battle.phase='fight'
 for n in 42:d.update(.1,1000+n*.1)
 v.open(m,'explore');v.explore_tab=0;await snap(m,out+'/battle.png')
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit()
