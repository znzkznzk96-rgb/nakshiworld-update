extends RefCounted
# PixelLab frames; names, specimens and proportional fill remain engine-rendered.
const REGIONS = ["동네 저수지","거꾸로 폭포 계곡","타일 바다","균열 해역","심해","우주 바다"]
const ACCENTS = [Color("56c6d1"),Color("d66b82"),Color("62c2e8"),Color("c28bef"),Color("68bec5"),Color("c4a3f5")]
const FRAME_SIZE := Vector2(256,64)
var bounds := Rect2()
var image_bounds := Rect2()
var fill_bounds := Rect2()
var track_bounds := Rect2()
var label_bounds := Rect2()
var warning_bounds := Rect2()
var frames: Array[Texture2D]=[]
var layouts: Array=[]
func load_frames() -> void:
	if frames.size()==6: return
	layouts=JSON.parse_string(FileAccess.get_file_as_string("res://data/ui/owner_gauges.json"))
	for area in 6:frames.append(load("res://art/ui/owners/region_%d.png"%area))
func visible(m) -> bool:
	return m.scene == "fish" and not m.title_open and m.TUT.done and m.active_region >= 0 and m.active_region < 6 and m.progression.all_parts(m,m.active_region)
func clear_bounds() -> void:
	bounds=Rect2();image_bounds=Rect2();fill_bounds=Rect2();track_bounds=Rect2();label_bounds=Rect2();warning_bounds=Rect2()
func draw(m) -> void:
	clear_bounds()
	if not visible(m): return
	var area: int=m.active_region
	var value: float=clampf(float(m.progression.owner_gauge[area]),0,100)
	draw_frame(m,area,value,Vector2(7,m.top_y+73))
	if m.S.phase == "pre" and m.S.get("owner",false):
		var owners: Array=m.CATALOG.by_star(area,4)
		warning(m,area,m.FISH_NAME[int(owners[0])] if not owners.is_empty() else "주인",ACCENTS[area])
func local_rect(area: int,key: String) -> Rect2:
	var a: Array=layouts[area][key]
	return Rect2(a[0],a[1],a[2],a[3])
func draw_frame(m,area: int,value: float,origin: Vector2) -> void:
	load_frames();clear_bounds()
	if area<0 or area>=6: return
	value=clampf(value,0,100)
	bounds=Rect2(origin,FRAME_SIZE)
	m._ui_texture_rect(frames[area],bounds)
	var badge: Rect2=local_rect(area,"badge");badge.position+=origin
	label_bounds=local_rect(area,"label");label_bounds.position+=origin
	track_bounds=local_rect(area,"track");track_bounds.position+=origin
	var owners: Array=m.CATALOG.by_star(area,4)
	var name: String="주인의 기척"
	if not owners.is_empty():
		var sp: int=int(owners[0]);name=m.FISH_NAME[sp]
		image_bounds=m._ui_fish(sp,badge.grow(-3))
	var baseline: float=roundf(label_bounds.get_center().y+3)
	var percent: String="%d%%"%int(value)
	var percent_width: float=m._text_w(percent,9)
	m._text(name,Vector2(label_bounds.position.x,baseline),9,Color("fff0d1"),false,label_bounds.size.x-percent_width-7)
	m._text(percent,Vector2(label_bounds.end.x-percent_width,baseline),9,Color("fff0d1"))
	m._ui_rect(track_bounds,Color("0b111a"))
	var inner: Rect2=track_bounds.grow(-1)
	fill_bounds=Rect2(inner.position,Vector2(floorf(inner.size.x*value/100.0),inner.size.y))
	if fill_bounds.size.x>0:
		m._ui_rect(fill_bounds,ACCENTS[area])
		m._ui_rect(Rect2(fill_bounds.position,Vector2(fill_bounds.size.x,1)),ACCENTS[area].lightened(0.3))
func warning(m,area: int,name: String,color: Color) -> void:
	warning_bounds=Rect2(12,m.top_y+166,246,62)
	m._ui_rect(warning_bounds,Color("231a27"))
	m._ui_rect(Rect2(warning_bounds.position+Vector2(2,2),warning_bounds.size-Vector2(4,4)),Color("7f413b"))
	m._ui_rect(Rect2(warning_bounds.position+Vector2(4,4),warning_bounds.size-Vector2(8,8)),Color("291f2c"))
	m._text("경고 · 주인 등장",Vector2(135,warning_bounds.position.y+18),12,Color("ffd397"),true,224)
	m._text(REGIONS[area],Vector2(135,warning_bounds.position.y+35),10,Color("fff0d1"),true,224)
	m._text(name,Vector2(135,warning_bounds.position.y+51),12,color,true,224)
