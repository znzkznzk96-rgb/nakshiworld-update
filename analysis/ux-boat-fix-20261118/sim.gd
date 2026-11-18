extends SceneTree
class Sim extends "res://main.gd":
	func _save_game()->bool:return true
	func play(_n:String,_v:=0.0,_p:=1.0)->void:pass
	func buzz(_p)->void:pass
	func fail(_t:String)->void:
		_settle_owner(false)
		S.phase="fail"
	func start_catch()->void:
		_settle_owner(true)
		S.weight = W_BASE[S.star] * pow(S.lf,3) * W_GRADE[S.grade]
		S.phase="caught"
var elapsed:=0.0
var idle:=0.0
var bank:=0.0
var purchases:Array=[]
var robot_count:=0
var first_species:Dictionary={}
var session_length:=10800.0
var smart:=true
var session_time:=0.0
var days:=1
var region_start:=0.0
var stage_idle:=0.0
var aqua_online:=0.0
var aqua_offline:=0.0
var sale_income:=0
var bundle_income:=0
func _initialize():call_deferred("run")
func advance(m, seconds:float):
	var left=seconds
	while left>0:
		var dt=minf(left,1.0)
		m.pond_stock=minf(m.pond_max(),m.pond_stock+m.pond_recovery()*dt/3600.0)
		m.capture_robot.update(m,dt)
		var earning:float=m.aqua_rate()*dt/60.0
		aqua_online+=earning;bank+=earning
		m.gold+=int(bank);bank-=int(bank)
		left-=dt
	elapsed+=seconds;session_time+=seconds
func process_bag(m,region:int):
	var donation_before:int=m.gold
	for j in range(m.bag.size()-1,-1,-1):
		var sp=int(m.bag[j].sp)
		if not first_species.has(str(sp)):first_species[str(sp)]=elapsed/3600
		for k in 3:
			if m.progression.bundle_done(region,k):continue
			var list=m.progression.MAIN_SPECIES[region] if k==0 else (m.progression.SUB_SPECIES[region] if k==1 else [region*20+19])
			var idx=list.find(sp)
			if idx>=0 and m.progression.donate_bundle(m,region,k,j,idx):
				if m.progression.bundle_done(region,k):m.progression.claim_reward(m,region,k)
				break
	bundle_income+=int(m.gold)-donation_before
	for j in range(m.bag.size()-1,-1,-1):
		var f=m.bag[j]
		var pos=m.aqua.find(null)
		if pos<0:
			pos=0
			for k in m.aqua.size():
				if m.aqua[k].price<m.aqua[pos].price:pos=k
		if int(f.sp)%20==19:
			for k in m.aqua.size():
				if m.aqua[k]!=null and m.aqua[k].sp==f.sp:pos=k
		if m.aqua[pos]!=null and m.aqua[pos].price>=f.price:continue
		if m.aqua[pos]!=null:
			m.V.aquarium.act(m.V,m,"take:%d"%pos)
		if m.aqua[pos]==null:m.V.aquarium.act(m.V,m,"put:%d"%j)
	var before_sale:int=m.gold
	m.sell_all();sale_income+=int(m.gold)-before_sale
func collect(m,region:int):
	while not m.capture_robot.fish.is_empty():
		var before=m.capture_robot.fish.size()
		m.capture_robot.transact(m,"collect")
		robot_count+=before-m.capture_robot.fish.size()
		process_bag(m,region)
		if before==m.capture_robot.fish.size():break
func buy(m, action:String):
	var before=int(m.gold)
	if action.begins_with("robot:"):m.capture_robot.transact(m,action.get_slice(":",1))
	elif action in ["pondcap","pondregen","aexpand","boat"]:m.FACILITIES.purchase(m,action)
	else:m.V._act(m,action)
	if m.gold<before:purchases.append({"h":elapsed/3600,"region":m.active_region,"action":action,"cost":before-m.gold,"left":m.gold})
func grow(m,region:int):
	if m.bait<5 and m.gold>=50:buy(m,"bait:0:10")
	if not m.capture_robot.owned:buy(m,"robot:buy")
	# Cheapest currently available regional facility/part upgrades first; retain bait cash.
	for iteration in 20:
		var choices:Array=[]
		for action in ["pondregen","pondcap","aexpand","boat"]:
			if m.FACILITIES.unlocked(m,action):choices.append([m.FACILITIES.cost(m,action),action])
		for slot in 4:
			if m.region_shop.part_key(region,slot) not in m.parts_owned:
				choices.append([m.region_shop.price(m,region,slot),"rpart:%d:%d"%[region,slot]]);break
		if m.rod_lv<region:choices.append([m.V.ROD_COST[m.rod_lv+1],"rod:%d"%(m.rod_lv+1)])
		var r=m.capture_robot
		if r.owned:
			if r.speed<r.COSTS.size() and r.can_level(m,r.GATES[r.speed+1]) and (not smart or r.RATES[r.speed+1]<=m.pond_recovery()*0.4):choices.append([r.COSTS[r.speed],"robot:speed"])
			if r.precision<3 and m.progression.licensed(r.precision+1):choices.append([r.PREC_COST[r.precision],"robot:precision"])
			if r.capacity<2:choices.append([r.CAP_COST[r.capacity],"robot:capacity"])
		if m.bag_lv<mini(region+1,m.BAG_PRICE.size()-1):choices.append([m.BAG_PRICE[m.bag_lv+1],"bag"])
		choices.sort_custom(func(a,b):return a[0]<b[0])
		if smart and m.pond_stock<m.pond_max()*0.3 and m.FACILITIES.unlocked(m,"pondregen"):
			choices.push_front([m.FACILITIES.cost(m,"pondregen"),"pondregen"])
		if choices.is_empty() or m.gold<choices[0][0]+50:break
		var before=m.gold
		buy(m,choices[0][1])
		if before==m.gold:break
	if m.bait<10 and m.gold>=500:buy(m,"bait:0:100")
