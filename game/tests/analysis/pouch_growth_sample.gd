extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var out=[]
 for ids in [[3,1,4],[2,0,4]]:
  var stages=[]
  for lv in 4:stages.append({"stars":[1,1,1],"levels":[lv,lv,lv]})
  for promote in 3:
   for lv in 4:
    var stars=[1,1,1];var levels=[3,3,3]
    for i in range(promote+1):stars[i]=2
    levels[promote]=lv;stages.append({"stars":stars,"levels":levels})
  for stage in stages:
   stage["ids"]=ids;stage["need"]=[0,0,0,0,0];stage["gold"]=0;stage["battles"]=[]
   for i in 3:
    var d=load("res://addons/expedition/model.gd").new();var element=int(d.catalog.soldiers[ids[i]].elements[0]);var lv=int(stage.levels[i]);var upgraded=int(stage.stars[i])==2
    stage.need[element]+=(18 if upgraded else 2)+lv*(lv+1)/2
    stage.gold+=(1400 if upgraded else 0)+([0,100,300,700][lv]*(2 if upgraded else 1))
   for r in range(1,11):
    var d=load("res://addons/expedition/model.gd").new();d.unlocked=10
    for i in 3:
     var u=d.add_unit(ids[i],stage.stars[i],[4,4,4]);u.level=stage.levels[i];d.team.append(u.uid)
    d.start(r,1000);var frames:=0
    while d.active() and frames<100000:d.update(.1,1000);frames+=1
    stage.battles.append({"round":r,"win":d.battle.status=="win","seconds":frames*.1,"cycle_seconds":frames*.1+30})
   out.append(stage)
 FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE).store_string(JSON.stringify(out,"  "));print("POUCH_GROWTH_SAMPLE battles=320");quit()
