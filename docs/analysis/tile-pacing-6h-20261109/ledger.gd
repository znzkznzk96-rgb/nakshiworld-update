extends SceneTree
const N=6000 # Safety limit; daily sessions stop after6days.
const SEEDS=5
func _initialize():call_deferred("run")
func run():
 var m=load("res://main.gd").new();m.SET.music=0;m.SET.sfx=0;root.add_child(m);await process_frame;m.set_process(false);m.development_preview=true;m.TUT.done=true;m.forge_lv=0;m.pond_cap_lv=0;m.pond_regen_lv=0;m.pond_base=40.0;m.active_region=2;m.region_shop.unlocked=[0,1,2];m.equipment.active_parts=["r2_float","r2_hook","r2_line","r2_reel"]
 var cases=[];var draw_count:int=0
 for trial in SEEDS:
  for bait in [0,1,2]:
   for mode in ["daily"]:
    var case_seed:int=20261108+trial*1000+200+10*bait+2
    seed(case_seed);m.region_shop.selected_bait=bait;m.region_shop.stocks=[0,N+1,N+1,0,0,0];m.bait=N+1;m.progression.owner_gauge[2]=0.0;m.pond_stock=40.0
    var day:int=1;var session:float=0.0
    var main_seen=[];var sub_seen=[];var owner_donated=false;var sub_claimed=false;var ledger=[];var stars=[0,0,0,0,0]
    for i in N:
     if session>=21600.0:
      if day>=6:break
      day+=1;session=0.0;m.pond_stock=40.0
      ledger.append([28800.0,-1,0,1.0,0,0,0,0,day]) #18h away; exactly8h paid on next login.
     var insufficient:bool=m.pond_stock<1.0;m.pond_stock=maxf(0,m.pond_stock-1);m.S={"insufficient":insufficient};m.start_wait()
     var dt:float=30.0+(m.S.biteAt-m.clock)-3.75
     if randf()<.10:m.S.grade=mini(4,m.S.grade+1)
     var owner:bool=m.progression.owner_ready(m,2)
     if owner:m.S.star=4;m.S.sp=59;m.S.lf=m.bait_length_cm(59)/float(m.FISH_LEN[59])
     stars[m.S.star]+=1
     var success:bool=randf()<.90;var donation:int=0;var bonus:int=0
     var price:int=m.fish_price(m.S.sp,m.S.star,m.S.grade,m.S.lf)
     if success:
      if owner:m.progression.settle_owner(2,true)
      else:m.progression.fishing_event(m,2,"catch",m.S.grade)
      if m.S.sp in m.progression.MAIN_SPECIES[2] and m.S.sp not in main_seen:main_seen.append(m.S.sp);donation=1
      elif m.S.sp in m.progression.SUB_SPECIES[2] and m.S.sp not in sub_seen:sub_seen.append(m.S.sp);donation=2
      elif owner and not owner_donated:owner_donated=true;donation=3;bonus+=m.progression.reward_gold(2,2)
      if sub_seen.size()==6 and not sub_claimed:sub_claimed=true;bonus+=m.progression.reward_gold(2,1)
     elif owner:m.progression.settle_owner(2,false)
     ledger.append([dt,m.S.sp-40,m.S.grade,m.S.lf,int(success),donation,bonus,price,day]);session+=dt;draw_count+=1
     m.pond_stock=minf(40.0,m.pond_stock+30.0*dt/3600.0)
    cases.append({"trial":trial,"bait":bait,"mode":mode,"seed":case_seed,"stars":stars,"main_seen":main_seen,"ledger":ledger})
    print("LEDGER ",trial," ",bait," ",mode)
 var f=FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE);f.store_string(JSON.stringify({"draws":draw_count,"cases":cases}));f.close();m.audio_feedback.dispose();m.queue_free();await process_frame;print("DAILY_LEDGER_COMPLETE cases=",cases.size());quit()
