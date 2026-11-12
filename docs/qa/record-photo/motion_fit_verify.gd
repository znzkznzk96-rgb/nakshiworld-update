extends SceneTree
var failures:Array=[]
func _initialize():call_deferred("run")
func run():
 var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 var d=m.personal_dex;var before:=JSON.stringify(d.serialize())
 var photo=d.photo;var vertices:=0
 for sp in 80:
  var g:Dictionary=photo.measure(m,sp,{"len":28.9},Rect2(0,0,270,270))
  var r:Rect2=g.fish_rect
  for frame in 64:
   for y in 7:
    for x in 15:
     var p:=Vector2(x/14.0,y/6.0)
     var v:Vector2=r.position+p*r.size+photo.motion.offset(sp,p,frame/12.0)*(r.size.x/140)
     if v.x<0 or v.x>270 or v.y<0 or v.y>g.zero.y-5:
      if failures.is_empty():failures.append("source clipping or ruler tick collision %d"%sp)
     vertices+=1
 if JSON.stringify(d.serialize())!=before:failures.append("persistent records changed")
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print("RECORD_MOTION_FIT_VERIFY failures=",failures," deformed_vertices=",vertices," species=80")
 quit(0 if failures.is_empty() else 1)
