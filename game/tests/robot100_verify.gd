extends SceneTree
var failures:Array=[]
func check(ok:bool,msg:String):
 if not ok:failures.append(msg);push_error(msg)
func _initialize():call_deferred('run')
func run():
 var m=load('res://main.gd').new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 var b=m.capture_robot
 for key in ['sleep','capture','success','full']:
  for frame in 2:
   m.ui_commands=[];b.micro_icons.draw(m,key,Vector2.ZERO,frame)
   for c in m.ui_commands:
    check(c[0]=='rect','native icon uses only pixel rectangles')
    check(Rect2(0,0,28,17).encloses(c[1]),'native icon bounds '+key)
    check(c[1].position==c[1].position.round() and c[1].size==c[1].size.round(),'integer pixel placement')
 for t in [0.0,.4,1.6,3.0]:
  b.visual_time=t;var layout=b.surface_layout(m)
  check(layout.bubble.size.x<=layout.robot.size.x and layout.bubble.size.y<=layout.robot.size.y,'bubble no larger than robot')
 b.owned=true;b.enabled=true;m.scene="fish";m.market_open=false;m.menu_open=false;m.settings_open=false
 for phase in ['idle','cast','wait','hook','pre','fight','catch']:
  m.S.phase=phase;m.ui_commands=[];m.text_items=[];b.draw_surface(m)
  check(not m.ui_commands.is_empty(),'robot stays visible '+phase)
  var alpha:float=m.ui_commands[0][4].a
  check(is_equal_approx(alpha,0.28 if phase in ['hook','pre','fight','catch'] else 1.0),'phase opacity '+phase)
  if phase in ['hook','pre','fight','catch']:check(b.button.size==Vector2.ZERO,'no robot tap interception '+phase)
 for h in [480,540,660]:
  m.text_items=[];m.ui_commands=[];b.opened=true
  var r:=Rect2(16,maxf(80,(h-250)/2.0),238,250)
  m._text('UNDERLAY',r.get_center(),12,Color.WHITE)
  m._text('HUD',Vector2(20,30),12,Color.WHITE)
  b.draw_panel(m,h)
  var labels:Array=m.text_items.map(func(i):return i[2])
  check(not 'UNDERLAY' in labels and 'HUD' in labels,'modal suppresses underlying labels but keeps HUD')
  check('모두 받기' in labels,'modal own label retained')
  for button in b.rects.values():check(r.encloses(button),'modal button fits')
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print('ROBOT100_VERIFY failures=',failures);quit(0 if failures.is_empty() else 1)
