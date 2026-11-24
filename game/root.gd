extends Node2D

const BUILD_CODE := 123
const BUILD_NAME := "1.23"
const UPDATE_BASE := "https://nakshiworld-update-kr.znzkznzk96.workers.dev/"
## 업데이트 방식: 버전마다 압축 파일(patch.pck) 하나. APK에 든 파일과 달라진 파일(코드·자주 바뀌는 데이터)만 들어 있다.
## 켜기 화면에서 버전 정보(version.json)를 한 번 읽고, 새 버전이면 받는다. 시간 안에 끝나면 바로, 아니면 게임을 시작한 채 백그라운드로 받고 다음 실행 때 적용한다.
const UPD_DIR := "user://upd/"
const CUR := "user://upd/current.pck"
const CUR_VER := "user://upd/current.ver"
const NEXT := "user://upd/next.pck"
const NEXT_VER := "user://upd/next.ver"
const PART := "user://upd/part.pck"
const WAIT_SECONDS := 5.0
var update_art: Texture2D
var chase_frames:Array[Texture2D]=[]
var chase_fish:Texture2D
var updater_logo:Texture2D
var animation_time:=0.0
var update_phase:="checking"
var received_bytes:=0
var total_bytes:=-1
var preview_only:=false
var loader_draw_scale:=1.0
var loader_draw_offset:=Vector2.ZERO
var box: SubViewportContainer
var http: HTTPRequest
var status := ""
var progress := -1.0
var shown_bar := 0.0   # 화면에 보이는 게이지: 실제 받기가 순식간에 끝나도 부드럽게 끝까지 차오른다
var font: Font
var expected_hash := ""
var expected_size := 0
var started := false
var want_code:=0
var want_name:=""
var fetching:=false
var wait_deadline_msec:=0
const MINIMUM_SPLASH_SECONDS:=2.0
var splash_started_msec:=Time.get_ticks_msec()
var boot_timings:Dictionary={}

func _ready() -> void:
	splash_started_msec=Time.get_ticks_msec()
	font = load("res://font/neodgm.ttf").duplicate(true)
	update_art = load("res://art/ui/update_cat_blue.png")
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	for i in 9:chase_frames.append(load("res://art/ui/updater/cat_run_%02d.png"%i))
	chase_fish=load("res://art/ui/updater/fish.png")
	updater_logo=load("res://art/ui/updater/logo.png")
	if preview_only:
		status="업데이트 확인 중…"
		return
	if "--shot" in OS.get_cmdline_user_args():
		_start()
		return
	status = "업데이트 확인 중…"
	DirAccess.make_dir_recursive_absolute(UPD_DIR)
	_drop_legacy()
	_apply_pending()
	http = HTTPRequest.new()
	http.timeout = 4.0
	add_child(http)
	http.request_completed.connect(_on_version)
	if http.request(UPDATE_BASE + "version.json") != OK:
		_start()

## 예전 방식(전체 patch.pck)으로 받아 둔 파일은 새 APK에 이미 들어 있어 필요 없다
func _drop_legacy() -> void:
	for f in ["user://patch.pck", "user://patch_ver.txt", "user://patch.pck.new", "user://patch.pck.bak", "user://patch_ver.txt.new"]:
		if FileAccess.file_exists(f): DirAccess.remove_absolute(f)

static func _read_ver(path: String) -> Array:
	if not FileAccess.file_exists(path): return [0, ""]
	var t := FileAccess.get_file_as_string(path).strip_edges()
	return [int(t.get_slice("|", 0)), t.get_slice("|", 1) if t.contains("|") else ""]

func _local_code() -> int:
	return maxi(BUILD_CODE, _read_ver(CUR_VER)[0]) if FileAccess.file_exists(CUR) else BUILD_CODE

func _local_name() -> String:
	return _read_ver(CUR_VER)[1] if _local_code() > BUILD_CODE else BUILD_NAME

