extends RefCounted
# Approved bundle and regional owner gauge rules. Reservoir and approved valley entry are available; later regions stay disabled.
const CATALOG = preload("res://addons/reservoir/regional_catalog.gd")
var available_regions: Array = [0,1]
var main_targets: Dictionary = {}
var certificates: Array = [false,false,false,false,false,false]
var main_completed: Array = [false,false,false,false,false,false]
var owner_gauge: Array = [0.0,0.0,0.0,0.0,0.0,0.0]
var donations: Dictionary = {}
var reward_claimed: Dictionary = {}

func restore(data: Dictionary) -> void:
	certificates = [false,false,false,false,false,false]
	main_completed = [false,false,false,false,false,false]
	owner_gauge = [0.0,0.0,0.0,0.0,0.0,0.0]
	for i in 6:
		if i < data.get("certificates",[]).size(): certificates[i] = bool(data.certificates[i])
		if i < data.get("main_completed",[]).size(): main_completed[i] = bool(data.main_completed[i])
		if i < data.get("owner_gauge",[]).size(): owner_gauge[i] = clampf(float(data.owner_gauge[i]),0.0,100.0)
	donations = data.get("donations",{}).duplicate(true)
	extra_donations=data.get("extra_donations",{}).duplicate(true)
	bundle_values=data.get("bundle_values",{}).duplicate(true)
	extra_completed=data.get("extra_completed",{}).duplicate(true)
	reward_claimed=data.get("reward_claimed",{}).duplicate(true)
	# Old automatic payouts are marked paid only when their completion flag existed.
	# A completed main bundle without its certificate is recoverable via Receive.
	if not data.has("reward_claimed"):
		for area in 2:
			for kind in 3:
				if bundle_done(area,kind): reward_claimed[bundle_key(area,kind)]=bool(certificates[area]) if kind==0 else true
	for area in 2:
		for kind in 3:
			var targets:=bundle_targets(area,kind)
			var counts:=bundle_counts(area,kind)
			var complete:=not targets.is_empty()
			for i in targets.size():
				if int(counts[i])<int(targets[i].count): complete=false
			if complete and not bundle_done(area,kind):
				if kind==0: main_completed[area]=true
				else: extra_completed[bundle_key(area,kind)]=true
				reward_claimed[bundle_key(area,kind)]=bool(certificates[area]) if kind==0 else false
		if bool(main_completed[area]) and not bool(certificates[area]): reward_claimed[bundle_key(area,0)]=false
func serialize() -> Dictionary:
	return {"reward_claimed":reward_claimed,"certificates":certificates,"main_completed":main_completed,"owner_gauge":owner_gauge,"donations":donations,"extra_donations":extra_donations,"bundle_values":bundle_values,"extra_completed":extra_completed}
func licensed(area: int) -> bool:
	return area == 0 or (area > 0 and area < 6 and bool(certificates[area-1]) and bool(main_completed[area-1]))
func all_parts(m, area: int) -> bool:
	for kind in ["float","hook","line","reel"]:
		if not m.region_shop.has_active(m,kind,area): return false
	return true
func owner_ready(m, area: int) -> bool:
	return area >= 0 and area < 6 and not CATALOG.by_star(area,4).is_empty() and all_parts(m,area) and float(owner_gauge[area]) >= 100.0
func fishing_event(m, area: int, event: String, grade: int = 0) -> void:
	if area < 0 or area >= 6 or event != "catch" or not all_parts(m,area): return
	var gain: float = [1.0, 1.0, 2.0, 3.0, 5.0][clampi(grade,0,4)]
	owner_gauge[area] = clampf(float(owner_gauge[area]) + gain,0.0,100.0)
func settle_owner(area: int, caught: bool) -> void:
	if area >= 0 and area < 6: owner_gauge[area] = 0.0 if caught else 70.0
func try_complete(area: int) -> bool:
	var key := str(area)
	var targets: Array = main_targets.get(key,[])
	if area < 0 or area > 5 or targets.is_empty(): return false
	var delivered: Array = donations.get(key,[])
	if delivered.size() != targets.size(): return false
	for i in targets.size():
		if int(delivered[i]) < int(targets[i].get("count",0)) or int(targets[i].get("count",0)) <= 0: return false
	main_completed[area] = true
	return true
func donate(m, area: int, bag_index: int, target_index: int) -> bool:
	return donate_bundle(m,area,0,bag_index,target_index)


const MAIN_SPECIES = [[1,3,8,9,14,17],[21,24,28,31,34,37]]
const SUB_SPECIES = [[0,2,5,6,10,15],[20,23,25,22,32,36]]
const SOUL_REWARD = [15,30]
var extra_donations: Dictionary = {}
var bundle_values: Dictionary = {}
var extra_completed: Dictionary = {}
func _init() -> void:
	for area in 2:
		var list: Array=[]
		for sp in MAIN_SPECIES[area]: list.append({"species":CATALOG.key(sp),"grade":0,"count":1})
		main_targets[str(area)]=list
