extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String):
 if not ok:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 var m=load("res://main.gd").new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 var v=m.expedition;var d=v.data;d.restore({})
 for star in [1,2,3]:d.team.append(d.add_unit(0,star,[0,0,0]).uid)
 d.start(1,1000);d.battle.phase="fight";d.battle.clock=.4
 var before:String=JSON.stringify(d.serialize());var rng_state:int=d.rng.state
 for height in [59,85]:
  var r:=Rect2(12,100,246,height);var ground:float=r.end.y-2
  for id in 15:
   var sizes:Array=[]
   for star in [1,2,3]:
    var lane:Dictionary=v.battle_lane(r,1,star);var major:float=lane.major
    var box:=Rect2(lane.center-major/2,ground-major,major,major)
    var g:Dictionary=v.battle_sprite_geometry(id,box,0,star);sizes.append(maxf(g.body.size.x,g.body.size.y))
    check(absf(g.body.end.y-ground)<.001,"idle feet share floor")
    check(r.encloses(g.body),"visible body inside room")
    for frame in v.frame_count(id,star):
     var moving:Dictionary=v.battle_sprite_geometry(id,box,frame,star)
     check(moving.rect==g.rect and moving.body==g.body,"animation frame never changes size/anchor")
     check(Rect2(Vector2.ZERO,v.textures[moving.texture].get_size()).encloses(moving.region),"correct source frame and atlas bounds")
     m.ui_commands=[];v.battle_sprite(m,id,box,frame,1,star,r)
     for command in m.ui_commands:
      if command[0]=="region":check(r.encloses(command[2]),"attack effects clipped to room")
   check(absf(sizes[2]/sizes[0]-1.5)<.001,"unchanged first/third tier ratio")
   check(sizes[1]>=sizes[0]*1.25 and sizes[1]<=43.001,"tier2 body raised without exceeding lane width")
  for i in 3:
   var lane:Dictionary=v.battle_lane(r,i,i+1)
   check(not lane.hp.intersects(lane.skill.grow(1)),"skill sits beside health")
   check(r.encloses(lane.skill.grow(4)),"skill flare fits room")
   for j in 3:
    if i!=j:check(not lane.skill.grow(4).intersects(v.battle_lane(r,j,3).hp),"simultaneous skill never covers neighboring health")
  m.ui_commands=[];m.text_items=[];v.battle_art(m,r)
 var hammer_lane:Dictionary=v.battle_lane(Rect2(0,0,246,59),0,2)
 var hammer_box:=Rect2(hammer_lane.center-hammer_lane.major/2,57-hammer_lane.major,hammer_lane.major,hammer_lane.major)
 var hammer:Dictionary=v.battle_sprite_geometry(10,hammer_box,0,2)
 check(hammer.body.size.y>=27 and hammer.body.size.y<=28,"reported tier2 hammer body at least27px")
 check(hammer.body.size.y/(30.0*81/127)>1.4,"hammer body more than40percent taller than v122")
 check(JSON.stringify(d.serialize())==before and d.rng.state==rng_state,"drawing preserves combat/save/RNG")
 print("SOLDIER_SIZE_VERIFY failures=",failures)
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
