extends SceneTree
var Model=preload("res://addons/expedition/model.gd")
func _initialize():call_deferred("run")
func run():
 var ref=Model.new();var roles={"attack":[],"defense":[],"support":[]}
 for i in 15:roles[ref.catalog.soldiers[i].role].append(i)
 var rows=[]
 for star in [1,2,3]:
  for level in [0,3]:
   for room in range(1,11):
    for role in ["attack","support"]:
     var wins=0;var ticks_sum=0;var hp_sum=0.0;var per={}
     for tank in roles.defense:
      for attacker in roles.attack:
       for third in roles[role]:
        var d=Model.new();d.unlocked=10;d.rng.seed=1
        for id in [tank,attacker,third]:
         var u=d.add_unit(id,star,[4,4,4]);u.level=level;d.team.append(u.uid)
        d.start(room,1000)
        var ticks=0;var support=0;var attacks=0
        while d.active():
         d.battle.phase="fight";d.tick();ticks+=1
         for e in d.battle.fx.get("support",[]):
          if int(e.source)==3:support+=int(e.amount)
         for e in d.battle.fx.get("attacks",[]):
          if int(e.source)==3:attacks+=int(e.amount)
         if d.battle.phase=="death":
          d.battle.index+=1
          if int(d.battle.index)>=3:d.finish(true,1000)
          else:d.spawn_enemy()
         elif d.battle.phase=="defeat":d.finish(false,1000)
        var won=d.battle.status=="win";var hp=0.0;var max_hp=0.0
        for f in d.battle.fighters:hp+=f.hp;max_hp+=f.max_hp
        if won:wins+=1;ticks_sum+=ticks;hp_sum+=hp/max_hp
        var key=str(third)
        if not per.has(key):per[key]={"name":ref.catalog.soldiers[third].name,"skill":ref.catalog.soldiers[third].skill,"wins":0,"support":0,"damage":0,"ticks":0}
        per[key].wins+=int(won);per[key].support+=support;per[key].damage+=attacks;per[key].ticks+=ticks
     rows.append({"star":star,"level":level,"room":room,"third_role":role,"wins":wins,"teams":125,"win_ticks":ticks_sum,"win_hp_ratio":hp_sum,"per_third":per})
 var file=FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE);file.store_string(JSON.stringify(rows));file.close()
 print("SUPPORT_AUDIT cases=15000 rows=",rows.size());quit()
