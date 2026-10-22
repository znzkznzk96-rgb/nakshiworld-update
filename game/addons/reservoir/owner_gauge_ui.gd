extends RefCounted
# Functional layout with approved existing fish sprites; NOT newly generated PixelLab art.
const REGIONS = ["동네 저수지","거꾸로 폭포 계곡","타일 바다","균열 해역","심해","우주 바다"]
const ACCENTS = [Color("56c6d1"),Color("76d9ab"),Color("62c2e8"),Color("c28bef"),Color("5ea8cf"),Color("c4a3f5")]
var bounds := Rect2()
var image_bounds := Rect2()
var fill_bounds := Rect2()
var warning_bounds := Rect2()
func visible(m) -> bool:
	return m.scene == "fish" and not m.title_open and m.TUT.done and m.active_region >= 0 and m.active_region < 6 and m.progression.all_parts(m,m.active_region)
func draw(m) -> void:
	bounds=Rect2();image_bounds=Rect2();fill_bounds=Rect2();warning_bounds=Rect2()
	if not visible(m): return
	var area: int=m.active_region
	var value: float=clampf(float(m.progression.owner_gauge[area]),0,100)
	var color: Color=ACCENTS[area]
	bounds=Rect2(8,m.top_y+73,254,31)
	m._ui_rect(bounds,Color("191d29"))
	m._ui_rect(Rect2(bounds.position+Vector2(1,1),bounds.size-Vector2(2,2)),Color("61513e"))
	m._ui_rect(Rect2(bounds.position+Vector2(3,3),bounds.size-Vector2(6,6)),Color("242c35"))
	var owners: Array=m.CATALOG.by_star(area,4)
	var name: String="주인의 기척"
	if not owners.is_empty():
		var sp: int=int(owners[0]);name=m.FISH_NAME[sp]
		image_bounds=m._ui_fish(sp,Rect2(bounds.position+Vector2(7,5),Vector2(34,21)))
	var label: String="%s · %d%%"%[name,int(value)]
	m._text(label,bounds.position+Vector2(47,13),9,Color("fff0d1"),false,198)
	var track:=Rect2(bounds.position+Vector2(47,19),Vector2(196,6))
	m._ui_rect(track,Color("111923"))
	fill_bounds=Rect2(track.position+Vector2(1,1),Vector2(floorf(194*value/100.0),4))
	if fill_bounds.size.x>0:
		m._ui_rect(fill_bounds,color)
		m._ui_rect(Rect2(fill_bounds.position,Vector2(fill_bounds.size.x,1)),color.lightened(0.3))
	if value>=100:
		m._ui_rect(Rect2(bounds.end.x-6,bounds.position.y+5,2,2),Color("fff1a0"))
	if m.S.phase == "pre" and m.S.get("owner",false): warning(m,area,name,color)
func warning(m,area: int,name: String,color: Color) -> void:
	warning_bounds=Rect2(12,m.top_y+130,246,62)
	m._ui_rect(warning_bounds,Color("231a27"))
	m._ui_rect(Rect2(warning_bounds.position+Vector2(2,2),warning_bounds.size-Vector2(4,4)),Color("7f413b"))
	m._ui_rect(Rect2(warning_bounds.position+Vector2(4,4),warning_bounds.size-Vector2(8,8)),Color("291f2c"))
	m._text("경고 · 주인 등장",Vector2(135,warning_bounds.position.y+18),12,Color("ffd397"),true,224)
	m._text(REGIONS[area],Vector2(135,warning_bounds.position.y+35),10,Color("fff0d1"),true,224)
	m._text(name,Vector2(135,warning_bounds.position.y+51),12,color,true,224)
