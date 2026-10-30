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
 var b=m.capture_robot;b.owned=true;b.enabled=true
 for h in [480,540,660]:
  root.content_scale_size=Vector2i(270,h);root.size=Vector2i(540,h*2);await process_frame;m._layout();m._switch_scene('village');m.V.shop='forge';m.V.forge_tab='robot'
  for tab in 3:
   b.shop_tab=tab;await snap(m,out,'shop_%d_%d'%[h,tab])
 root.content_scale_size=Vector2i(270,660);root.size=Vector2i(540,1320);await process_frame;m._layout();m.V.shop='';m._switch_scene('fish');m._layout()
 for i in 40:
  b.visual_time=i*.12;b.flash=0;b.job={};b.fish=[]
  if i>=10 and i<20:b.job=b.make_fish(m)
  if i>=20 and i<30:b.flash=2-(i-20)*.12;b.fish=[b.make_fish(m)]
  if i>=30:
   for j in 20:b.fish.append(b.make_fish(m))
  await snap(m,out,'motion_%02d'%i)
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit()
