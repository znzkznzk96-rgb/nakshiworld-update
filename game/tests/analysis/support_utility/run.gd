extends SceneTree
var Base=preload("res://addons/expedition/model.gd")
var Candidate=preload("res://tests/analysis/support_utility/candidate.gd")
var profiles=[{"name":"low","regen":.025,"rescue":.12,"ward":.06,"cd":6,"threshold":.30,"expose":.10},{"name":"mid","regen":.045,"rescue":.18,"ward":.09,"cd":5,"threshold":.35,"expose":.15},{"name":"high","regen":.065,"rescue":.24,"ward":.12,"cd":4,"threshold":.40,"expose":.20}]
var Screen=preload("res://tests/analysis/support_utility/candidate_screen.gd")
var screen_run=false
var total=0
func _initialize():call_deferred("run")
func fight(ids: Array,stars: Array,level: int,iv: int,room: int,p: int,third_level: int=-1) -> Dictionary:
 var d=Base.new() if p<0 else Screen.new() if screen_run else Candidate.new()
 if p>=0:d.profile=profiles[p]
 d.unlocked=10;d.rng.seed=1
 for i in 3:
  var u=d.add_unit(ids[i],stars[i],[iv,iv,iv]);u.level=third_level if i==2 and third_level>=0 else level;u.rarity=0;d.team.append(u.uid)
 d.start(room,1000);var ticks=0
 while d.active():
  d.battle.phase="fight";d.tick();ticks+=1
  if d.battle.phase=="death":
   d.battle.index+=1
   if int(d.battle.index)>=3:d.finish(true,1000)
   else:d.spawn_enemy()
  elif d.battle.phase=="defeat":d.finish(false,1000)
 var hp=0.;var maximum=0.
 for f in d.battle.fighters:hp+=f.hp;maximum+=f.max_hp
 total+=1
 return {"win":int(d.battle.status=="win"),"ticks":ticks,"hp":hp/maximum,"effects":d.effect_total if p>=0 else 0,"rescues":d.rescue_count if p>=0 else 0}
func run():
 var out=OS.get_cmdline_user_args()[0];var mode=OS.get_cmdline_user_args()[1] if OS.get_cmdline_user_args().size()>1 else "screen"
 screen_run=mode=="screen"
 var ref=Base.new();var roles={"attack":[],"defense":[],"support":[]}
 for i in 15:roles[ref.catalog.soldiers[i].role].append(i)
 var rows=[]
 var configs=[[1,0],[1,3],[2,0],[2,3]]
 var ps=[-1,0,1,2]
 var ivs=[4]
 var comps=["DAA","DAS"]
 if mode=="validate":
  ps=[1];ivs=[int(OS.get_cmdline_user_args()[2])];comps=["DAA","DAS","DSS","SSS"];configs=[[1,0],[1,1],[1,2],[1,3],[2,0],[2,3]]
 if mode=="refine":
  profiles[1]={"name":"refined","regen":.035,"rescue":.15,"ward":.075,"cd":5,"threshold":.35,"expose":.15}
  ps=[1];comps=["DAA","DAS","DSS","SSS"]
  ivs=[int(OS.get_cmdline_user_args()[2])] if OS.get_cmdline_user_args().size()>2 else [4]
 for p in ps:
  for cfg in configs:
   for iv in ivs:
    for room in range(1,11):
     for comp in comps:
      var pools=[roles.defense,roles.attack,roles.attack] if comp=="DAA" else [roles.defense,roles.attack,roles.support] if comp=="DAS" else [roles.defense,roles.support,roles.support] if comp=="DSS" else [roles.support,roles.support,roles.support]
      var per={};var wins=0;var ticks=0;var hp=0.;var effects=0
      for a in pools[0]:
       for b in pools[1]:
        for c in pools[2]:
         var r=fight([a,b,c],[cfg[0],cfg[0],cfg[0]],cfg[1],iv,room,p)
         wins+=r.win
         if r.win:ticks+=r.ticks;hp+=r.hp
         effects+=r.effects
         var key=str(c)
         if not per.has(key):per[key]={"wins":0,"effects":0,"rescues":0}
         per[key].wins+=r.win;per[key].effects+=r.effects;per[key].rescues+=r.rescues
      rows.append({"profile":"base" if p<0 else profiles[p].name,"star":cfg[0],"level":cfg[1],"iv":iv,"room":room,"comp":comp,"wins":wins,"teams":125,"win_ticks":ticks,"win_hp":hp,"effects":effects,"per":per})
  print("PROFILE_DONE ",p," cases=",total)
 var file=FileAccess.open(out,FileAccess.WRITE);file.store_string(JSON.stringify({"profiles":profiles,"cases":total,"rows":rows}));file.close();print("DONE cases=",total);quit()
