extends SceneTree
class Probe extends "res://tests/difficulty_sim_main.gd":
 var cfg: Dictionary={}
 func play(_n:String,_v:=0.0,_p:=1.0)->void:pass
 func buzz(_p)->void:pass
 func show_toast(_t:String,_c:=Color.WHITE,_a:=false)->void:pass
 func fail(text:String)->void:S.phase="failure";S.reason=text
 func start_catch()->void:S.phase="success"
 func lesson_end()->void:S.lesson=""
 func next_behavior()->void:
  super.next_behavior()
  if not cfg.get("baseline",false) and active_region>1 and S.beh in ["tell","nose","rise","turn"]:
   S.bt=maxf(S.bt,float(cfg.get("warning_floor",0)))
   S.warningDuration=S.bt
 func apply_profile():
  simulation_bonus_factor=1.0;simulation_loss_factor=1.0
  if cfg.get("baseline",false):return
  var resistance:float=cfg.region[active_region]
  var species:float=pow(maxf(.5,float(FISH_LEN[S.sp])/float(FISH_LEN[active_region*20])),float(cfg.get("species_exp",.06)))
  var size_factor:float=pow(float(S.lf),float(cfg.get("size_exp",.45)))
  var rank_factor:float=1+float(cfg.get("star_resist",.10))*int(S.star)+float(cfg.get("grade_resist",.06))*int(S.grade)
  simulation_loss_factor=pow(resistance*species*size_factor*rank_factor,-float(cfg.get("loss_exp",0)))
  S.reelMul=float(cfg.rods[rod_lv])*(1+float(cfg.get("enhance",.06))*forge_lv)/(resistance*species*size_factor*rank_factor)
  var load:float=pow(resistance,float(cfg.get("load_exp",.32)))
  simulation_bonus_factor=minf(1.5,S.reelMul)
  S.tensionMul=load/(pow(float(cfg.rods[rod_lv]),float(cfg.get("control_exp",.40)))*(1+float(cfg.get("enhance_control",.035))*forge_lv))
func _initialize():call_deferred("run")
func run():
 var args=OS.get_cmdline_user_args();var config:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]));var out:String=args[1]
 var m=Probe.new();m.SET.music=0;m.SET.sfx=0;m.SET.vib=false;m.title_open=false;root.add_child(m);await process_frame;m.set_process(false);m.TUT.done=true
 m.TUT.seen=["tell","jump","dive","charge","clone","sulk","circle","thrash","skim","spike"]
 var file=FileAccess.open(out,FileAccess.WRITE);var count:=0
 var dt:float=float(config.get("dt",.05));var limit:float=float(config.get("limit",120))
 for cfg in config.configs:
  m.cfg=cfg
  for scenario in config.scenarios:
   for n in int(config.trials):
    var sd:int=123456+n*7919+int(scenario.star)*100003+int(scenario.grade)*1009+int(scenario.get("variant",0))*37
    seed(sd);m.active_region=int(scenario.area);m.rod_lv=int(scenario.rod);m.forge_lv=int(scenario.enh)
    var choices:Array=m.CATALOG.by_star(m.active_region,int(scenario.star))
    var sp:int=int(scenario.get("sp",choices[int(scenario.get("variant",0))%choices.size()]))
    m.S={"sp":sp,"star":int(scenario.star),"grade":int(scenario.grade),"lf":float(scenario.get("lf",1)),"judge":"GREAT","tutFish":false}
    m.clock=0;m.start_fight();m.S.tut=false;m.S.lesson="";m.apply_profile();m.holding=true
    var profile:int=int(scenario.get("profile",1));var delay:float=[.45,.23,.10][profile];var mistakes:float=[.13,.045,.005][profile]
    var control_rng=RandomNumberGenerator.new();control_rng.seed=sd+555
    var history:Array=[];var observed:Dictionary={"beh":"swim","tension":30.0,"slack":0.0,"spike":0.0,"jumpT":0.0,"thT":0.0,"circA":0.0,"cloneSub":"rest"}
    var previous:String="";var wrong:bool=false;var t:float=0;var held:bool=true;var max_tension:float=30;var bonus:int=0
    while t<limit and m.S.phase=="fight":
     history.append({"at":t,"beh":m.S.beh,"tension":m.S.tension,"slack":m.S.slack,"spike":m.S.spike,"jumpT":m.S.jumpT,"thT":m.S.get("thT",0),"circA":m.S.get("circA",0),"cloneSub":m.S.get("cloneSub","rest")})
     while history.size()>1 and float(history[1].at)<=t-delay:observed=history.pop_front()
     var beh:String=observed.cloneSub if observed.beh=="clone" else observed.beh
     if beh!=previous:wrong=control_rng.randf()<mistakes;previous=beh
     var dangerous:bool=beh in ["tell","run","nose","dive","rise","jump"] or float(observed.spike)>0
     if beh=="circle":dangerous=sin(float(observed.circA))<=0
     if beh=="thrash":dangerous=sin(float(observed.thT)*(9+4*m.S.F))>.4
     var wanted:bool=not dangerous
     if beh=="sulk":wanted=fmod(t,1.0)<.30
     if wrong:wanted=not wanted
     if float(observed.tension)>[88,80,73][profile]:held=false
     elif float(observed.tension)<[48,40,32][profile]:held=true
     m.holding=wanted and held
     if beh in ["turn","charge"] and float(observed.tension)<92:m.holding=true
     # Brief visible-slack correction; no future behavior/timer inspection.
     if float(observed.slack)>2.8 and float(observed.tension)<65 and beh!="jump":m.holding=true
     # Human landing tap after observed jump, subject to reaction delay/missed input.
     if float(m.S.landUntil)>0 and t<=float(m.S.landUntil) and not m.S.jumpUsed and t>=float(m.S.landUntil)-.5+delay:
      m.S.jumpUsed=true
      if control_rng.randf()>=mistakes:
       m.S.dist+=12*(1.0 if cfg.get("baseline",false) else minf(1.5,m.S.reelMul));bonus+=1
     m.clock=t;m.update_fight(dt);max_tension=maxf(max_tension,m.S.tension);t+=dt
    var row:Dictionary={"config":cfg.id,"scenario":scenario,"seed":sd,"success":m.S.phase=="success","seconds":snappedf(t,.001),"outcome":m.S.get("reason","timeout" if m.S.phase=="fight" else "success"),"progress":m.S.dist,"max_tension":max_tension,"landing_taps":bonus}
    file.store_line(JSON.stringify(row));count+=1
 file.close();m.audio_feedback.dispose();m.queue_free();await process_frame;print("SIM_COMPLETE trials=",count);quit()
