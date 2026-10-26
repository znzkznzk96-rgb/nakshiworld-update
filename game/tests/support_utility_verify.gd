extends SceneTree
var failures=[]
var Model=preload("res://addons/expedition/model.gd")
var Old=preload("res://tests/combat_feedback_baseline.gd")
func _initialize():call_deferred("run")
func check(ok,label):
 if not ok:failures.append(label)
func prepare(ids,star=2,rare=0):
 var d=Model.new();d.rng.seed=1;d.unlocked=10
 for id in ids:
  var u=d.add_unit(id,star,[4,4,4]);u.level=3;u.rarity=rare;d.team.append(u.uid)
 d.start(10,1000);return d
func step(d):
 d.battle.phase="fight";d.tick()
 if d.battle.phase=="death":
  d.battle.index+=1
  if int(d.battle.index)>=3:d.finish(true,1000)
  else:d.spawn_enemy()
 elif d.battle.phase=="defeat":d.finish(false,1000)
func run():
 var save_cases=0
 for id in [4,6,7,9,12]:
  for rare in 3:
   var a=prepare([3,0,id],3,rare);var b=Model.new();b.restore(JSON.parse_string(JSON.stringify(a.serialize())))
   for tick in 300:
    if not a.active():break
    step(a);step(b);check(JSON.parse_string(JSON.stringify(a.battle))==JSON.parse_string(JSON.stringify(b.battle)),"JSON resume parity")
    b.restore(JSON.parse_string(JSON.stringify(b.serialize())));save_cases+=1
   check(a.battle.status==b.battle.status,"final restored outcome")
 # Running old saves keep v0.85 support rules for the whole expedition.
 var old=Old.new();old.unlocked=10
 for id in [3,0,7]:
  var u=old.add_unit(id,2,[4,4,4]);u.level=3;old.team.append(u.uid)
 old.start(10,1000);old.tick();var restored=Model.new();restored.restore(JSON.parse_string(JSON.stringify(old.serialize())))
 while old.active():step(old);step(restored);check(JSON.parse_string(JSON.stringify(old.battle.fighters))==JSON.parse_string(JSON.stringify(restored.battle.fighters)),"legacy uninterrupted outcome")
 check(old.battle.status==restored.battle.status,"legacy final status")
 for ids in [[7,7,3],[12,12,3],[6,6,3]]:
  var d=prepare(ids);d.battle.fighters[0].max_hp=100;d.battle.fighters[0].hp=1;d.battle.enemy.atk=1
  d.battle.utility_tick=1;d.tick()
  var relevant=d.battle.fx.support.filter(func(e):return e.kind==("heal" if ids[0]==7 else "ward" if ids[0]==12 else "regen"))
  check(relevant.size()==1 and int(relevant[0].source)==2,"strongest duplicate once")
  check(d.battle.fx.attacks.size()==3,"support keeps attacking")
 var d=prepare([3,0,7]);d.battle.fighters[0].hp=1;d.battle.enemy.atk=1;d.tick()
 check(d.battle.fx.support.size()==1 and d.battle.fighters[0].hp>0,"prelethal rescue")
 var ready=d.battle.rescue_ready;var clock=d.battle.utility_tick;d.spawn_enemy()
 check(d.battle.rescue_ready==ready and d.battle.utility_tick==clock,"timers cross encounters")
 print("SUPPORT_UTILITY_SAVE_CASES ",save_cases)
 print("SUPPORT_UTILITY_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