func run():
	var argv=OS.get_cmdline_user_args()
	var m=Sim.new()
	m.SET.sfx=0;m.SET.music=0;m.SET.vib=false
	root.add_child(m);await process_frame;m.set_process(false)
	m.title_open=false;m.lesson_open=false;m.trans={};m.scene="fish";m.TUT.done=true;m.TUT.seen=m.BOOK_KEYS.duplicate()
	seed(int(argv[0]))
	var online:=0.0;var session:=0.0;var day:=1;var attempts:=0;var caught:=0;var quick:=0;var hooks:=0;var perf:=0
	var region:=0;var cert_time:=-1.0
	if argv.size()>2:session_length=float(argv[2])*3600
	if argv.size()>3:smart=argv[3]=="smart"
	var fd=FileAccess.open(argv[1],FileAccess.WRITE)
	while (region<3 or elapsed-region_start<3600*6 or m.boat_lv<6) and elapsed<3600*300:
		process_bag(m,region)
		collect(m,region)
		grow(m,region)
		if m.pond_stock<1.0:
			# Protect manual casting from robot fractional escrow starvation.
			m.capture_robot.enabled=false
			var wait=(1.0-m.pond_stock)*3600.0/m.pond_recovery()+0.001
			advance(m,wait);idle+=wait;stage_idle+=wait
			m.capture_robot.enabled=m.capture_robot.owned
		var start=m.clock
		m.start_cast();m.start_wait()
		m.clock=m.S.biteAt+randf_range(0.18,0.68)
		m.press(Vector2(160,300))
		if m.S.phase=="hook":
			hooks+=1;quick+=int(m.S.quickHook)
			m.S.pos=0.5+randfn(0,0.047);m.hook_tap();perf+=int(m.S.judge=="PERFECT")
			m.start_fight()
			var t:=0.0;var next_read:=0.0;var hold:=true
			while m.S.phase=="fight" and t<180:
				if t>=next_read:
					next_read=t+0.22
					var b=m.S.cloneSub if m.S.beh=="clone" else m.S.beh
					hold=b not in ["tell","run","nose","dive","rise","jump"] and m.S.spike<=0
					if b=="circle":hold=sin(m.S.circA)>0
					if b=="thrash":hold=sin(m.S.thT*(9+4*m.S.F))<=0.4
					if b=="sulk":hold=fmod(t,1)<0.3
					if m.S.slack>2.8 and b!="jump":hold=true
					if m.S.tension>80:hold=false
					if m.S.landUntil>m.clock and not m.S.jumpUsed:m.press(Vector2(160,300))
				m.holding=hold;m.clock+=0.08;t+=0.08;m.update_fight(0.08)
			if m.S.phase=="fight":m.fail("timeout")
			if m.S.phase=="caught":
				caught+=1
				m.keep_fish()
		attempts+=1
		var dt=m.clock-start+10.0
		advance(m,dt);m.clock+=10
		if session_time>=session_length:
			days+=1;session_time=0
			var earning:int=int(m.aqua_rate()*m.AQUARIUM_OFFLINE_HOURS*60)
			aqua_offline+=earning;m.gold+=earning
			m.pond_stock=minf(m.pond_max(),m.pond_stock+m.pond_recovery()*8)
		if region<3 and m.progression.licensed(region+1) and cert_time<0:cert_time=elapsed/3600
		if region<3 and m.progression.licensed(region+1) and m.gold>=m.spots.PRICES[region+1] and m.region_shop.unlock(m,region+1):
			var row={"from":region,"to":region+1,"day":days,"total_h":elapsed/3600,"stage_h":(elapsed-region_start)/3600,"cert_h":cert_time,"stage_idle_h":stage_idle/3600,"attempts":attempts,"caught":caught,"robot_caught":robot_count,"facilities":[m.pond_cap_lv,m.pond_regen_lv,m.aqua_lv,m.boat_lv],"robot":[m.capture_robot.speed,m.capture_robot.precision],"gold_after_unlock":m.gold,"aqua_hourly":m.aqua_rate()*60,"aqua_online":aqua_online,"aqua_offline":aqua_offline,"sale_income":sale_income,"bundle_income":bundle_income,"target_first_capture_h":{}}
			for sp in m.progression.MAIN_SPECIES[region]:row.target_first_capture_h[str(sp)]=first_species.get(str(sp),-1)
			fd.store_line(JSON.stringify(row));fd.flush();print("ENTRY ",row)
			region+=1;m.active_region=region;cert_time=-1;region_start=elapsed;stage_idle=0
	fd.store_line(JSON.stringify({"final_online_h":elapsed/3600,"rift_h":(elapsed-region_start)/3600,"final_boat":m.boat_lv,"final_passengers":m.V.passengers(m),"final_aqua_hourly":m.aqua_rate()*60,"aqua_online":aqua_online,"aqua_offline":aqua_offline,"sale_income":sale_income,"bundle_income":bundle_income,"final_gold":m.gold,"robot_caught":robot_count,"purchases":purchases,"idle_h":idle/3600,"session_h":session_length/3600,"reached_rift":region==3,"smart":smart}))
	var complete:bool=region==3 and m.boat_lv>=6
	fd.close();m.audio_feedback.dispose();m.queue_free();await process_frame;call_deferred("finish",complete)

func finish(complete:bool):
	await process_frame
	quit(0 if complete else 1)
