extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String):
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 var m=load("res://main.gd").new();m.SET.music=0;m.SET.sfx=0;root.add_child(m);await process_frame;m.set_process(false)
 var cfg=m.FISHING_DIFFICULTY
 var state:Dictionary={"rod_enh":m.rod_enh.duplicate(),"bag":m.bag.duplicate(true),"gold":m.gold,"equipment":m.equipment.serialize().duplicate(true)}
 for area in 3:
  m.active_region=area
  for rod in 3:
   m.rod_lv=rod;m.forge_lv=0
   m.S={"sp":area*20,"star":0,"grade":0,"lf":1.0,"tutFish":false};seed(123);m.start_fight()
   if area==0:
    check(is_equal_approx(m.S.reelMul,1+.12*rod) and is_equal_approx(m.S.tensionMul,1-.08*rod),"reservoir unchanged")
    check(m.S.progress_loss_factor==1 and m.S.progress_bonus_factor==1,"reservoir bonus and loss unchanged")
   else:
    check(is_equal_approx(m.S.reelMul,cfg.ROD_POWER[rod]/cfg.REGION_RESISTANCE[area]),"approved regional gear strength")
    var speed:float=m.S.reelMul;var tension:float=m.S.tensionMul;m.forge_lv=3;cfg.configure(m)
    check(m.S.reelMul>speed and m.S.tensionMul<tension,"enhancement improves speed and control")
    var average:float=m.S.reelMul;m.S.lf=1.4;cfg.configure(m);check(m.S.reelMul<average,"larger individual needs more effort")
    m.S.lf=1;m.S.star=4;m.S.grade=1;cfg.configure(m);check(m.S.reelMul<average,"owner rank adds resistance")
    check(m.S.progress_bonus_factor<=1.5 and m.S.progress_loss_factor<1,"bonuses and release loss share resistance")
 m.active_region=2;m.rod_lv=2;m.forge_lv=5;m.S={"sp":40,"star":0,"grade":0,"lf":1.0};m.start_fight()
 check(is_equal_approx(m.S.reelMul,2.9*1.3/3.8),"tile recommended exact value")
 m.S.beh="tell";m.S.bt=.4;cfg.warning_floor(m);check(m.S.bt==.55,"minimum visible warning")
 m.active_region=0;m.S.bt=.4;cfg.warning_floor(m);check(m.S.bt==.4,"reservoir warnings unchanged")
 for i in range(1,6):check(cfg.rod_power(i)>cfg.rod_power(i-1),"higher existing rods remain stronger")
 check(cfg.upgrade_labels(5,2)[0]=="+30%" and cfg.upgrade_labels(5,2)[1]=="-23%","forge displays actual denominator reduction")
 m.rod_enh=state.rod_enh;m.rod_lv=0
 check(m.bag==state.bag and m.gold==state.gold and m.equipment.serialize()==state.equipment,"configuration preserves bag wallet and owned equipment")
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print("FISHING_DIFFICULTY_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
