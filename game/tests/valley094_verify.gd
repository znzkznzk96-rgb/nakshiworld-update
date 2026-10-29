extends SceneTree
var failures=[]
func check(ok,label):
 if not ok:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 var m=load("res://main.gd").new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 m.title_open=false;m.lesson_open=false;m.trans={};m.active_region=1;m._layout();m._switch_scene("fish")
 var v=m.environment.valley
 var life=v.layers.life
 check(life.SPECIES==[20,21,28] and life.fish.size()==3,"exactly three approved valley decorative species")
 check(life.runs.size()==9 and life.idles.size()==5,"real PixelLab motion frames available")
 for tex in life.runs+life.idles:check(tex!=null and tex.get_size()==Vector2(64,64),"original deer frame resolution preserved")
 var before=[m.gold,m.bag.duplicate(true)]
 for i in 440:
  var t: float=i/20.0
  var state=life.deer_state(t)
  if state.visible:
   check(state.x>=93 and state.x<=129,"deer stays on safe ledge")
   if fposmod(t+1,22)>=9:check(state.facing==-1 and state.moving,"deer faces back on exit")
 for i in range(1,80):
  var enter=life.deer_state(i/20.0-1)
  var leave=life.deer_state(12-i/20.0)
  check(is_equal_approx(enter.x,leave.x) and is_equal_approx(enter.y,leave.y),"return exactly retraces ledge")
 for h in [480,660]:
  root.content_scale_size=Vector2i(270,h);await process_frame;m._layout()
  check(v.map_rect.has_area(),"valid plate coordinate mapping")
  v.elapsed=9.2;v.update(0.016);life.queue_redraw();await process_frame
 check(m.gold==before[0] and m.bag==before[1],"decorations never change currency or inventory")
 m.active_region=0;m._layout();m.environment.show_scene(true);check(not v.root.visible,"wildlife hidden outside valley")
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print("VALLEY094_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
