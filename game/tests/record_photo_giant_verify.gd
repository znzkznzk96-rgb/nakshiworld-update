extends SceneTree
var failures:Array=[]
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 if not ok and not label in failures:failures.append(label)
func run():
 var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 var photo=m.personal_dex.photo;var saved:=JSON.stringify(m.personal_dex.serialize());var vertices:=0
 var area:=Rect2(0,0,270,270)
 for sp in 80:
  for length in [8.9,60.0,61.0,120.0,240.0,9999.0]:
   var g:Dictionary=photo.measure(m,sp,{"len":length},area)
   var original:Rect2=g.source.source
   check(absf(g.fish_rect.size.aspect()-original.size.aspect())<.001,"preserve source aspect")
   for intro in [0.0,.5,1.0]:
    var zoom:float=photo.camera_zoom({"len":length},intro)
    var view:Dictionary=photo.camera_geometry(g,area,zoom)
    for frame in 12:
     for y in 7:
      for x in 15:
       var p:=Vector2(x/14.0,y/6.0)
       var v:Vector2=view.fish_rect.position+p*view.fish_rect.size+photo.motion.offset(sp,p,frame/9.0)*(view.fish_rect.size.x/140)
       check(v.x>=2 and v.x<=268 and v.y>=36 and v.y<=263,"full moving silhouette clears UI")
       vertices+=1
   if length>=240:
    check(g.fish_rect.size.x>area.size.x*.655 or g.fish_rect.size.y>area.size.y*.31,"giant exceeds mat")
    check(photo.camera_zoom({"len":length},0)>photo.camera_zoom({"len":length},1),"camera retreats")
 check(photo.giant_amount({})==0,"legacy length not invented")
 check(photo.camera_zoom({"len":9999},-1)==1,"export uses completed camera")
 check(JSON.stringify(m.personal_dex.serialize())==saved,"records unchanged")
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print("RECORD_PHOTO_GIANT_VERIFY failures=",failures," vertices=",vertices," species=80")
 quit(0 if failures.is_empty() else 1)
