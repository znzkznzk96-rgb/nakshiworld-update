extends RefCounted
# Approved bundle definitions; owner gauge gain and unreleased region entry remain undefined.
const CATALOG = preload("res://addons/reservoir/regional_catalog.gd")
var available_regions: Array = [0]
var main_targets: Dictionary = {}
var owner_rules: Dictionary = {}
var certificates: Array = [false,false,false,false,false,false]
var main_completed: Array = [false,false,false,false,false,false]
var owner_gauge: Array = [0.0,0.0,0.0,0.0,0.0,0.0]
var donations: Dictionary = {}

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
func serialize() -> Dictionary:
	return {"certificates":certificates,"main_completed":main_completed,"owner_gauge":owner_gauge,"donations":donations,"extra_donations":extra_donations,"bundle_values":bundle_values,"extra_completed":extra_completed}
func licensed(area: int) -> bool:
	return area == 0 or (area > 0 and area < 6 and bool(certificates[area-1]) and bool(main_completed[area-1]))
func all_parts(m, area: int) -> bool:
	for kind in ["float","hook","line","reel"]:
		if not m.region_shop.has_active(m,kind,area): return false
	return true
func owner_ready(m, area: int) -> bool:
	return area >= 0 and area < 2 and all_parts(m,area) and float(owner_gauge[area]) >= 100.0
func fishing_event(m, area: int, event: String) -> void:
	if area < 0 or area > 1 or not all_parts(m,area): return
	# Configuration is deliberately empty until the user sets the event and gain.
	var rule: Dictionary = owner_rules.get(str(area),{})
	if not rule.has("event") or not rule.has("gain"): return
	var expected: String = str(rule.event)
	if event != expected and not (expected == "completed" and event in ["catch","miss"]): return
	owner_gauge[area] = minf(100.0,float(owner_gauge[area]) + maxf(0.0,float(rule.gain)))
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
	main_completed[area] = true;certificates[area] = true
	return true
func donate(m, area: int, bag_index: int, target_index: int) -> bool:
	var key := str(area)
	var targets: Array = main_targets.get(key,[])
	if area < 0 or area > 5 or main_completed[area] or target_index < 0 or target_index >= targets.size(): return false
	if bag_index < 0 or bag_index >= m.bag.size(): return false
	var target: Dictionary = targets[target_index]
	var fish: Dictionary = m.bag[bag_index]
	if CATALOG.key(int(fish.sp)) != str(target.get("species","")) or int(fish.grade) < int(target.get("grade",0)): return false
	var delivered: Array = donations.get(key,[])
	while delivered.size() < targets.size(): delivered.append(0)
	if int(target.get("count",0)) <= 0 or int(delivered[target_index]) >= int(target.count): return false
	delivered[target_index] = int(delivered[target_index])+1;donations[key] = delivered
	m.bag.remove_at(bag_index);try_complete(area);m._save_game()
	return true


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
func donate_bundle(m, area: int, kind: int, bag_index: int, target_index: int) -> bool:
	if bag_index not in matching_bag(m,area,kind,target_index): return false
	if kind==0: return donate(m,area,bag_index,target_index)
	var key:=bundle_key(area,kind)
	var delivered:=bundle_counts(area,kind)
	var fish: Dictionary=m.bag[bag_index]
	delivered[target_index]=int(delivered[target_index])+1
	extra_donations[key]=delivered
	bundle_values[key]=int(bundle_values.get(key,0))+maxi(0,int(fish.get("price",0)))
	m.bag.remove_at(bag_index)
	var ready:=true
	var targets:=bundle_targets(area,kind)
	for i in targets.size():
		if int(delivered[i])<int(targets[i].count): ready=false
	if ready:
		extra_completed[key]=true
		# One atomic save includes removal, completion and rewards. No separate replayable claim.
		m.gold+=roundi(int(bundle_values[key])*(1.2 if kind==1 else 1.5))
		if kind==1: m.souls+=SOUL_REWARD[area]
		else: m.pearl+=2
		m.show_toast("번들 완료! 보상을 받았어요")
	m._save_game()
	return true
