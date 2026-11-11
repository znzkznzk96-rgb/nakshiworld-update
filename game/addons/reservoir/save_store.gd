extends RefCounted
# Same-directory rename commits complete JSON. Backup is only for corrupted/missing primary.
static func write(path: String, data: Dictionary) -> bool:
	if data.has("region_shop"):
		var previous := read(path)
		data = data.duplicate()
		recover_unlocks(data, previous)
	var tmp:=path+".tmp"
	var f:=FileAccess.open(tmp,FileAccess.WRITE)
	if f==null: return false
	f.store_string(JSON.stringify(data));f.flush()
	var ok: bool=f.get_error()==OK;f.close()
	if not ok: return false
	if FileAccess.file_exists(path):
		var old=JSON.parse_string(FileAccess.get_file_as_string(path))
		if old is Dictionary:
			var err:=DirAccess.copy_absolute(path,path+".bak")
			if err!=OK: return false
	return DirAccess.rename_absolute(tmp,path)==OK
static func read(path: String) -> Dictionary:
	var primary: Dictionary={}
	var backup: Dictionary={}
	for candidate in [path,path+".bak"]:
		if not FileAccess.file_exists(candidate): continue
		var data=JSON.parse_string(FileAccess.get_file_as_string(candidate))
		if data is Dictionary:
			if candidate==path: primary=data
			else: backup=data
	if primary.is_empty():
		primary = backup
		backup = {}
	recover_unlocks(primary, backup)
	if not backup.is_empty() and (primary.has("regional_progress") or backup.has("regional_progress")):
		primary["regional_progress"]=recover_bundles(primary.get("regional_progress",{}),backup.get("regional_progress",{}))
	return primary
# Purchased locations are permanent. A saved visit also proves the preceding route.
static func recover_unlocks(current: Dictionary, previous: Dictionary) -> void:
	if not current.has("region_shop") and not previous.has("region_shop"): return
	var shop: Dictionary = current.get("region_shop", {}) if current.get("region_shop", {}) is Dictionary else {}
	var highest := 0
	for snapshot in [current, previous]:
		var saved = snapshot.get("region_shop", {})
		var evidence: Array = [snapshot.get("active_region", 0)]
		if saved is Dictionary and saved.get("unlocked") is Array:
			evidence.append_array(saved.unlocked)
		for value in evidence:
			if typeof(value) in [TYPE_INT, TYPE_FLOAT] and value == int(value) and value >= 0 and value < 6:
				highest = maxi(highest, int(value))
	shop = shop.duplicate()
	shop["unlocked"] = range(highest + 1)
	current["region_shop"] = shop

static func recover_bundles(current: Dictionary, previous: Dictionary) -> Dictionary:
	const Progress=preload("res://addons/reservoir/regional_progress.gd")
	var now=Progress.new();now.restore(current)
	var old=Progress.new();old.restore(previous)
	var result: Dictionary=now.serialize().duplicate(true)
	for area in 4:
		result.certificates[area]=bool(result.certificates[area]) or bool(old.certificates[area])
		result.main_completed[area]=bool(result.main_completed[area]) or bool(old.main_completed[area])
		for kind in 3:
			var key: String=now.bundle_key(area,kind)
			var counts: Array=now.bundle_counts(area,kind)
			var prior: Array=old.bundle_counts(area,kind)
			for i in counts.size(): counts[i]=maxi(int(counts[i]),int(prior[i]))
			if prior.any(func(value): return int(value)>0):
				if kind==0: result.donations[str(area)]=counts
				else: result.extra_donations[key]=counts
			if old.bundle_done(area,kind) and kind>0: result.extra_completed[key]=true
			if old.claimed(area,kind): result.reward_claimed[key]=true
			if old.bundle_values.has(key): result.bundle_values[key]=maxi(int(now.bundle_values.get(key,0)),int(old.bundle_values.get(key,0)))
	var merged=Progress.new();merged.restore(result)
	return merged.serialize()
