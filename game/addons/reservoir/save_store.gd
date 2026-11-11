extends RefCounted
# Same-directory rename commits complete JSON. Backup is only for corrupted/missing primary.
static func write(path: String, data: Dictionary) -> bool:
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
	if primary.is_empty(): return backup
	if not backup.is_empty() and (primary.has("regional_progress") or backup.has("regional_progress")):
		primary["regional_progress"]=recover_bundles(primary.get("regional_progress",{}),backup.get("regional_progress",{}))
	return primary
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
