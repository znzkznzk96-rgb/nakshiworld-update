extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String):
 if not ok:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 var m=load("res://main.gd").new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 m.title_open=false;m.trans={};m.TUT.done=true;m.lesson_open=false;m.scene="village";m.V.shop=""
 var g=m.guide;var count:=0
 for h in [480,540,660]:
  root.content_scale_size=Vector2i(270,h);root.size=Vector2i(540,h*2);await process_frame;m._layout();g.open_home();g.draw(m,h)
  check(g.rects.tabs.size()==8,"eight large home cards")
  for i in 8:
   var b: Rect2=g.rects.tabs[i];check(b.size.x>=100 and b.size.y>=50,"roomy home card")
   check(b.end.y<h-55,"home leaves bottom breathing room")
   for j in range(i+1,8):check(not b.intersects(g.rects.tabs[j]),"home targets do not overlap")
  for pair in g.text_boxes:
   var b: Rect2=pair[0]
   for card in g.rects.tabs:
    if card.has_point(b.position):check(card.encloses(b),"home label and subtitle stay within card")
  g.press(m,g.rects.quick.get_center());check(g.screen=="article" and g.tab==0 and g.topic==0,"home shortcut opens basics")
  for tab in 8:
   g.tab=tab;g.change_screen("topics");g.draw(m,h);check(g.rects.topics.size()==g.TOPICS[tab].size(),"all topic rows reachable")
   for topic in g.TOPICS[tab].size():
    g.topic=topic;g.change_screen("article");g.draw(m,h);count+=1
    check(is_equal_approx(g.maximum(),maxf(0,g.content_height-g.viewport.size.y)),"scroll range matches content")
    var all_text:=""
    for item in g.body_text:all_text+=str(item[2])
    var compact: String=all_text.replace(" ","").replace("\n","")
    for line in g.content(m):check(str(line).replace(" ","").replace("\n","") in compact,"all current guide explanations preserved")
    for pair in g.text_boxes:
     var box: Rect2=pair[0];check(box.position.x>=24 and box.end.x<=246,"text width bounded inside content cards")
    var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_WHEEL_DOWN;e.pressed=true;e.position=g.viewport.get_center()+Vector2(m.ox,0);g.input_event(m,e);check(g.scroll>0 if g.maximum()>0 else g.scroll==0,"wheel scrolls long detail and keeps short detail fixed")
    g.scroll=g.maximum();g.draw(m,h);check(g.rects.links[-1][0].end.y<=g.viewport.end.y,"footer reachable within viewport")
   g.change_screen("home");g.draw(m,h)
  g.tab=0;g.topic=1;g.change_screen("article");g.draw(m,h)
  var t=InputEventScreenTouch.new();t.index=0;t.pressed=true;t.position=g.viewport.get_center()+Vector2(m.ox,0);g.input_event(m,t)
  var d=InputEventScreenDrag.new();d.index=0;d.position=t.position-Vector2(0,60);g.input_event(m,d);t.pressed=false;t.position=d.position;g.input_event(m,t)
  check(g.scroll>0 and g.screen=="article","native drag scrolls without selecting or closing")
  g.press(m,g.rects.back.get_center());check(g.screen=="topics" and g.scroll==0,"back resets scroll and returns to topics")
  g.draw(m,h);g.press(m,g.rects.close.get_center());check(not g.opened,"close remains available")
 # A real release event selects; emulated touch mouse events never duplicate it.
 g.open_home();g.draw(m,660)
 var click=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.position=g.rects.tabs[5].get_center()+Vector2(m.ox,0);click.pressed=true;g.input_event(m,click)
 check(g.screen=="home","press does not prematurely select")
 click.pressed=false;g.input_event(m,click);check(g.tab==5 and g.screen=="topics","release selects one menu")
 click.device=-1;click.pressed=true;g.input_event(m,click);check(g.screen=="topics","synthetic mouse ignored")
 g.opened=false;g.sync_layer();check(not is_instance_valid(g.clip_root) or not g.clip_root.visible,"closed article layer hidden")
 print("GUIDE_AC_VERIFY failures=",failures," articles=",count)
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
