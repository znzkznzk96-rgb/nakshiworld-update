extends SceneTree
var Base=preload("res://addons/expedition/model.gd")
var Candidate=preload("res://tests/analysis/support_utility/candidate.gd")
var failures=[]
var count=0
func _initialize():call_deferred("run")
func make(ids,star,level,room,candidate):
 var d=Candidate.new() if candidate else Base.new();d.unlocked=10;d.rng.seed=1
 for id in ids:
  var u=d.add_unit(id,star,[4,4,4]);u.level=level;u.rarity=0;d.team.append(u.uid)
 d.start(room,1000);return d
func fast(d):
 while d.active():
  d.battle.phase="fight";d.tick()
  if d.battle.phase=="death":
   d.battle.index+=1
   if int(d.battle.index)>=3:d.finish(true,1000)
   else:d.spawn_enemy()
  elif d.battle.phase=="defeat":d.finish(false,1000)
func check(ok,label):
 if not ok:failures.append(label)
 count+=1
func run():
 for room in range(1,11):
  for star in [1,2]:
   for level in [0,3]:
    var a=make([3,0,1],star,level,room,false);var b=make([3,0,1],star,level,room,true);fast(a);fast(b)
    check(a.battle.fighters==b.battle.fighters and a.battle.enemy==b.battle.enemy,"no support parity")
  for id in [4,6,7,9,12]:
   var a=make([3,0,id],1,3,room,true);var b=make([3,0,id],1,3,room,true);fast(a)
   var frames=0
   while b.active() and frames<100000:b.update(.1,1000);frames+=1
   check(a.battle.status==b.battle.status and a.battle.fighters==b.battle.fighters and a.utility_tick==b.utility_tick,"actual update parity")
 var rescue=make([3,0,7],1,0,1,true);rescue.battle.fighters[0].hp=1;rescue.battle.enemy.atk=1;rescue.tick()
 check(rescue.rescue_count==1 and rescue.battle.fighters[0].hp>0,"rescue before lethal hit")
 var r=rescue.rescue_ready
 rescue.spawn_enemy();check(rescue.rescue_ready==r and rescue.utility_tick==1,"cooldown continues across enemies")
 var scale=make([3,0,7],2,3,1,true)
 var src=scale.battle.fighters[2];src.max_hp=roundi(src.max_hp*.4)
 check(scale.utility_base(scale.battle.fighters[0],src)<float(scale.battle.fighters[0].max_hp)*.5,"underleveled support scale cap")
 print("UTILITY_VERIFY checks=",count," failures=",failures);quit(0 if failures.is_empty() else 1)
