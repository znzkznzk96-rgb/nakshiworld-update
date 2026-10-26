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
	for candidate in [path,path+".bak"]:
		if FileAccess.file_exists(candidate):
			var data=JSON.parse_string(FileAccess.get_file_as_string(candidate))
			if data is Dictionary: return data
	return {}
