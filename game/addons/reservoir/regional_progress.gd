extends RefCounted
# Undefined design values stay absent. No fallback bundle or owner-gain value.
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
func serialize() -> Dictionary:
	return {"certificates":certificates,"main_completed":main_completed,"owner_gauge":owner_gauge,"donations":donations}
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
