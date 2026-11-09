extends Node2D

const BUILD_CODE := 79
const BUILD_NAME := "0.79"
const UPDATE_BASE := "https://nakshiworld-update-kr.znzkznzk96.workers.dev/"
const PATCH := "user://patch.pck"
const PATCH_VER := "user://patch_ver.txt"
var update_art: Texture2D
var chase_frames:Array[Texture2D]=[]
var chase_fish:Texture2D
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
var font: Font
var expected_hash := ""
var expected_size := 0
var started := false

func _ready() -> void:
	font = load("res://font/neodgm.ttf")
	update_art = load("res://art/ui/update_cat_blue.png")
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	for i in 16:chase_frames.append(load("res://art/char/anim/cat/cat_%02d.png"%i))
	chase_fish=load("res://art/fish/l0_00.png")
	if preview_only:
		status="업데이트 확인 중…"
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
	update_phase="download";progress=-1;received_bytes=0
	status = "새 버전 %s 받는 중…" % d.get("name", "")
	http.timeout = 180.0
	http.download_file = PATCH + ".new"
	http.request_completed.connect(_on_patch.bind(int(d.code), str(d.get("name", ""))))
	if http.request(UPDATE_BASE + "patch.pck?v=" + str(d.code)) != OK:
		_start()

func _on_patch(result: int, code: int, _h: PackedStringArray, _b: PackedByteArray, ver: int, vname: String) -> void:
	update_phase="verifying";status="받은 파일 확인 중…";queue_redraw()
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

func transfer_snapshot(received:int,declared_size:int,header_size:int=-1) -> Dictionary:
	var total:int=declared_size if declared_size>0 else header_size
	var count:int=maxi(0,received)
	return {"received":count,"total":total,"progress":clampf(float(count)/total,0,1) if total>0 else -1.0}

func transfer_detail() -> String:
	if update_phase=="checking":return "새로운 소식을 확인하고 있어요"
	if update_phase=="verifying":return "파일 크기와 안전성을 확인하고 있어요"
	var total:int=expected_size if expected_size>0 else total_bytes
	if total<=0:return "%.1f MB 받음 · 전체 크기 확인 중"%(received_bytes/1000000.0)
	return "%d%%   %.1f / %.1f MB"%[int(clampf(progress,0,1)*100),received_bytes/1000000.0,total/1000000.0]

func _process(dt: float) -> void:
	animation_time+=minf(dt,.1)
	if update_phase=="download" and http:
		var data:Dictionary=transfer_snapshot(http.get_downloaded_bytes(),expected_size,http.get_body_size())
		received_bytes=data.received;total_bytes=data.total;progress=data.progress
	if status != "":queue_redraw()

func _pixel_panel(rect:Rect2) -> void:
	draw_rect(rect,Color("061c2b"));draw_rect(rect.grow(-1),Color("3d7a83"));draw_rect(rect.grow(-3),Color("102e3d"))
	for point in [rect.position,Vector2(rect.end.x-3,rect.position.y),Vector2(rect.position.x,rect.end.y-3),rect.end-Vector2(3,3)]:draw_rect(Rect2(point,Vector2(3,3)),Color("dfc886"))

