extends Node2D

const BUILD_CODE := 63
const BUILD_NAME := "0.63"
const UPDATE_BASE := "https://nakshiworld-update-kr.znzkznzk96.workers.dev/"
const PATCH := "user://patch.pck"
const PATCH_VER := "user://patch_ver.txt"
var box: SubViewportContainer
var http: HTTPRequest
var status := ""
var progress := -1.0
var font: Font
var expected_hash := ""
var expected_size := 0
var started := false
var update_screen = preload("res://addons/reservoir/update_screen.gd").new()
var update_phase := "check"
var update_version := ""
var downloaded_bytes := 0

func _ready() -> void:
	font = load("res://font/neodgm.ttf")
	update_screen.attach(self)
	if "--update-preview" in OS.get_cmdline_user_args():
		status = "업데이트 확인 중…"
		return
	if "--shot" in OS.get_cmdline_user_args():
		_start()
		return
	status = "업데이트 확인 중…"
	http = HTTPRequest.new()
	http.timeout = 8.0
	add_child(http)
	http.request_completed.connect(_on_version)
	if http.request(UPDATE_BASE + "version.json") != OK:
		_start()

func _local_code() -> int:
	if FileAccess.file_exists(PATCH) and FileAccess.file_exists(PATCH_VER):
		var f := FileAccess.open(PATCH_VER, FileAccess.READ)
		if f:
			return maxi(BUILD_CODE, int(f.get_as_text().get_slice("|", 0)))
	return BUILD_CODE

func _local_name() -> String:
	if _local_code() > BUILD_CODE:
		var f := FileAccess.open(PATCH_VER, FileAccess.READ)
		if f:
			var t := f.get_as_text()
			if t.contains("|"):
				return t.get_slice("|", 1)
	return BUILD_NAME

func _on_version(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	http.request_completed.disconnect(_on_version)
	var d = JSON.parse_string(body.get_string_from_utf8()) if result == HTTPRequest.RESULT_SUCCESS and code == 200 else null
	if not (d is Dictionary) or int(d.get("code", 0)) <= _local_code():
		_start()
		return
	expected_hash = str(d.get("sha256", "")).to_lower()
	expected_size = int(d.get("size", 0))
	if expected_hash.length() != 64 or expected_size <= 0:
		_start()
		return
	status = "새 버전 %s 받는 중…" % d.get("name", "")
	update_phase = "download"
	update_version = str(d.get("name", ""))
	downloaded_bytes = 0
	progress = 0
	http.timeout = 180.0
	http.download_file = PATCH + ".new"
	http.request_completed.connect(_on_patch.bind(int(d.code), str(d.get("name", ""))))
	if http.request(UPDATE_BASE + "patch.pck?v=" + str(d.code)) != OK:
		_start()

func _on_patch(result: int, code: int, _h: PackedStringArray, _b: PackedByteArray, ver: int, vname: String) -> void:
	update_phase = "verify"
	progress = 1.0 if result == HTTPRequest.RESULT_SUCCESS and code == 200 else progress
	queue_redraw()
	await get_tree().process_frame
	var candidate := PATCH + ".new"
	var valid := result == HTTPRequest.RESULT_SUCCESS and code == 200 and FileAccess.file_exists(candidate)
	if valid:
		var f := FileAccess.open(candidate, FileAccess.READ)
		valid = f != null and f.get_length() == expected_size
		f = null
	if valid:
		valid = FileAccess.get_sha256(candidate) == expected_hash
	if valid:
		var header := FileAccess.open(candidate, FileAccess.READ)
		valid = header != null and header.get_buffer(4) == PackedByteArray([71, 68, 80, 67])
		header = null
	if valid and DirAccess.rename_absolute(candidate, PATCH) == OK:
		update_phase = "apply"
		queue_redraw()
		await get_tree().process_frame
		var f := FileAccess.open(PATCH_VER, FileAccess.WRITE)
		if f:
			f.store_string("%d|%s" % [ver, vname])
	elif FileAccess.file_exists(candidate):
		DirAccess.remove_absolute(candidate)
	_start()

func _process(_dt: float) -> void:
	update_screen.advance(_dt)
	if http and update_phase == "download":
		downloaded_bytes = http.get_downloaded_bytes()
		var total: int = expected_size if expected_size > 0 else http.get_body_size()
		if total > 0:
			progress = clampf(float(downloaded_bytes) / total, 0, 1)
	if status != "":
		queue_redraw()

func _draw() -> void:
	if status != "":
		update_screen.draw(self)

func _start() -> void:
	if started:
		return
	started = true
	update_screen.dismiss()
	status = ""
	queue_redraw()
	if FileAccess.file_exists(PATCH) and _local_code() > BUILD_CODE:
		if not ProjectSettings.load_resource_pack(PATCH, true):
			get_tree().root.set_meta("ver", BUILD_NAME)
		else:
			get_tree().root.set_meta("ver", _local_name())
	else:
		get_tree().root.set_meta("ver", BUILD_NAME)
	box = SubViewportContainer.new()
	box.stretch = true
	box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sv := SubViewport.new()
	sv.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	box.add_child(sv)
	add_child(box)
	var txt := Node2D.new()
	txt.set_script(load("res://text_layer.gd"))
	add_child(txt)
	_fit()
	get_viewport().size_changed.connect(_fit)
	var m := Node2D.new()
	m.set_script(load("res://main.gd"))
	m.text_layer = txt
	sv.add_child(m)

func _fit() -> void:
	box.size = get_viewport_rect().size