func bundle_targets(area: int, kind: int) -> Array:
	if area<0 or area>1: return []
	if kind==0: return main_targets.get(str(area),[])
	var result: Array=[]
	var species: Array=SUB_SPECIES[area] if kind==1 else [area*20+19]
	if kind not in [1,2]: return []
	for sp in species: result.append({"species":CATALOG.key(sp),"grade":0,"count":1})
	return result
func bundle_key(area: int, kind: int) -> String: return "%d:%d"%[area,kind]
func bundle_counts(area: int, kind: int) -> Array:
	var result: Array=donations.get(str(area),[]).duplicate() if kind==0 else extra_donations.get(bundle_key(area,kind),[]).duplicate()
	while result.size()<bundle_targets(area,kind).size(): result.append(0)
	return result
func bundle_done(area: int, kind: int) -> bool:
	if area<0 or area>1: return false
	return bool(main_completed[area]) if kind==0 else bool(extra_completed.get(bundle_key(area,kind),false))
func matching_bag(m, area: int, kind: int, target_index: int) -> Array:
	var targets: Array=bundle_targets(area,kind)
	if target_index<0 or target_index>=targets.size() or bundle_done(area,kind): return []
	var target: Dictionary=targets[target_index]
	if int(bundle_counts(area,kind)[target_index])>=int(target.count): return []
	var result: Array=[]
	for i in m.bag.size():
		var f: Dictionary=m.bag[i]
		if CATALOG.key(int(f.sp))==str(target.species) and int(f.grade)>=int(target.grade): result.append(i)
	return result
func claimed(area: int, kind: int) -> bool:
	return bool(reward_claimed.get(bundle_key(area,kind),false))
func _donate_one(m, area: int, kind: int, bag_index: int, target_index: int) -> bool:
	if bag_index not in matching_bag(m,area,kind,target_index): return false
	var key:=bundle_key(area,kind)
	var delivered:=bundle_counts(area,kind)
	var fish: Dictionary=m.bag[bag_index]
	delivered[target_index]=int(delivered[target_index])+1
	if kind==0: donations[str(area)]=delivered
	else: extra_donations[key]=delivered
	bundle_values[key]=int(bundle_values.get(key,0))+maxi(0,int(fish.get("price",0)))
	m.bag.remove_at(bag_index)
	var ready:=true
	var targets:=bundle_targets(area,kind)
	for i in targets.size():
		if int(delivered[i])<int(targets[i].count): ready=false
	if ready:
		if kind==0: main_completed[area]=true
		else: extra_completed[key]=true
	return true
func donate_bundle(m, area: int, kind: int, bag_index: int, target_index: int) -> bool:
	var old:=serialize().duplicate(true)
	var bag: Array=m.bag.duplicate(true)
	if not _donate_one(m,area,kind,bag_index,target_index): return false
	if m._save_game(): return true
	restore(old);m.bag=bag
	return false
func donation_plan(m, area: int, kind: int) -> Array:
	var plan: Array=[]
	var targets:=bundle_targets(area,kind)
	var counts:=bundle_counts(area,kind)
	for target in targets.size():
		var matches:=matching_bag(m,area,kind,target)
		matches.sort_custom(func(a,b):
			if int(m.bag[a].grade)!=int(m.bag[b].grade): return int(m.bag[a].grade)<int(m.bag[b].grade)
			return int(m.bag[a].get("price",0))<int(m.bag[b].get("price",0)))
		for i in mini(matches.size(),maxi(0,int(targets[target].count)-int(counts[target]))):
			plan.append({"target":target,"index":int(matches[i]),"fish":m.bag[matches[i]].duplicate(true)})
	return plan
func donate_all(m, area: int, kind: int, expected: Array=[]) -> int:
	var plan:=donation_plan(m,area,kind)
	if plan.is_empty() or (not expected.is_empty() and plan!=expected): return 0
	var old:=serialize().duplicate(true)
	var bag: Array=m.bag.duplicate(true)
	# Descending indices preserve the exact specimens shown in the confirmation.
	plan.sort_custom(func(a,b): return int(a.index)>int(b.index))
	for item in plan:
		if not _donate_one(m,area,kind,int(item.index),int(item.target)):
			restore(old);m.bag=bag;return 0
	if m._save_game(): return plan.size()
	restore(old);m.bag=bag
	return 0
func claim_reward(m, area: int, kind: int) -> bool:
	if not bundle_done(area,kind) or claimed(area,kind): return false
	var old:=serialize().duplicate(true)
	var gold: int=m.gold;var souls: int=m.souls;var pearl: int=m.pearl
	if kind==0: certificates[area]=true
	else:
		m.gold+=roundi(int(bundle_values.get(bundle_key(area,kind),0))*(1.2 if kind==1 else 1.5))
		if kind==1: m.souls+=SOUL_REWARD[area]
		else: m.pearl+=2
	reward_claimed[bundle_key(area,kind)]=true
	if m._save_game(): return true
	restore(old);m.gold=gold;m.souls=souls;m.pearl=pearl
	return false
