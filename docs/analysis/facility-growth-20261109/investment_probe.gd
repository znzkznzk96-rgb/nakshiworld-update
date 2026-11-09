extends SceneTree
class ProbeMain:
 extends "res://main.gd"
 func _save_game() -> bool:return true
const INC=[0,10,20,40,60,80,100,115,130,145,160,175,190]
const REC=[30,35,40,50,60,70,80,90,100,110,120,130,140]
const SLOTS=[3,4,6,8,10,15,20,22,24,26,28,30,32]
const PASS=[4,5,6,8,10,12,14,15,16,17,18,19,20]
const INTERVAL=[60,58,56,52,48,44,40,40,40,40,40,40,40]
# aquarium/ferry/capacity/recovery; effect coefficients intentionally bounded.
const WEIGHTS=[.2857142857,.2380952381,.1904761905,.2857142857]
const ORDERS=[[3,2,0,1,3,2,0,1],[0,1,0,1,3,2,3,2],[3,3,2,2,0,1,0,1]]
const SELECTED_COSTS=[[[7500,22500],[6000,18000],[4000,12000],[7500,22500]],[[40000,110000],[30000,90000],[20000,60000],[40000,110000]],[[400000,1200000],[300000,1000000],[250000,750000],[400000,1200000]]]
var failures=[]
func _initialize():call_deferred("run")
func income(pool:Array,level:int)->float:
 var total=0.
 for f in pool:total+=f[1]
 return total*.15*float(PASS[level])/4.*60./INTERVAL[level]
func choose(pool:Array,slots:int,sp:int,price:int,boat:int,remaining:float)->Dictionary:
 var at=-1
 if sp%20==19:
  for i in pool.size():
   if int(pool[i][0])==sp:at=i;break
 if at<0 and pool.size()>=slots:
  at=0
  for i in pool.size():
   if pool[i][1]<pool[at][1]:at=i
 var old=0 if at<0 else int(pool[at][1])
 var factor=.15*float(PASS[boat])/4.*60./INTERVAL[boat]
 if price>old and (price-old)/((price-old)*factor)<=remaining:
  if at<0:pool.append([sp,price])
  else:pool[at]=[sp,price]
  return {"retained":true,"sold":old}
 return {"retained":false,"sold":price}
