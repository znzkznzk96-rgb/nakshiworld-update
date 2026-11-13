extends SceneTree
class FakeGallery extends RefCounted:
 var photo
 var mode:="success"
 var calls:=0
 var saw_busy:=true
 func save(_image,_filename):
  calls+=1;saw_busy=photo.busy
  if mode=="empty":return null
  return {"ok":mode=="success","message":"갤러리에 저장했어요" if mode=="success" else "저장 실패"}
var failures:Array=[]
func check(ok:bool,label:String):
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 var p=m.personal_dex.photo;var saved:=JSON.stringify(m.personal_dex.serialize())
 var gallery:=FakeGallery.new();gallery.photo=p;p.gallery=gallery
 var im:=Image.create(2,2,false,Image.FORMAT_RGBA8)
 for mode in ["success","failure","empty"]:
  gallery.mode=mode;p.busy=true;p.status="사진을 만들고 있어요"
  p.complete_image(m,im,"fixture.png",p.generation)
  check(not p.busy and not gallery.saw_busy,"native save boundary cannot leave waiting state")
  check(p.status!="사진을 만들고 있어요","pending text cleared on every outcome")
  if mode=="success":check(p.status=="갤러리에 저장했어요","completed save reports success")
 var calls:=gallery.calls;p.busy=true;p.complete_image(m,im,"stale.png",p.generation-1)
 check(gallery.calls==calls and not p.busy,"stale export never saved to new record")
 for sp in 80:
  var g:Dictionary=p.measure(m,sp,{"len":8.9},Rect2(0,0,240,240))
  for label in p.ruler_numbers(m,g):
   check(label.bounds.position.x>=g.zero.x and label.bounds.end.x<=g.zero.x+g.width,"end labels remain inside paper band")
 var motion=p.motion
 var active:=0;var peak:=0.0
 for frame in 600:
  var a:float=motion.strength(0,frame/100.0);peak=maxf(peak,a)
  if a>.2:active+=1
 check(peak>1.9 and active>350,"six-second intro repeatedly stronger")
 for sp in 80:
  for frame in 64:
   var t:=6.0+frame/12.0
   check(is_equal_approx(motion.strength(sp,t),motion.periodic_strength(sp,t)),"post-intro exact previous cadence")
 check(motion.offset(0,Vector2(.9,.2),-1)==Vector2.ZERO,"export pose remains static")
 var title=m.title_screen
 check(title.STRIKES==[.4,.75,1.2],"three earlier lightning beats")
 check(not title.button_enabled(1.199) and title.button_enabled(1.2),"start enabled exactly on final strike")
 for t in [.4,.75,1.2]:check(title.flash_at(t).pulse>.1,"lightning fires at each beat")
 title.rects.start=Rect2(49,400,172,34);m.title_open=true;title.elapsed=1.19
 title.press(m,Vector2(130,410));check(m.title_open,"early taps ignored")
 title.elapsed=1.2;title.press(m,Vector2(130,410));check(not m.title_open,"final beat permits start")
 check(JSON.stringify(m.personal_dex.serialize())==saved,"records unchanged")
 gallery.photo=null;m.audio_feedback.dispose();m.queue_free();await process_frame
 print("RECORD_FOLLOWUP_VERIFY failures=",failures," intro_seconds=6 title_enable_seconds=1.2")
 quit(0 if failures.is_empty() else 1)