func _label(text:String,y:float,font_size:int,color:Color) -> void:
	var width:float=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	draw_string(font,Vector2(roundf((270-width)*.5),roundf(y)),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func chase_positions(t:float,center:Vector2) -> Array[Vector2]:
	var angle:float=t*1.55
	return [center+Vector2(cos(angle)*43,sin(angle)*31),center+Vector2(cos(angle+.95)*43,sin(angle+.95)*31)]

func _chase_sprite(texture:Texture2D,position:Vector2,length:float,flip:bool,tilt:float) -> void:
	var h:float=length*texture.get_height()/texture.get_width()
	draw_set_transform(loader_draw_offset+position.round()*loader_draw_scale,tilt,Vector2.ONE*loader_draw_scale)
	draw_texture_rect(texture,Rect2(Vector2(length*.5 if flip else -length*.5,-h*.5),Vector2(-length if flip else length,h)),false)
	draw_set_transform(loader_draw_offset,0,Vector2.ONE*loader_draw_scale)

func _draw() -> void:
	if status=="" or font==null:return
	var size:Vector2=get_viewport_rect().size
	var scale:float=minf(size.x/270.0,size.y/400.0)
	var height:float=size.y/scale
	var offset:Vector2=Vector2((size.x-270*scale)*.5,0)
	loader_draw_scale=scale;loader_draw_offset=offset
	draw_rect(Rect2(Vector2.ZERO,size),Color("081b2c"))
	draw_set_transform(offset,0,Vector2.ONE*scale)
	# Quiet layered pixel water, with no stretched bitmap or random frame noise.
	for band in 12:draw_rect(Rect2(0,height*.34+band*height*.055,270,height*.055+1),Color("103446").lerp(Color("071c2e"),band/12.0))
	for i in 22:
		var x:int=(i*67+19)%270;var y:float=28+(i*37)%int(height*.28)
		draw_rect(Rect2(x,y,1 if i%3 else 2,1),Color("a6d0cf",.25+.2*sin(animation_time*.7+i)))
	var horizon:float=height*.37
	for i in 18:
		var tall:int=8+(i*17)%21
		draw_rect(Rect2(i*16,horizon-tall,17,tall+6),Color("163b4a"))
	draw_rect(Rect2(0,horizon+5,270,1),Color("4d9697",.55))
	for i in 16:
		var x:float=fposmod(i*47+animation_time*(1 if i%2 else -1),290)-10
		draw_rect(Rect2(roundf(x),horizon+18+(i*23)%int(height*.5),8+i%4*3,1),Color("6bb4b5",.10))
	draw_rect(Rect2(219,42,14,14),Color("d4e5c2"));draw_rect(Rect2(216,39,12,12),Color("081b2c"))
	_label("작은 물결, 새로운 이야기",height*.19,10,Color("8fc5c5"))
	_label("낚시월드",height*.19+38,29,Color("061723"))
	_label("낚시월드",height*.19+36,29,Color("f4e8c3"))
	var center:Vector2=Vector2(135,height*.47)
	for i in 48:
		var angle:float=i*TAU/48
		var p:Vector2=(center+Vector2(cos(angle)*43,sin(angle)*31)).round()
		draw_rect(Rect2(p,Vector2(1,1)),Color("78bab7",.25))
	var positions:Array[Vector2]=chase_positions(animation_time,center)
	for i in 5:
		var angle:float=animation_time*1.55-.15-i*.12
		draw_rect(Rect2((center+Vector2(cos(angle)*43,sin(angle)*31)+Vector2(0,10)).round(),Vector2(2,1)),Color("8fd6c2",.4-i*.06))
	if chase_fish:_chase_sprite(chase_fish,positions[1],22,sin(animation_time*1.55+.95)>0,0)
	if not chase_frames.is_empty():_chase_sprite(chase_frames[int(animation_time*9)%16],positions[0]+Vector2(0,-absf(sin(animation_time*9))*3),31,sin(animation_time*1.55)>0,sin(animation_time*9)*.055)
	var panel:Rect2=Rect2(21,height*.66,228,101)
	_pixel_panel(panel)
	_label(status,panel.position.y+23,11,Color("f2e7ca"))
	var bar:Rect2=Rect2(35,panel.position.y+37,200,10)
	draw_rect(bar,Color("061b27"));draw_rect(bar.grow(-1),Color("2d5261"))
	if update_phase=="download" and progress>=0:draw_rect(Rect2(bar.position+Vector2.ONE,Vector2(198*clampf(progress,0,1),8)),Color("b8e9b0"))
	else:
		var x:float=fposmod(animation_time*36,222)-24
		var begin:float=maxf(0,x);var finish:float=minf(198,x+24)
		if finish>begin:draw_rect(Rect2(bar.position+Vector2(1+begin,1),Vector2(finish-begin,8)),Color("b8e9b0"))
	_label(transfer_detail(),panel.position.y+66,9,Color("b6d8d7"))
	_label("잠시만 기다려 주세요",panel.position.y+85,8,Color("71999f"))
	draw_set_transform(Vector2.ZERO)

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
