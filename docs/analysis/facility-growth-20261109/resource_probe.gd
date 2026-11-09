extends SceneTree
# Analysis-only subclass prevents every save write from simulated robot transactions.
class ProbeMain:
 extends "res://main.gd"
 func _save_game() -> bool:return true
const SEEDS=5
const CAP_INC=[0,10,20,40,60,80,100,115,130,145,160,175,190]
const REGEN=[30,35,40,50,60,70,80,90,100,110,120,130,140]
const SLOTS=[3,4,6,8,10,15,20,22,24,26,28,30,32]
const PASSENGERS=[4,5,6,8,10,12,14,15,16,17,18,19,20]
const INTERVALS=[60,58,56,52,48,44,40,40,40,40,40,40,40]
func _initialize():call_deferred("run")
func run():
 var starter="--starter" in OS.get_cmdline_user_args()
 var m=ProbeMain.new();m.SET.music=0;m.SET.sfx=0;root.add_child(m);await process_frame;m.set_process(false);m.development_preview=true;m.TUT.done=true
 var rows=[];var draws=0
 for region in (1 if starter else 3):
  var configs=[]
  configs.append({"id":"current_max_new40","base":40,"cap":140,"regen":80,"slots":20,"mult":5.25,"forge":region+1})
  configs.append({"id":"current_max_legacy80","base":80,"cap":180,"regen":80,"slots":20,"mult":5.25,"forge":region+1})
  for base in [20,30,40]:
   for stage in [region*2,region*2+2]:
    configs.append({"id":"proposed_%d_lv%d"%[base,stage],"base":base,"stage":stage,"cap":base+CAP_INC[stage],"regen":REGEN[stage],"slots":SLOTS[stage],"mult":float(PASSENGERS[stage])/4.0*60.0/INTERVALS[stage],"forge":region+1})
  if starter:configs=configs.filter(func(c):return c.id.begins_with("proposed_30"))
  for config in configs:
   for robot_on in ([false] if starter else [false,true]):
    for gear in ([0,2] if starter else [4]):
     for trial in SEEDS:
      for bait in [0,1,2]:
       seed(20261109+trial*1000+region*100+bait*10)
       m.forge_lv=0 if starter else config.forge;m.active_region=region;m.region_shop.unlocked=[0,1,2];m.region_shop.selected_bait=bait;m.region_shop.stocks=[99999,99999,99999,0,0,0];m.bait=99999
       m.equipment.active_parts=[]
       for part in gear:
        var key=["float","hook","line","reel"][part];m.equipment.active_parts.append(key if region==0 else "r%d_%s"%[region,key])
       m.pond_base=config.cap;m.pond_cap_lv=0;m.pond_stock=config.cap;m.progression.owner_gauge=[0.,0.,0.,0.,0.,0.]
       m.capture_robot.restore({"owned":robot_on,"enabled":robot_on,"speed":[3,6,7][region],"capacity":4,"precision":region})
       var t=0.;var next_cast=0.;var depleted_at=-1.;var low_seconds=0.;var total_sales=0;var owner_sales=0;var catches=0;var owner_count=0;var attempts=0;var robot_catches=0;var robot_sales=0;var stars=[0,0,0,0,0];var fish=[]
       while t<10800.:
        if t>=next_cast:
         var insufficient=m.pond_stock<1.;m.pond_stock=maxf(0,m.pond_stock-1);m.S={"insufficient":insufficient};m.start_wait()
         var dt=30.+(m.S.biteAt-m.clock)-3.75
         if randf()<.1:m.S.grade=mini(4,m.S.grade+1)
         var owner=m.progression.owner_ready(m,region)
         if owner:m.S.star=4;m.S.sp=region*20+19;m.S.lf=m.bait_length_cm(m.S.sp)/float(m.FISH_LEN[m.S.sp])
         var success=randf()<.9
         attempts+=1;stars[m.S.star]+=1;draws+=1
         if success:
          var price=m.fish_price(m.S.sp,m.S.star,m.S.grade,m.S.lf);total_sales+=price;catches+=1
          if owner:m.progression.settle_owner(region,true);owner_count+=1;owner_sales+=price
          else:m.progression.fishing_event(m,region,"catch",m.S.grade)
          fish.append([t,m.S.sp,price])
         elif owner:m.progression.settle_owner(region,false)
         next_cast=t+maxf(1.,dt)
        m.pond_stock=minf(config.cap,m.pond_stock+config.regen/3600.)
        var before=m.capture_robot.fish.size();m.capture_robot.update(m,1.)
        if m.capture_robot.fish.size()>before:
         robot_catches+=1;robot_sales+=int(m.capture_robot.fish.back().price)
        if int(t)%1800==1799:m.capture_robot.fish=[]
        if m.pond_stock<1. and depleted_at<0:depleted_at=t
        if m.pond_stock<float(config.cap)*.35:low_seconds+=1
        t+=1.
       rows.append({"region":region,"gear":gear,"config":config,"robot":robot_on,"trial":trial,"bait":bait,"attempts":attempts,"catches":catches,"owner_catches":owner_count,"sale_all":total_sales,"owner_sales":owner_sales,"bait_cost":attempts*[5,15,20][bait],"robot_catches":robot_catches,"robot_sales":robot_sales,"depleted_at_seconds":depleted_at,"low_stock_seconds":low_seconds,"end_stock":m.pond_stock,"stars":stars,"fish":fish})
   print("CONFIG_COMPLETE region=",region," id=",config.id)
 var f=FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE);f.store_string(JSON.stringify({"draws":draws,"cases":rows}));f.close()
 m.audio_feedback.dispose();m.queue_free();await process_frame;print("FACILITY_RESOURCE_PROBE_COMPLETE cases=",rows.size()," draws=",draws);quit()
