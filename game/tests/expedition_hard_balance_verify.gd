extends SceneTree
var failures: Array=[]
const FACTORS=[3.0,3.5,3.2,5.0,2.5,4.5,1.5,3.5,3.5,1.0]
func _initialize() -> void:call_deferred("run")
func prepare(path: String,r: int,ids: Array,star: int,level: int,iv: int):
 var d=load(path).new();d.unlocked=10
 for id in ids:
  var u=d.add_unit(id,star,[iv,iv,iv]);u.level=level;d.team.append(u.uid)
 return d
func fast(d) -> void:
 while d.active():
  d.battle.phase="fight";d.tick()
  if d.battle.phase=="death":
   d.battle.index+=1
   if int(d.battle.index)>=3:d.finish(true,1000)
   else:d.spawn_enemy()
  elif d.battle.phase=="defeat":d.finish(false,1000)
func equivalent(a,b) -> bool:
 return a.battle.status==b.battle.status and a.battle.fighters==b.battle.fighters
func run() -> void:
 var actual_path="res://addons/expedition/model.gd";var old_path="res://tests/analysis/baseline080_model.gd";var cases:=0;var saves:=0
 for iv in [0,4,8]:
  for r in range(1,11):
   for sample in 12:
    var ids=[(sample*7)%15,(sample*11+1)%15,(sample*13+6)%15];var star:=1+sample%3;var level:=sample%4
    var actual=prepare(actual_path,r,ids,star,level,iv)
    var expected=prepare("res://tests/analysis/candidate_model.gd",r,ids,star,level,iv);expected.shield_factor=.2
    for e in expected.catalog.enemies:e.atk=roundi(float(e.atk)*FACTORS[r-1])
    actual.start(r,1000);actual.battle.utility_revision=0;actual.battle.fighters.map(func(f): f.erase("support_budget"));expected.start(r,1000);fast(expected)
    var frames:=0
    while actual.active() and frames<100000:actual.update(.1,1000);frames+=1
    if actual.active() or not equivalent(actual,expected) or int(actual.battle.reward)!=(actual.FIRST_GOLD[r-1] if actual.battle.status=="win" else 0):failures.append(["runtime parity",iv,r,sample])
    cases+=1
   # Existing in-progress expeditions must keep all three old encounters unchanged.
   var old=prepare(old_path,r,[3,1,7],1,3,iv);old.start(r,1000);old.update(4.1,1000);old.update(1.5,1000)
   var restored=load(actual_path).new();restored.restore(old.serialize());fast(old);fast(restored)
   if not equivalent(old,restored) or int(old.battle.reward)!=int(restored.battle.reward):failures.append(["legacy resumed balance",iv,r])
   var fresh=prepare(actual_path,r,[3,1,7],2,1,iv);fresh.start(r,1000);fresh.battle.utility_revision=0;fresh.update(4.1,1000);fresh.update(1.5,1000)
   restored=load(actual_path).new();restored.restore(fresh.serialize());fast(fresh);fast(restored)
   if not equivalent(fresh,restored) or int(fresh.battle.reward)!=int(restored.battle.reward):failures.append(["new resumed balance",iv,r])
   saves+=2
 var ref=load(actual_path).new();var roles={"attack":[],"defense":[],"support":[]}
 for i in 15:roles[ref.catalog.soldiers[i].role].append(i)
 var gate=[]
 for iv in [0,4,8]:
  var wins=[]
  for level in 4:
   var n:=0
   for a in roles.defense:
    for b in roles.attack:
     for c in roles.support:
      var d=prepare(actual_path,3,[a,b,c],1,level,iv);d.start(3,1000);d.battle.utility_revision=0;fast(d)
      if d.battle.status=="win":n+=1
   wins.append(n)
  if wins[0]<1 or wins[0]>65 or wins[1]<=wins[0] or wins[2]<120 or wins[3]!=125:failures.append(["first growth wall",iv,wins])
  gate.append({"iv":iv,"wins_by_training":wins,"teams":125})
 print("HARD_BALANCE_REPORT ",JSON.stringify({"runtime_parity_cases":cases,"save_cases":saves,"gate":gate}))
 print("EXPEDITION_HARD_BALANCE_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