## 지난번에 다 받아 확인까지 끝낸 새 버전이 있으면 지금(켜기 화면)에 적용한다
func _apply_pending() -> void:
	if not (FileAccess.file_exists(NEXT) and FileAccess.file_exists(NEXT_VER)): return
	if _read_ver(NEXT_VER)[0] <= _local_code():
		DirAccess.remove_absolute(NEXT); DirAccess.remove_absolute(NEXT_VER); return
	status = "업데이트 중…"; update_phase = "applying"
	if FileAccess.file_exists(CUR): DirAccess.remove_absolute(CUR)
	if DirAccess.rename_absolute(NEXT, CUR) == OK and DirAccess.rename_absolute(NEXT_VER, CUR_VER) == OK: return
	for f in [CUR, CUR_VER, NEXT, NEXT_VER]:
		if FileAccess.file_exists(f): DirAccess.remove_absolute(f)

func _on_version(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	http.request_completed.disconnect(_on_version)
	var d = JSON.parse_string(body.get_string_from_utf8()) if result == HTTPRequest.RESULT_SUCCESS and code == 200 else null
	if not (d is Dictionary):
		update_phase="ready";status="기존 버전으로 시작합니다"
		_start()
		return
	want_code = int(d.get("code", 0))
	want_name = str(d.get("name", ""))
	expected_hash = str(d.get("sha256", "")).to_lower()
	expected_size = int(d.get("size", 0))
	if want_code <= _local_code() or (FileAccess.file_exists(NEXT_VER) and _read_ver(NEXT_VER)[0] >= want_code):
		update_phase="ready";status="최신 버전입니다 · 곧 시작합니다"
		_start()
		return
	if expected_hash.length() != 64 or expected_size <= 0 or expected_size > 200000000:
		_start()
		return
	update_phase="download";progress=-1;received_bytes=0;fetching=true
	status="업데이트 받는 중…"
	wait_deadline_msec=Time.get_ticks_msec()+int(WAIT_SECONDS*1000)
	http.download_file=PART
	http.use_threads=true
	http.timeout=180.0
	http.body_size_limit=expected_size+4096
	http.request_completed.connect(_on_download)
	if http.request(UPDATE_BASE+"patch.pck?v="+str(want_code))!=OK:
		fetching=false
		_start()

## 다 받았을 때: 크기·파일 머리·sha256이 모두 맞을 때만 다음 적용 후보로 저장한다
func _on_download(result: int, code: int, _h: PackedStringArray, _b: PackedByteArray) -> void:
	http.request_completed.disconnect(_on_download)
	var valid := result == HTTPRequest.RESULT_SUCCESS and code == 200 and FileAccess.file_exists(PART)
	if valid:
		var f := FileAccess.open(PART, FileAccess.READ)
		valid = f != null and f.get_length() == expected_size and f.get_buffer(4) == PackedByteArray([71, 68, 80, 67])
		f = null
	if valid:
		if not started: update_phase="verifying";status="받은 파일 확인 중…"
		valid = await digest_file(self, PART) == expected_hash
	if valid:
		var vf := FileAccess.open(NEXT_VER + ".tmp", FileAccess.WRITE)
		valid = vf != null
		if valid:
			vf.store_string("%d|%s" % [want_code, want_name]); vf.flush(); valid = vf.get_error() == OK; vf = null
		if valid:
			if FileAccess.file_exists(NEXT): DirAccess.remove_absolute(NEXT)
			valid = DirAccess.rename_absolute(PART, NEXT) == OK and DirAccess.rename_absolute(NEXT_VER + ".tmp", NEXT_VER) == OK
	if not valid:
		for f in [PART, NEXT_VER + ".tmp"]:
			if FileAccess.file_exists(f): DirAccess.remove_absolute(f)
	fetching = false
	if not started:
		if valid: _apply_pending()
		else: status="업데이트를 받지 못했어요 · 기존 버전으로 시작합니다"
		_start()

static func digest_file(owner: Node, path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return ""
	var hash := HashingContext.new(); hash.start(HashingContext.HASH_SHA256)
	var tick := Time.get_ticks_usec(); var chunks := 0
	while f.get_position() < f.get_length():
		var chunk := f.get_buffer(524288)
		if chunk.is_empty(): return ""
		hash.update(chunk)
		chunks += 1
		if chunks >= 8 or Time.get_ticks_usec() - tick >= 3000:
			await owner.get_tree().process_frame
			tick = Time.get_ticks_usec(); chunks = 0
	return hash.finish().hex_encode()

func transfer_snapshot(received:int,declared_size:int,header_size:int=-1) -> Dictionary:
	var total:int=declared_size if declared_size>0 else header_size
	var count:int=maxi(0,received)
	return {"received":count,"total":total,"progress":clampf(float(count)/total,0,1) if total>0 else -1.0}

func transfer_detail() -> String:
	if update_phase=="checking":return "새로운 소식을 확인하고 있어요"
	if update_phase=="applying":return "새 버전을 적용하고 있어요"
	if update_phase=="verifying":return "다운로드 완료 · 파일 안전성을 확인하고 있어요"
	if update_phase=="ready":return "잠시 후 낚시월드로 이동해요"
	if update_phase=="loading":return "게임 화면과 장비를 준비하고 있어요"
	var total:int=expected_size if expected_size>0 else total_bytes
	if total<=0:return "%.1f MB 받음 · 전체 크기 확인 중"%(received_bytes/1000000.0)
	return "%d%%   %.1f / %.1f MB"%[int(clampf(progress,0,1)*100),received_bytes/1000000.0,total/1000000.0]

## 단계별로 게이지가 가야 할 곳(받는 단계는 실제 받은 비율을 따른다)
func _bar_target() -> float:
	match update_phase:
		"checking": return 0.15
		"download": return 0.2 + 0.6 * maxf(progress, 0.0) if progress >= 0.0 else 0.3
		"verifying": return 0.85
		"applying": return 0.92
	return 1.0

func _process(dt: float) -> void:
	animation_time+=maxf(dt,0.0)
	shown_bar=move_toward(shown_bar,_bar_target(),maxf(dt,0.0)*0.8)
	if fetching and update_phase=="download":
		received_bytes=http.get_downloaded_bytes()
		progress=clampf(float(received_bytes)/expected_size,0,1) if expected_size>0 else -1.0
		if not started and Time.get_ticks_msec()>wait_deadline_msec:
			_start()   # 시간 안에 못 끝나면 게임을 먼저 켜고, 받기는 뒤에서 계속한다(적용은 다음 실행)
	if status != "":queue_redraw()

func _pixel_panel(rect:Rect2) -> void:
	draw_rect(rect,Color("111c52"));draw_rect(rect.grow(-3),Color("fff5cc"))
	for point in [rect.position+Vector2(2,2),Vector2(rect.end.x-5,rect.position.y+2),Vector2(rect.position.x+2,rect.end.y-5),rect.end-Vector2(5,5)]:draw_rect(Rect2(point,Vector2(3,3)),Color("ffda24"))

func _label(text:String,y:float,font_size:int,color:Color) -> void:
	var width:float=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	draw_string(font,Vector2(roundf((270-width)*.5),roundf(y)),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func chase_positions(t:float,center:Vector2) -> Array[Vector2]:
	var angle:float=t*1.55
	return [center+Vector2(cos(angle)*48,sin(angle)*36),center+Vector2(cos(angle+2.0)*48,sin(angle+2.0)*36)]

func logo_motion(t:float) -> Vector2:
	var phase:float=t*TAU/3.6
	return Vector2(sin(phase)*deg_to_rad(1.5),cos(phase)*1.2)

func _draw_logo(height:float) -> void:
	var motion:Vector2=logo_motion(animation_time)
	var pivot:Vector2=Vector2(135,height*.20+motion.y)
	draw_set_transform(loader_draw_offset+pivot*loader_draw_scale,motion.x,Vector2.ONE*loader_draw_scale)
	draw_texture_rect(updater_logo,Rect2(-110,-37,220,74),false)
	draw_set_transform(loader_draw_offset,0,Vector2.ONE*loader_draw_scale)

func _chase_sprite(texture:Texture2D,position:Vector2,length:float,flip:bool,tilt:float) -> void:
	var h:float=length*texture.get_height()/texture.get_width()
	draw_set_transform(loader_draw_offset+position.round()*loader_draw_scale,tilt,Vector2(-1 if flip else 1,1)*loader_draw_scale)
	draw_texture_rect(texture,Rect2(Vector2(-length*.5,-h*.5),Vector2(length,h)),false)
	draw_set_transform(loader_draw_offset,0,Vector2.ONE*loader_draw_scale)

func _draw() -> void:
	if status=="" or font==null:return
	var size:Vector2=get_viewport_rect().size
	var scale:float=minf(size.x/270.0,size.y/400.0)
	var height:float=size.y/scale
	var offset:Vector2=Vector2((size.x-270*scale)*.5,0)
	loader_draw_scale=scale;loader_draw_offset=offset
	draw_rect(Rect2(Vector2.ZERO,size),Color("078bfa"))
	draw_set_transform(offset,0,Vector2.ONE*scale)
	# Bright pixel sky, green islands and saturated turquoise water.
	var horizon:float=height*.36
	draw_rect(Rect2(0,horizon,270,height-horizon),Color("08bed0"))
	for band in 5:draw_rect(Rect2(0,horizon+band*(height-horizon)/5,270,(height-horizon)/5+1),[Color("12ccda"),Color("0dc5d6"),Color("08bed0"),Color("08b6cb"),Color("0bafc7")][band])
	for cloud in [[Vector2(24,height*.075),1.0],[Vector2(202,height*.10),.65],[Vector2(226,height*.27),.60]]:
		var p:Vector2=cloud[0];var k:float=cloud[1]
		for piece in [Rect2(-14,0,48,7),Rect2(-5,-7,32,9),Rect2(4,-13,15,9)]:
			draw_rect(Rect2((p+piece.position*k).round(),(piece.size*k).round()),Color("ffffff"))
		draw_rect(Rect2((p+Vector2(-10,5)*k).round(),Vector2(41,3)*k),Color("a9e9fa"))
	for side in 2:
		for i in 7:
			var x:float=i*9 if side==0 else 270-i*9-9
			var tall:int=8+int(sin(i*.65+.2)*15)
			draw_rect(Rect2(x,horizon-tall,10,tall),Color("087f72"))
			draw_rect(Rect2(x,horizon-tall,6,4),Color("7be44b"))
	draw_rect(Rect2(0,horizon-1,56,2),Color("ffe6a2"));draw_rect(Rect2(222,horizon-1,48,2),Color("ffe6a2"))
	draw_rect(Rect2(0,horizon,270,1),Color("a0f7e6"))
	for i in 24:
		var x:float=fposmod(i*47+animation_time*(2 if i%2 else -2),290)-10
		draw_rect(Rect2(roundf(x),horizon+12+(i*23)%int(height*.57),7+i%4*4,1),Color("b9ffff",.3 if i%3 else .65))
	_draw_logo(height)
	var center:Vector2=Vector2(135,height*.47)
	for i in 48:
		var angle:float=i*TAU/48
		var p:Vector2=(center+Vector2(cos(angle)*48,sin(angle)*36)).round()
		draw_rect(Rect2(p,Vector2(1,1)),Color("e5ffff",.35))
	var positions:Array[Vector2]=chase_positions(animation_time,center)
	for i in 5:
		var angle:float=animation_time*1.55-.15-i*.12
		draw_rect(Rect2((center+Vector2(cos(angle)*48,sin(angle)*36)+Vector2(0,10)).round(),Vector2(2,1)),Color("ffffff",.8-i*.12))
	if chase_fish:_chase_sprite(chase_fish,positions[1],46,sin(animation_time*1.55+2.0)>0,0)
	if not chase_frames.is_empty():_chase_sprite(chase_frames[int(animation_time*10)%chase_frames.size()],positions[0],80,sin(animation_time*1.55)>0,0)
	var panel:Rect2=Rect2(21,height*.66,228,101)
	_pixel_panel(panel)
	_label(status,panel.position.y+23,11,Color("111c52"))
	var bar:Rect2=Rect2(35,panel.position.y+37,200,10)
	draw_rect(bar,Color("111c52"));draw_rect(bar.grow(-1),Color("15275b"))
	if shown_bar>0.0:draw_rect(Rect2(bar.position+Vector2.ONE,Vector2(198*clampf(shown_bar,0,1),8)),Color("ffda24"))
	_label(transfer_detail(),panel.position.y+66,9,Color("223b66"))
	_label("잠시만 기다려 주세요",panel.position.y+85,8,Color("426581"))
	draw_set_transform(Vector2.ZERO)

func _start() -> void:
	if started:
		return
	started = true
	if update_phase!="ready":
		update_phase="loading";status="게임 준비 중…"
	queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	var mount_tick:=Time.get_ticks_msec()
	if FileAccess.file_exists(CUR) and _local_code() > BUILD_CODE:
		if not ProjectSettings.load_resource_pack(CUR, true):
			get_tree().root.set_meta("ver", BUILD_NAME)
		else:
			get_tree().root.set_meta("ver", _local_name())
	else:
		get_tree().root.set_meta("ver", BUILD_NAME)
	boot_timings["mount_ms"]=Time.get_ticks_msec()-mount_tick
	var load_tick:=Time.get_ticks_msec()
	var script:Script
	var requested:int=ResourceLoader.load_threaded_request("res://main.gd","Script",true)
	if requested==OK:
		while ResourceLoader.load_threaded_get_status("res://main.gd")==ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
		if ResourceLoader.load_threaded_get_status("res://main.gd")==ResourceLoader.THREAD_LOAD_LOADED:
			script=ResourceLoader.load_threaded_get("res://main.gd")
	if script==null:script=load("res://main.gd")
	boot_timings["script_ms"]=Time.get_ticks_msec()-load_tick
	box = SubViewportContainer.new()
	box.modulate.a=0
	box.stretch = true
	box.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sv := SubViewport.new()
	sv.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	box.add_child(sv)
	add_child(box)
	var hires := Node2D.new()   # 폰 실제 해상도로 그려야 하는 연출(슬롯 등)용 층: 게임 화면 위, 글자 층 아래
	hires.add_to_group("hires_layer")
	hires.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(hires)
	var txt := Node2D.new()
	txt.set_script(load("res://text_layer.gd"))
	txt.modulate.a=0
	add_child(txt)
	_fit()
	get_viewport().size_changed.connect(_fit)
	var m := Node2D.new()
	m.set_script(script)
	m.text_layer = txt
	m.cooperative_boot=true
	var init_tick:=Time.get_ticks_msec()
	sv.add_child(m)
	while not m.boot_ready:await get_tree().process_frame
	boot_timings["game_ready_ms"]=Time.get_ticks_msec()-init_tick
	await get_tree().process_frame
	var remaining:float=MINIMUM_SPLASH_SECONDS-float(Time.get_ticks_msec()-splash_started_msec)/1000.0
	if remaining>0:await get_tree().create_timer(remaining).timeout
	var reveal:=create_tween().set_parallel(true)
	reveal.tween_property(box,"modulate:a",1.0,.3)
	reveal.tween_property(txt,"modulate:a",1.0,.3)
	reveal.tween_property(self,"self_modulate:a",0.0,.3)
	await reveal.finished
	status="";queue_redraw()

func _fit() -> void:
	box.size = get_viewport_rect().size
