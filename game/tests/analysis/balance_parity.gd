extends SceneTree
func _initialize() -> void:call_deferred("run")
func configure(scenario: String,r: int,ids: Array,star: int,level: int):
 var d=load("res://tests/analysis/candidate_model.gd").new();d.unlocked=10
 if scenario!="current":d.shield_factor=0.2
 var am: float=[3.0,3.0,2.5,2.5,2.0,2.0,1.7,1.6,1.5,1.0][r-1] if scenario in ["pressure","pressure_hp"] else 1.0
 if scenario=="curve":am=[3.0,3.0,2.1,3.5,1.65,3.5,1.1,3.0,3.0,1.0][r-1]
 for e in d.catalog.enemies:e.atk=roundi(float(e.atk)*am);e.hp=roundi(float(e.hp)*(1.25 if scenario=="pressure_hp" and r<10 else 1.0))
 for id in ids:
  var u: Dictionary=d.add_unit(id,star,[4,4,4]);u.level=level;d.team.append(u.uid)
 d.start(r,1000);return d
func run() -> void:
 var failures=[];var cases:=0
 for scenario in ["current","shield","pressure","pressure_hp","curve"]:
  for r in range(1,11):
   for sample in 12:
    var ids: Array=[(sample*7)%15,(sample*11+1)%15,(sample*13+6)%15];var star:=1+sample%3;var level:=sample%4
    var fast=configure(scenario,r,ids,star,level);var real=configure(scenario,r,ids,star,level)
    while fast.active():
     fast.battle.phase="fight";fast.tick()
     if fast.battle.phase=="death":
      fast.battle.index+=1
      if int(fast.battle.index)>=3:fast.finish(true,1000)
      else:fast.spawn_enemy()
     elif fast.battle.phase=="defeat":fast.finish(false,1000)
    var frames:=0
    while real.active() and frames<100000:real.update(.1,1000);frames+=1
    if real.active() or fast.battle.status!=real.battle.status or fast.battle.fighters!=real.battle.fighters or int(fast.battle.reward)!=int(real.battle.reward):failures.append([scenario,r,sample])
    cases+=1
 var result={"cases":cases,"failures":failures,"method":"Compare accelerated exact production tick to actual update(0.1) including transitions; final all fighter dictionaries, outcome and reward"}
 FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
 print("BALANCE_PARITY ",JSON.stringify(result));quit(0 if failures.is_empty() else 1)
