extends SceneTree
func _initialize():
 var Model=load("res://addons/expedition/model.gd")
 var sample=Model.new();var roles={"attack":[],"defense":[],"support":[]}
 for i in 15:roles[sample.catalog.soldiers[i].role].append(i)
 var teams=[];var idx=0
 for a in roles.defense:
  for b in roles.attack:
   for c in roles.support:
    if idx%5==int(idx/5)%5:teams.append([a,b,c])
    idx+=1
 var rows=[]
 for r in range(1,11):
  for star in [1,2,3]:
   for level in [0,3]:
    for ids in teams:
     var d=Model.new();d.unlocked=10;d.completed=[r];d.rng.seed=20261102
     for id in ids:
      var u=d.add_unit(id,star,[4,4,4]);u.level=level;d.team.append(u.uid)
     assert(d.start(r,1000))
     var steps=0
     while d.active() and steps<12000:
      d.update(.1,1000+steps*.1);steps+=1
     assert(not d.active())
     rows.append({"round":r,"star":star,"training":level,"team":ids,"win":d.battle.status=="win","seconds":steps*.1,"gold":d.battle.reward,"cycle_seconds":steps*.1+30})
 var f=FileAccess.open("/workspace/scratch/c8c564d78230/repo/analysis/expedition-cash-20261030/battles.json",FileAccess.WRITE);f.store_string(JSON.stringify(rows));f.close()
 print("EXPEDITION_CASH_PROBE cases=",rows.size());quit()
