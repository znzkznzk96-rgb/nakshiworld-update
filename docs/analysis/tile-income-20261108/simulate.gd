extends SceneTree
const N=50000
func _initialize():call_deferred("run")
func run():
 var m=load("res://main.gd").new();m.SET.music=0;m.SET.sfx=0;root.add_child(m);await process_frame;m.set_process(false);m.development_preview=true;m.TUT.done=true;m.forge_lv=0;m.pond_cap_lv=0;m.pond_regen_lv=0;m.pond_base=40.0
 var rows=[]
 for region in [1,2]:
  m.active_region=region;m.region_shop.unlocked=[0,1,2];m.equipment.active_parts=[]
  for key in ["float","hook","line","reel"]:m.equipment.active_parts.append("r%d_%s"%[region,key])
  for bait in [0,1,2]:
   for mode in ["full","continuous"]:
    seed(20261108+region*100+10*bait+(1 if mode=="full" else 2));m.region_shop.selected_bait=bait;m.region_shop.stocks=[0,N+1,N+1,0,0,0];m.bait=N+1;m.progression.owner_gauge[region]=0.0;m.pond_stock=40.0
    var gold=0.0;var gross=0.0;var seconds=0.0;var owners=0;var catches=0;var stars=[0,0,0,0,0];var donated=0.0;var bonus=0.0;var main_seen=[];var sub_seen=[];var owner_donated=false;var sub_claimed=false;var first_fee=-1.0;var main_time=-1.0;var half_gold=0.0;var half_time=0.0;var depleted_at=-1.0
    var ordinary_gross=0.0;var owner_gross=0.0
    for i in N:
     if mode=="full":m.pond_stock=40.0
     var insufficient:bool=m.pond_stock<1.0;m.pond_stock=maxf(0,m.pond_stock-1)
     m.S={"insufficient":insufficient};m.start_wait()
     var wait:float=m.S.biteAt-m.clock
     # A declared 30-second full-stock reference cycle; only the coded bite-wait penalty changes.
     var dt:float=30.0+wait-3.75
     if randf()<0.10:m.S.grade=mini(4,m.S.grade+1) # 50% PERFECT x20% grade-up; otherwise GREAT.
     var owner:bool=m.progression.owner_ready(m,region)
     if owner:
      m.S.star=4;m.S.sp=region*20+19;m.S.lf=m.bait_length_cm(m.S.sp)/float(m.FISH_LEN[m.S.sp])
     stars[m.S.star]+=1
     gold-=m.region_shop.BAIT_PRICES[bait]
     if randf()<.90:
      catches+=1
      var price:int=m.fish_price(m.S.sp,m.S.star,m.S.grade,m.S.lf)
      gross+=price
      if owner:owners+=1;owner_gross+=price;m.progression.settle_owner(region,true)
      else:ordinary_gross+=price;m.progression.fishing_event(m,region,"catch",m.S.grade)
      var donation:bool=false
      if m.S.sp in m.progression.MAIN_SPECIES[region] and m.S.sp not in main_seen:main_seen.append(m.S.sp);donation=true
      elif m.S.sp in m.progression.SUB_SPECIES[region] and m.S.sp not in sub_seen:sub_seen.append(m.S.sp);donation=true
      elif owner and not owner_donated:
       owner_donated=true;donation=true;var reward:int=m.progression.reward_gold(region,2);gold+=reward;bonus+=reward
      if donation:donated+=price
      else:gold+=price
      if sub_seen.size()==6 and not sub_claimed:
       sub_claimed=true;var reward:int=m.progression.reward_gold(region,1);gold+=reward;bonus+=reward
     elif owner:m.progression.settle_owner(region,false)
     seconds+=dt;m.pond_stock=minf(m.pond_max(),m.pond_stock+m.pond_recovery()*dt/3600.0)
     if depleted_at<0 and insufficient:depleted_at=seconds/60.0
     if main_time<0 and main_seen.size()==6:main_time=seconds/3600.0
     if first_fee<0 and gold>=m.spots.PRICES[region+1]:first_fee=seconds/3600.0
     if i==N/2-1:half_gold=gold;half_time=seconds
    rows.append({"region":region,"bait":bait,"mode":mode,"attempts":N,"catches":catches,"owner_catches":owners,"hours":seconds/3600.0,"gross_per_attempt":gross/N,"ordinary_gross_per_attempt":ordinary_gross/N,"owner_gross_per_attempt":owner_gross/N,"steady_net_per_hour":(gold-half_gold)/(seconds-half_time)*3600.0,"fee":m.spots.PRICES[region+1],"first_fee_hours":first_fee,"main_complete_hours":main_time,"main_species_observed":main_seen,"sub_complete":sub_claimed,"oneoff_bonus":bonus,"donation_opportunity_cost":donated,"first_insufficient_minutes":depleted_at,"stars":stars})
    print("SIM ",region," ",bait," ",mode," done")
 var out=OS.get_cmdline_user_args()[0];var f=FileAccess.open(out,FileAccess.WRITE);f.store_string(JSON.stringify({"seed_base":20261108,"results":rows},"  "));f.close();m.audio_feedback.dispose();m.queue_free();await process_frame;print("TILE_INCOME_SIM_COMPLETE draws=",N*12);quit()
