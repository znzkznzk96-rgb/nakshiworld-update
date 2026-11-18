extends SceneTree
func _initialize():call_deferred("run")
func run():
 var Model=load("res://addons/expedition/model.gd")
 var ref=Model.new();var roles={"attack":[],"defense":[],"support":[]};var report=[]
 for i in 15:roles[ref.catalog.soldiers[i].role].append(i)
 for r in [3,6,10]:
  for star in [1,2]:
   for level in [0,3]:
    for boost in [1.0,1.1,1.2,1.3]:
     var wins:=0;var total:=0;var ticks:=0;var timeouts:=0
     for a in roles.defense:
      for b in roles.attack:
       for c in roles.support:
        var d=Model.new();d.unlocked=10;d.rng.seed=17
        for id in [a,b,c]:
         var u=d.add_unit(id,star,[4,4,4]);u.level=level;d.team.append(u.uid)
        assert(d.start(r,1000))
        for f in d.battle.fighters:f.atk=roundi(float(f.atk)*boost)
        var steps:=0
        while d.active() and steps<10000:
         d.update(0.25,1000);steps+=1
        if d.active():timeouts+=1
        if d.battle.status=="win":wins+=1;ticks+=steps
        total+=1
     report.append({"round":r,"star":star,"level":level,"attack_multiplier":boost,"wins":wins,"total":total,"mean_win_seconds":float(ticks)*.25/maxi(1,wins),"timeouts":timeouts})
     print("EXP ",report[-1])
 var f=FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"));f.close();quit()
