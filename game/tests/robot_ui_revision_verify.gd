extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String):
 if not ok: failures.append(label);push_error(label)
func _initialize(): call_deferred('run')
func run():
 var m=load('res://main.gd').new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.development_preview=true
 var b=m.capture_robot;b.owned=true;b.enabled=true;m.scene='fish';m.S.phase='idle';m.market_open=false;m.menu_open=false;m.settings_open=false
 var saved=b.serialize()
 for key in ['sleep','capture','success','full','speed','storage','precision']:
  var tex=b.icon_art.icon(key)
  check(tex.get_width()>=90 and tex.get_height()>=88,'master resolution preserved '+key)
  check(tex.get_image().get_pixel(0,0).a==0,'edge background transparent '+key)
 for h in [480,540,660]:
  var r=Rect2(8,110,254,h-122)
  for tab in 3:
   b.shop_tab=tab;m.V.rects.rows=[];m.ui_commands=[];b.draw_shop(m,r,191)
   for key in b.visual_bounds: check(r.encloses(b.visual_bounds[key]),'panel contains '+str(h)+' '+key)
   for i in 3: check(b.visual_bounds['tab_%d'%i].grow(-4).encloses(b.visual_bounds['tab_icon_%d'%i]),'icon margin '+str(h))
   for row in m.V.rects.rows: check(r.encloses(row[0]),'touch target fits')
   for c in m.ui_commands:
    if c[0]=='texture':check(c[1]!=b.WORKSHOP,'workshop tiling removed')
 for state in 5:
  b.enabled=state!=0;b.job={};b.flash=0;b.fish=[]
  if state==2:b.job=b.make_fish(m)
  if state==3:b.flash=1.0
  if state==4:
   for j in 20:b.fish.append(b.make_fish(m))
  for frame in 12:
   b.visual_time=frame*.3;m.ui_commands=[];b.draw_surface(m)
   var box: Rect2=b.surface_layout(m).bubble
   check(box.position.x>=0 and box.end.x<=270,'bubble stays on screen')
   for c in m.ui_commands:
    if c[0]=='texture':check(box.grow(-2).encloses(c[2]),'state icon enclosed with motion '+str(state))
 b.restore(saved);check(b.serialize()==saved,'save unchanged after UI')
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print('ROBOT_UI_REVISION_VERIFY failures=',failures);quit(0 if failures.is_empty() else 1)
