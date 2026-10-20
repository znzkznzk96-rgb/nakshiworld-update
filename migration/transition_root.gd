extends Node2D

const BUILD_CODE := 60
const BUILD_NAME := "0.60"
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

func _ready() -> void:
	font = load("res://font/neodgm.ttf")
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
	http.timeout = 180.0
	http.download_file = PATCH + ".new"
	http.request_completed.connect(_on_patch.bind(int(d.code), str(d.get("name", ""))))
	if http.request(UPDATE_BASE + "patch.pck?v=" + str(d.code)) != OK:
		_start()

func _on_patch(result: int, code: int, _h: PackedStringArray, _b: PackedByteArray, ver: int, vname: String) -> void:
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
		var f := FileAccess.open(PATCH_VER, FileAccess.WRITE)
		if f:
			f.store_string("%d|%s" % [ver, vname])
	elif FileAccess.file_exists(candidate):
		DirAccess.remove_absolute(candidate)
	_start()

func _process(_dt: float) -> void:
	if http and http.get_body_size() > 0:
		progress = float(http.get_downloaded_bytes()) / http.get_body_size()
	if status != "":
		queue_redraw()

func _draw() -> void:
	if status == "":
		return
	var r := get_viewport_rect()
	draw_rect(r, Color("2b2026"))
	draw_string(font, Vector2(0, r.size.y / 2 - 8), status, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 16, Color("f6e7c8"))
	if progress >= 0:
		draw_rect(Rect2(35, r.size.y / 2 + 8, 200, 6), Color("5a3a22"))
		draw_rect(Rect2(35, r.size.y / 2 + 8, int(200 * progress), 6), Color("ffcf4a"))

func _start() -> void:
	if started:
		return
	started = true
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
