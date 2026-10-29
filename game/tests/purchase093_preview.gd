extends SceneTree
var failures=[]
func check(ok,label):
 if not ok: failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func capture(m,out,name):
 m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out.path_join(name+".png"))
func run():
 var out=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 var ui=CanvasLayer.new();root.add_child(ui);var txt=Node2D.new();txt.set_script(load("res://text_layer.gd"));ui.add_child(txt)
 var m=load("res://main.gd").new();m.text_layer=txt;m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 m.title_open=false;m.lesson_open=false;m.tip_t=0;m.trans={};m.TUT.done=true;m.pearl=0;m.expedition.data.restore({})
 for h in [480,660]:
  root.content_scale_size=Vector2i(270,h);root.size=Vector2i(540,h*2);await process_frame;m._layout();m._switch_scene("village");m.V.shop="up";m.V.tab="pouches"
  for gold in [237,1000]:
   m.gold=gold;m.V.commerce.request(m.V,m,"soul_pouch:1");m.ui_commands=[];m.V.commerce.draw(m.V,m,h)
   var found=false
   for c in m.ui_commands:
    if c[0]=="texture" and c[1]==m.V.commerce.pending.icon:
     found=true;check(c[2].size.x<=96 and c[2].size.y<=64,"pouch contained")
     check(m.V.commerce.rects.panel.encloses(c[2]),"pouch inside modal")
   check(found,"pouch rendered")
   check((m.V.commerce.rects.buy.size!=Vector2.ZERO)==(gold>=500),"affordability unchanged")
   await capture(m,out,"purchase_%d_%d"%[h,gold])
  m.V.commerce.pending={};m.V.shop="";m._switch_scene("fish");m.S={"phase":"idle"};m.region_shop.selected_bait=-1
  m.ui_commands=[];m.bait_picker.draw_button(m,h-108-m.bot_pad)
  for c in m.ui_commands:
   if c[0]=="texture":check(c[1]!=m.icons.hook,"no duplicate hook")
  await capture(m,out,"empty_%d"%h)
 m.audio_feedback.dispose();m.queue_free();await process_frame;print("PURCHASE093 failures=",failures);quit(0 if failures.is_empty() else 1)
