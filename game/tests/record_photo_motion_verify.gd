extends SceneTree
var failures:Array=[]
func _initialize():call_deferred("run")
func run():
 var motion=load("res://addons/reservoir/record_photo_motion.gd").new()
 var profiles:Dictionary={};var samples:=0
 for sp in 80:
  profiles[motion.profile(sp)]=true
  for y in 7:
   for x in 15:
    var p:=Vector2(x/14.0,y/6.0)
    if motion.offset(sp,p,-1)!=Vector2.ZERO:failures.append("export pose")
    for frame in 64:
     var t:=frame/12.0
     var d:Vector2=motion.offset(sp,p,t)
     if not d.is_finite() or d.length()>8.4:failures.append("motion bounds")
     # Screen-space orientation must never fold or tear a grid cell.
     if x<14:
      var next:Vector2=motion.offset(sp,p+Vector2(1.0/14,0),t)
      if 140.0/14+next.x-d.x<=0:failures.append("fold x")
     if y<6:
      var next:Vector2=motion.offset(sp,p+Vector2(0,1.0/6),t)
      if 20.0/6+next.y-d.y<=0:failures.append("fold y")
     samples+=1
 if profiles.size()!=6:failures.append("six profiles")
 # Distinct body-family responses, including exact rest periods.
 var signatures:Dictionary={}
 for sp in [0,16,47,51,64,75]:
  var response:Array=[]
  for i in 12:response.append(motion.offset(sp,Vector2(.8,.2),i*.07))
  signatures[str(response)]=true
  if motion.strength(sp,9)!=0:failures.append("rest interval")
 if signatures.size()!=6:failures.append("duplicate body motion")
 print("RECORD_PHOTO_MOTION_VERIFY failures=",failures," samples=",samples," profiles=",profiles.size())
 quit(0 if failures.is_empty() else 1)
