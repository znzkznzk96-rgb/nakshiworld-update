extends SceneTree
var output:String
func _initialize():call_deferred('run')
func run():
 output=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(output)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
 var txt:=Node2D.new();txt.set_script(load('res://text_layer.gd'));ui.add_child(txt)
 var m=load('res://main.gd').new();m.text_layer=txt;m.SET.music=0;m.SET.sfx=0;root.add_child(m);await process_frame;m.set_process(false)
 m.title_open=false;m.title_screen.leaving=false;m.title_screen.root.hide();m.lesson_open=false;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.tip_t=0
 root.content_scale_size=Vector2i(270,660);root.size=Vector2i(810,1980);await process_frame
 m._switch_scene('village');m.trans={};m.V.ferry_clock=8;m.V.visitors.motion_rng.seed=131
 for x in [0,360,900]:
  m.V.camera_x=x
  for frame in 40:
   m.V.town_time=frame/10.0;m.V.ferry_clock=8
   m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(output.path_join('village-%d-%02d.png'%[x,frame]))
 m.V.visitors.hide_all(m.V.res+m.V.locals);m.audio_feedback.dispose();m.queue_free();await process_frame
 print('VILLAGE_LAYERS_QUALITY_PREVIEW screens=120');quit()