func run():
 var args=OS.get_cmdline_user_args();var focus="--focus" in args;var starter=JSON.parse_string(FileAccess.get_file_as_string(args[0]));var previous={}
 for c in starter.cases:
  if str(c.config.id)=="proposed_30_lv%d"%[int(c.region)*2+2]:previous["%d:%d:%d:%s"%[c.region,c.trial,c.bait,str(c.robot)]]=c.fish
 var m=ProbeMain.new();m.SET.music=0;m.SET.sfx=0;root.add_child(m);await process_frame;m.set_process(false);m.development_preview=true;m.TUT.done=true
 var rows=[];var draws=0
 for area in 3:
  for scale in ([1.] if focus else [.5,1.,1.5]):
   var budget=[80000,600000,8400000][area]*scale;var costs=[]
   for i in 4:
    var first=roundi(budget*WEIGHTS[i]*.25/10.)*10;var second=roundi(budget*WEIGHTS[i]*.75/10.)*10;costs.append([first,second])
   if focus:
    costs=SELECTED_COSTS[area].duplicate(true);budget=0
    for pair in costs:budget+=pair[0]+pair[1]
   for order_id in 3:
    for robot_on in [false,true]:
     for trial in (5 if focus else 3):
      for bait in [0,1,2]:
       seed(20261109+trial*1000+area*100+bait*10)
       m.active_region=area;m.rod_lv=area;m.forge_lv=area+1;m.region_shop.unlocked=[0,1,2];m.region_shop.selected_bait=bait;m.region_shop.stocks=[999999,999999,999999,0,0,0];m.bait=999999
       m.equipment.active_parts=[]
       for key in ["float","hook","line","reel"]:m.equipment.active_parts.append(key if area==0 else "r%d_%s"%[area,key])
       m.progression.owner_gauge=[0.,0.,0.,0.,0.,0.];m.capture_robot.restore({"owned":robot_on,"enabled":robot_on,"speed":[3,6,7][area],"capacity":4,"precision":area})
       var start_lv=area*2;var lv=[start_lv,start_lv,start_lv,start_lv];var pool=[]
       if area>0:
        var p=previous["%d:%d:%d:%s"%[area-1,trial,bait,str(robot_on)]].duplicate(true);p.sort_custom(func(a,b):return a[2]>b[2])
        var owners=[]
        for f in p:
         if int(f[1])%20==19 and int(f[1]) in owners:continue
         pool.append([int(f[1]),int(f[2])]);if int(f[1])%20==19:owners.append(int(f[1]))
         if pool.size()>=SLOTS[start_lv]:break
       m.pond_base=30.+INC[lv[2]];m.pond_cap_lv=0;m.pond_stock=m.pond_base
       var cash=0.;var active=0.;var session=0.;var offline=0.;var next=0.;var pending={};var step=0;var record=[];var on_income=0.;var off_income=0.;var sold=0;var bait_spent=0;var spent=0;var rcash=0
       while active<43200. and step<8:
        if session>=10800.:
         var credit=floori(income(pool,lv[1])*3.);cash+=credit;off_income+=credit;offline+=3.;m.pond_stock=m.pond_base;session=0.
        while step<8:
         var type=ORDERS[order_id][step];var cost=costs[type][lv[type]-start_lv]
         if cash<cost:break
         cash-=cost;spent+=cost;lv[type]+=1;step+=1
         if type==2:
          var old_cap=m.pond_base;m.pond_base=30.+INC[lv[2]]
          # Proposed expansion preserves stock ratio, avoiding a temporary rarity penalty.
          m.pond_stock=minf(m.pond_base,m.pond_stock*m.pond_base/old_cap)
         record.append([active/3600.,offline,step,type,cost,cash])
        if step==8:break
        var earn=income(pool,lv[1])/3600.;cash+=earn;on_income+=earn
        if not pending.is_empty() and active>=pending.end:
         if pending.success:
          if pending.owner:m.progression.settle_owner(area,true)
          else:m.progression.fishing_event(m,area,"catch",pending.grade)
          var choice=choose(pool,SLOTS[lv[0]],pending.sp,pending.price,lv[1],maxf(0,9.-active/3600.-offline));cash+=choice.sold;sold+=int(choice.sold)
         elif pending.owner:m.progression.settle_owner(area,false)
         pending={}
        if pending.is_empty() and active>=next:
         var insufficient=m.pond_stock<1.;m.pond_stock=maxf(0,m.pond_stock-1);m.S={"insufficient":insufficient};m.start_wait()
         var dt=30.+(m.S.biteAt-m.clock)-3.75
         if randf()<.1:m.S.grade=mini(4,m.S.grade+1)
         var owner=m.progression.owner_ready(m,area)
         if owner:m.S.star=4;m.S.sp=area*20+19;m.S.lf=m.bait_length_cm(m.S.sp)/float(m.FISH_LEN[m.S.sp])
         next=active+maxf(1,dt);pending={"end":next,"sp":m.S.sp,"grade":m.S.grade,"owner":owner,"success":randf()<.9,"price":m.fish_price(m.S.sp,m.S.star,m.S.grade,m.S.lf)};draws+=1
         var cost=[5,15,20][bait];cash-=cost;bait_spent+=cost
        m.pond_stock=minf(m.pond_base,m.pond_stock+REC[lv[3]]/3600.);m.capture_robot.update(m,1.)
        if int(active)%1800==1799:
         for f in m.capture_robot.fish:cash+=f.price;rcash+=int(f.price)
         m.capture_robot.fish=[]
        active+=1.;session+=1.
       if absf(cash-(sold+rcash+on_income+off_income-spent-bait_spent))>.01:failures.append("cash conservation")
       var owners=[]
       for f in pool:
        if int(f[0])%20==19:
         if f[0] in owners:failures.append("duplicate owner")
         owners.append(f[0])
       rows.append({"region":area,"scale":scale,"budget":budget,"costs":costs,"order":order_id,"robot":robot_on,"trial":trial,"bait":bait,"completed":step==8,"active_hours":active/3600.,"offline_credit_hours":offline,"steps":record,"cash":cash,"sources":{"sold":sold,"robot":rcash,"online":on_income,"offline":off_income,"spent":spent,"bait":bait_spent},"levels":lv,"pool":pool})
   print("INVESTMENT_GRID region=",area," scale=",scale)
 var f=FileAccess.open(args[1],FileAccess.WRITE);f.store_string(JSON.stringify({"draws":draws,"cases":rows,"failures":failures}));f.close();m.audio_feedback.dispose();m.queue_free();await process_frame;print("FACILITY_INVESTMENT_COMPLETE cases=",rows.size()," draws=",draws," failures=",failures);quit(0 if failures.is_empty() else 1)
