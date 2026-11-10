extends SceneTree
var failures:Array=[]
var cases:=0
func check(ok:bool,label:String)->void:
 if not ok:failures.append(label);push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 var m=load("res://main.gd").new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false;m.scene="village";m.S={"phase":"idle"};m.trans={};m.TUT.done=true;m.tip_t=0;m.V.shop=""
 var saved:Dictionary=m.expedition.data.serialize().duplicate(true);var gold:int=m.gold
 for h in [480,660,740]:
  root.content_scale_size=Vector2i(270,h);root.size=Vector2i(270,h);await process_frame;m._layout()
  var r:Rect2=m._village_toast_rect()
  check(r.position.y>=m.top_y+146,"notice below top strip")
  check(r.end.y<h-m.bot_pad-117,"notice above browse instruction and controls")
  for zoom in [.65,1.0,1.6]:
   m.V.zoom=zoom
   for camera in [0,434,795,1024,1495]:
    m.V.camera_x=camera;var origin:Vector2=m.V.map_origin(m,h)
    for b in m.V.BUILD:
     var center:Vector2=origin+b[3]
     var w:float=maxf(54,m._text_w(b[0],10)+16) if b[1]!="harbor" else 92.0
     var world:Rect2=Rect2(center-Vector2(w/2,10),Vector2(w,23))
     var anchor:=Vector2(135,origin.y)
     var sign_rect:=Rect2(anchor+(world.position-anchor)*zoom,world.size*zoom)
     check(not r.intersects(sign_rect),"reward avoids transformed sign");cases+=1
  m.show_toast("260 비늘 · 어혼 주머니 2개 획득",Color("ffdc96"))
  check(m.toast_t==1.2 and not m.toast_action,"reward duration preserved")
 check(m.gold==gold and m.expedition.data.serialize()==saved,"layout leaves reward and save untouched")
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print("VILLAGE_REWARD_NOTICE_VERIFY failures=",failures," sign_cases=",cases);quit(0 if failures.is_empty() else 1)
