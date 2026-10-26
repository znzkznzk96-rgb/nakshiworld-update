extends SceneTree
const PROFILES=[{"id":"1s0","stars":[1,1,1],"level":0},{"id":"1s1","stars":[1,1,1],"level":1},{"id":"1s2","stars":[1,1,1],"level":2},{"id":"1s3","stars":[1,1,1],"level":3}]
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var args:=OS.get_cmdline_user_args();var out:=args[0];var scenario:=args[1];var shard:=int(args[2]);var shards:=int(args[3]);var limit:=int(args[4]) if args.size()>4 else 3375
 var iv:=int(args[5]) if args.size()>5 else 4;var balanced_only:=args.size()>6 and args[6]=="balanced"
 var d=load("res://tests/analysis/candidate_model.gd").new();var original: Array=d.catalog.enemies.duplicate(true)
 var file:=FileAccess.open(out,FileAccess.WRITE)
 file.store_line("scenario,profile,team,round,win,ticks,hp_ratio,front_ratio,no_hp_hits,hits,raw_damage,absorbed,healed,shield_given,deaths,sample")
 var count:=0;var start:=Time.get_ticks_msec()
 for p in PROFILES:
  for r in ([3] if scenario.begins_with("r3_") else range(1,11)):
   var attack_mult: float=1.0;var hp_mult: float=1.0
   d.shield_factor=1.0
   if scenario!="current": d.shield_factor=0.2
   if scenario.begins_with("r3_"):attack_mult=float(scenario.trim_prefix("r3_"))
   if scenario=="hard":attack_mult=[3.0,3.5,3.2,5.0,2.5,4.5,1.5,3.5,3.5,1.0][r-1]
   if scenario=="expert":attack_mult=[3.0,3.5,3.5,5.5,2.8,5.0,1.8,4.0,4.0,1.15][r-1]
   if scenario=="curve": attack_mult=[3.0,3.0,2.1,3.5,1.65,3.5,1.1,3.0,3.0,1.0][r-1]
   if scenario=="pressure": attack_mult=[3.0,3.0,2.5,2.5,2.0,2.0,1.7,1.6,1.5,1.0][r-1]
   if scenario=="pressure_hp":
    attack_mult=[3.0,3.0,2.5,2.5,2.0,2.0,1.7,1.6,1.5,1.0][r-1];hp_mult=1.25 if r<10 else 1.0
   d.catalog.enemies=original.duplicate(true)
   for e in d.catalog.enemies:e.atk=roundi(float(e.atk)*attack_mult);e.hp=roundi(float(e.hp)*hp_mult)
   for raw_code in range(shard,limit*100,shards):
    var code: int=raw_code/100;var sample: int=raw_code%100
    var ids: Array=[code/225,(code/15)%15,code%15]
    # Mixed-star profiles use defense/attack/support placement for interpretable growth comparison.
    if balanced_only or p.has("levels") or p.id in ["2tank","2attack","2support","2two"]:
     if d.catalog.soldiers[ids[0]].role!="defense" or d.catalog.soldiers[ids[1]].role!="attack" or d.catalog.soldiers[ids[2]].role!="support":continue
    d.battle={};d.pending={};d.soldiers=[];d.team=[];d.next_uid=1;d.recovery_until=0;d.unlocked=10;d.completed=[]
    d.rng.seed=820000+raw_code
    for i in 3:
     var u: Dictionary=d.add_unit(ids[i],p.stars[i],[]);u.level=p.levels[i] if p.has("levels") else p.level;d.team.append(u.uid)
    d.start(r,1000)
    var ticks:=0;var hits:=0;var zero:=0;var damage:=0;var absorbed:=0;var healed:=0;var shields:=0
    while d.active():
     if d.battle.phase=="approach": d.battle.phase="fight"
     d.tick();ticks+=1
     var fx: Dictionary=d.battle.fx
     hits+=1;damage+=int(fx.incoming);absorbed+=int(fx.blocked)
     if int(fx.incoming)==0:zero+=1
     for h in fx.support:
      if h.kind=="ward":shields+=int(h.amount)
      else:healed+=int(h.amount)
     if d.battle.phase=="death":
      d.battle.index+=1
      if int(d.battle.index)>=3:d.finish(true,1000)
      else:d.spawn_enemy()
     elif d.battle.phase=="defeat":d.finish(false,1000)
     if ticks>1800:push_error("iteration overflow");quit(2);return
    var hp:=0;var maximum:=0;var deaths:=0
    for f in d.battle.fighters:
     hp+=int(f.hp);maximum+=int(f.max_hp)
     if int(f.hp)==0:deaths+=1
    file.store_line("%s,%s,%d,%d,%d,%d,%.6f,%.6f,%d,%d,%d,%d,%d,%d,%d,%d"%[scenario,p.id,code,r,int(d.battle.status=="win"),ticks,float(hp)/maximum,float(d.battle.fighters[0].hp)/float(d.battle.fighters[0].max_hp),zero,hits,damage,absorbed,healed,shields,deaths,sample])
    count+=1
  file.flush();print(scenario," shard ",shard," ",p.id," fights=",count," seconds=",(Time.get_ticks_msec()-start)/1000.0)
 file.close();print("SIMULATION_COMPLETE fights=",count);quit()
