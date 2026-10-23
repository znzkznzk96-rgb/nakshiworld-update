extends "res://main.gd"
# Preview only. Uses the live game's styles, icons, fish renderer and text layer.
var dex_variant := 0
const PREVIEW_INK := Color("513b29")
const PREVIEW_MUTED := Color("7c6448")
func label_at(s: String, x: float, y: float, size: int = 10, width: float = 220, center: bool = false) -> void:
	_text(s, Vector2(x,y), size, PREVIEW_INK, center, width)
func plate(r: Rect2, s: String, selected: bool = false) -> void:
	_ui_style_box(sb_btn if selected else sb_chip,r)
	label_at(s,r.get_center().x,r.get_center().y+4,10,r.size.x-8,true)
func record_row(y: float, title: String, value: String, detail: String, grade: int) -> void:
	var r := Rect2(23,y,224,37)
	_ui_style_box(sb_chip,r)
	_ui_rect(Rect2(30,y+7,2,23),GRADE_C[grade])
	label_at(title,38,y+14,9,110)
	label_at(value,209,y+15,12,65,true)
	_text(detail,Vector2(38,y+29),8,PREVIEW_MUTED,false,198)
func _draw_overlays(t: float, h: float) -> void:
	super._draw_overlays(t,h)
	text_items = []; ui_commands = []
	_ui_rect(Rect2(0,0,270,h),Color(.04,.06,.1,.78))
	var r := Rect2(10,48,250,444)
	_ui_style_box(sb_panel,r)
	preload("res://addons/reservoir/ui_theme.gd").title(self,r,"물고기 도감")
	_ui_texture(icons.close,Vector2(229,57))
	plate(Rect2(23,94,110,25),"동네 저수지",true)
	plate(Rect2(137,94,110,25),"거꾸로 폭포 계곡")
	match dex_variant:
		0: collection()
		1: trophy()
		2: journal()
	_text("검토 시안 · 수치와 날짜는 예시",Vector2(135,478),8,PREVIEW_MUTED,true,225)
	if text_layer:
		text_layer.items = text_items; text_layer.commands = ui_commands; text_layer.queue_redraw()
func collection() -> void:
	label_at("발견 14 / 20종",25,135,10,120)
	_text("물고기 선택",Vector2(211,135),9,PREVIEW_MUTED,true,70)
	var species := [1,0,2,3,8,9,17,19]
	for i in 8:
		var cell := Rect2(23+i%4*57,143+floori(i/4.0)*50,53,46)
		_ui_style_box(sb_btn if i==0 else sb_chip,cell)
		if i < 6:
			_ui_fish(species[i],Rect2(cell.position+Vector2(6,4),Vector2(41,24)))
			label_at(FISH_NAME[species[i]],cell.get_center().x,cell.position.y+38,8,47,true)
		else:
			label_at("?",cell.get_center().x,cell.position.y+24,16,40,true)
			_text("미발견",Vector2(cell.get_center().x,cell.position.y+38),8,PREVIEW_MUTED,true,47)
	_ui_style_box(hud_reference_style,Rect2(23,248,224,25))
	_text("붕어  ★1",Vector2(80,265),12,Color("fff0d1"),true,100)
	_text("128마리 포획",Vector2(197,265),9,Color("fff0d1"),true,88)
	_ui_fish(1,Rect2(31,279,79,35))
	label_at("나의 최고 기록",124,295,11,118)
	_text("기록마다 다른 한 마리",Vector2(124,310),8,PREVIEW_MUTED,false,119)
	record_row(321,"최고 개체 등급","신화","35.8cm · 705g · 10.21",4)
	record_row(362,"최대 길이","43.2cm","레어 · 619g · 10.23",1)
	record_row(403,"최대 무게","737g","전설 · 41.6cm · 10.22",3)
	_text("판매·기증해도 기록은 남아요",Vector2(135,459),9,PREVIEW_MUTED,true,226)
func trophy() -> void:
	label_at("붕어 ★1",27,139,13,120)
	_text("누적 128마리",Vector2(204,139),9,PREVIEW_MUTED,true,85)
	for i in 3: plate(Rect2(23+i*76,148,72,24),["최고 등급","최대 길이","최대 무게"][i],i==0)
	_ui_style_box(sb_chip,Rect2(23,180,224,139))
	_ui_style_box(hud_reference_style,Rect2(34,188,202,23))
	_text("나의 신화 붕어",Vector2(135,204),12,Color("fff0d1"),true,190)
	_ui_fish(1,Rect2(60,221,150,59))
	label_at("35.8cm · 705g",135,296,12,200,true)
	_text("10.21 · 동네 저수지",Vector2(135,310),8,PREVIEW_MUTED,true,200)
	record_row(328,"최대 길이","43.2cm","레어 · 619g · 10.23",1)
	record_row(369,"최대 무게","737g","전설 · 41.6cm · 10.22",3)
	label_at("만나 본 등급",26,426,10,130)
	for i in 5:
		var x: float=24+i*45
		_ui_style_box(sb_chip,Rect2(x,433,42,26))
		_ui_rect(Rect2(x+6,438,30,2),GRADE_C[i])
		label_at(GRADE_N[i],x+21,452,8,38,true)
func journal() -> void:
	_ui_style_box(sb_chip,Rect2(23,128,224,62))
	_ui_fish(1,Rect2(32,137,70,38))
	label_at("붕어 ★1",115,151,13,125)
	_text("첫 만남 10.03 · 128마리",Vector2(115,172),8,PREVIEW_MUTED,false,125)
	for i in 3:
		var x: float=23+i*76
		_ui_style_box(sb_chip,Rect2(x,199,72,51))
		label_at(["최고 등급","최대 길이","최대 무게"][i],x+36,215,9,65,true)
		label_at(["신화","43.2cm","737g"][i],x+36,236,12,66,true)
	label_at("나의 기록 경신",26,271,11,220)
	for i in 3: plate(Rect2(23+i*76,280,72,24),["길이","무게","등급"][i],i==0)
	var dates := ["10.23","10.18","10.09"]
	var values := ["43.2cm","40.7cm","35.8cm"]
	var details := ["레어 · 619g · +2.5cm","유니크 · 518g · +4.9cm","레어 · 282g · 새 기록"]
	for i in 3:
		var y: float=313+i*45
		_ui_style_box(sb_chip,Rect2(23,y,224,41))
		label_at(dates[i],34,y+15,9,54)
		label_at(values[i],121,y+16,13,118)
		_text(details[i],Vector2(34,y+31),8,PREVIEW_MUTED,false,202)
	_text("최고 기록과 경신 이력을 함께 보관",Vector2(135,459),9,PREVIEW_MUTED,true,224)
