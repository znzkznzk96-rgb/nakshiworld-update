extends RefCounted
# View-only grouping. The original bag specimens and their individual values stay intact.
const PITCH := 50.0
var scroll := 0.0
var detail_scroll := 0.0
var viewport := Rect2()
var detail_viewport := Rect2()
var rows: Array=[]
var detail_indices: Array=[]
var groups_cache: Array=[]
var grouped_hash: int = 0
var grouped_valid := false
var regroup_count := 0
var image_bounds: Array=[]
var badge_bounds: Array=[]
var pointer := false
var dragged := false
var touch_index := -1
var last_touch := -1000
var start := Vector2.ZERO
var last := Vector2.ZERO
var detail_rects := {}
static func groups(items: Array) -> Array:
	var result: Array=[];var lookup: Dictionary={}
	for i in items.size():
		var f: Dictionary=items[i]
		var key: String="%d:%d"%[int(f.sp),int(f.grade)]
		if not lookup.has(key):
			lookup[key]=result.size();result.append({"sp":int(f.sp),"grade":int(f.grade),"indices":[],"min_weight":float(f.w),"max_weight":float(f.w)})
		var g: Dictionary=result[int(lookup[key])]
		g.indices.append(i);g.min_weight=minf(g.min_weight,float(f.w));g.max_weight=maxf(g.max_weight,float(f.w))
	return result
func reset() -> void:
	scroll=0;detail_scroll=0;pointer=false;dragged=false;touch_index=-1
	grouped_valid=false
func refresh_groups(items: Array) -> void:
	var fingerprint: int=items.hash()
	if grouped_valid and fingerprint==grouped_hash: return
	groups_cache=groups(items);grouped_hash=fingerprint;grouped_valid=true;regroup_count+=1
func weight(m,g: Dictionary) -> String:
	return m._wtxt(g.min_weight) if is_equal_approx(g.min_weight,g.max_weight) else "%s~%s"%[m._wtxt(g.min_weight),m._wtxt(g.max_weight)]
func badge(m, grade: int, r: Rect2) -> void:
	m._ui_style_box(m.sb_chip,r)
	m._ui_rect(Rect2(r.position+Vector2(7,5),Vector2(2,r.size.y-10)),m.GRADE_C[grade])
	var font: Font=m.fonts[0]
	var baseline: float=roundf(r.get_center().y+(font.get_ascent(10)-font.get_descent(10))/2.0)
	var center:=Vector2(r.get_center().x,baseline)
	m._text(m.GRADE_N[grade],center,10,Color("513b29"),true,r.size.x-18)
	badge_bounds.append({"rect":r,"text_center":center,"grade":grade})
func max_scroll(detail: bool=false) -> float:
	return maxf(0,detail_indices.size()*PITCH-detail_viewport.size.y) if detail else maxf(0,groups_cache.size()*PITCH-viewport.size.y)
func scrollbar(m, area: Rect2, offset: float, maximum: float, count: int) -> void:
	if maximum<=0: return
	var size: float=maxf(20,area.size.y*area.size.y/(count*PITCH))
	m._ui_rect(Rect2(area.end.x+2,area.position.y,2,area.size.y),Color("d3c39e"))
	m._ui_rect(Rect2(area.end.x+2,area.position.y+offset/maximum*(area.size.y-size),2,size),Color("9d7c4c"))
func draw(m) -> void:
	var inv=m.inventory
	var h: float=m.get_viewport_rect().size.y
	var height: float=minf(444,h-24)
	var r:=Rect2(10,floorf((h-height)/2),250,height)
	m.text_items=m.text_items.filter(func(it):return it[1].y<r.position.y-7)
	m._ui_rect(Rect2(-m.ox,0,270+2*m.ox,h),Color(0.04,0.06,0.1,0.78))
	var k: float=clampf((m.ui_clock-inv.opened_at)/0.24,0,1)
	var ease: float=1-pow(1-k,3)
	var scale:=Vector2(lerpf(0.88,1,ease),lerpf(0.06,1,ease))
	var first: int=m.text_items.size();var anchor:=r.get_center()
	m.ui_commands.append(["transform",anchor-anchor*scale,scale])
	m._ui_style_box(m.sb_panel,r)
	preload("res://addons/reservoir/ui_theme.gd").title(m,r,"가방")
	var close:=Rect2(r.end.x-31,r.position.y+9,22,23)
	m._ui_texture(m.icons.close,close.position)
	inv.rects={"panel":r,"close":close.grow(4),"cells":[]};inv.tab_rects.clear()
	for i in 3:
		var key: String=["fish","inventory","equipment"][i]
		var tr:=Rect2(r.position+Vector2(10+i*78,45),Vector2(74,25))
		m._ui_style_box(m.sb_btn if i==0 else m.sb_chip,tr)
		m._text(["물고기","인벤토리","장비"][i],tr.get_center()+Vector2(0,4),10,Color("513b29"),true,70)
		inv.tab_rects[key]=tr
	refresh_groups(m.bag);rows=[];image_bounds=[];badge_bounds=[]
	m._text("보유 %d마리 · %d묶음"%[m.bag.size(),groups_cache.size()],r.position+Vector2(13,87),10,Color("513b29"),false,218)
	viewport=Rect2(r.position+Vector2(10,97),Vector2(230,r.size.y-144))
	scroll=clampf(scroll,0,max_scroll())
	if groups_cache.is_empty(): m._text("보관통이 비었어요",viewport.get_center(),11,Color("7c6448"),true,210)
	for i in groups_cache.size():
		var yy: float=viewport.position.y+i*PITCH-roundf(scroll)
		var row:=Rect2(viewport.position.x,yy,230,46)
		if row.position.y<viewport.position.y or row.end.y>viewport.end.y: continue
		var g: Dictionary=groups_cache[i]
		m._ui_style_box(m.sb_chip,row)
		var image_box:=Rect2(row.position+Vector2(12,6),Vector2(34,34))
		var actual: Rect2=m._ui_fish(int(g.sp),image_box)
		image_bounds.append({"row":row,"box":image_box,"image":actual})
		m._text(m.FISH_NAME[int(g.sp)],row.position+Vector2(54,16),11,Color("382619"),false,166)
		badge(m,int(g.grade),Rect2(row.position+Vector2(54,22),Vector2(58,20)))
		m._text("%d마리"%g.indices.size(),row.position+Vector2(121,36),9,Color("513b29"),false,38)
		m._text(weight(m,g),Vector2(row.end.x-34,row.position.y+36),9,Color("7c6448"),true,64)
		rows.append({"rect":row,"sp":int(g.sp),"grade":int(g.grade)})
	scrollbar(m,viewport,scroll,max_scroll(),groups_cache.size())
	m._text("%s / %s"%[m._wtxt(m.bag_weight()),m._wtxt(m.bag_cap())],Vector2(135,r.end.y-27),10,Color("513b29"),true,226)
	m._text("위아래로 밀기 · 누르면 개체 정보",Vector2(135,r.end.y-11),9,Color("7c6448"),true,228)
	inv._finish(m,first,anchor,scale,k)
func press(m,p: Vector2) -> void:
	var inv=m.inventory
	if m.ui_clock-inv.opened_at<0.2: return
	if inv.rects.get("close",Rect2()).has_point(p) or not inv.rects.get("panel",Rect2()).has_point(p):
		m.market_open=false;inv.displayed=false;pointer=false;return
	for key in inv.tab_rects:
		if inv.tab_rects[key].has_point(p): inv.tab=key;m.equipment.page=0;pointer=false;return
	for row in rows:
		if row.rect.has_point(p): inv.open_group(row.sp,row.grade);pointer=false;return
func draw_detail(m) -> void:
	var inv=m.inventory;var h: float=m.get_viewport_rect().size.y
	m.text_items=m.text_items.filter(func(it):return it[1].y<m.top_y+40)
	m._ui_rect(Rect2(-m.ox,0,270+2*m.ox,h),Color(0.025,0.04,0.07,0.82))
	var r:=Rect2(18,roundf(h/2)-170,234,340)
	m._ui_style_box(m.sb_panel,r)
	m._text(m.FISH_NAME[inv.selected],Vector2(135,r.position.y+27),13,Color("382619"),true,210)
	badge(m,inv.selected_grade,Rect2(106,r.position.y+36,58,20))
	m._ui_fish(inv.selected,Rect2(85,r.position.y+61,100,42))
	detail_indices=[]
	for i in m.bag.size():
		var f: Dictionary=m.bag[i]
		if int(f.sp)==inv.selected and int(f.grade)==inv.selected_grade: detail_indices.append(i)
	m._text("보유 %d마리"%detail_indices.size(),Vector2(135,r.position.y+117),10,Color("513b29"),true,210)
	detail_viewport=Rect2(29,r.position.y+129,210,150)
	detail_scroll=clampf(detail_scroll,0,max_scroll(true))
	for i in detail_indices.size():
		var yy: float=detail_viewport.position.y+i*PITCH-roundf(detail_scroll)
		var row:=Rect2(detail_viewport.position.x,yy,210,45)
		if row.position.y<detail_viewport.position.y or row.end.y>detail_viewport.end.y: continue
		var f: Dictionary=m.bag[int(detail_indices[i])]
		m._ui_style_box(m.sb_chip,row)
		m._text("%d번 · %.1fcm"%[i+1,float(f.get("len",0))],row.position+Vector2(8,16),10,Color("513b29"),false,122)
		m._text(m._wtxt(float(f.w)),row.position+Vector2(172,16),10,Color("513b29"),true,58)
		m._text("판매가 %d 비늘"%int(f.get("price",0)),row.position+Vector2(8,34),9,Color("7c6448"),false,192)
	scrollbar(m,detail_viewport,detail_scroll,max_scroll(true),detail_indices.size())
	var stats:=Rect2(31,r.end.y-43,102,27);var close:=Rect2(139,r.end.y-43,99,27)
	for button in [stats,close]: m._ui_style_box(m.sb_btn,button)
	m._text("도감 통계",stats.get_center()+Vector2(0,4),10,Color("513b29"),true,94)
	m._text("닫기",close.get_center()+Vector2(0,4),11,Color("513b29"),true,91)
	detail_rects={"panel":r,"stats":stats,"close":close}
func detail_press(inv,p: Vector2) -> void:
	if detail_rects.get("stats",Rect2()).has_point(p): inv.selected_grade=-1;pointer=false;return
	if detail_rects.get("close",Rect2()).has_point(p) or not detail_rects.get("panel",Rect2()).has_point(p): inv.selected=-1;inv.selected_grade=-1;pointer=false
func move_scroll(delta: float, detail: bool) -> void:
	if detail: detail_scroll=clampf(detail_scroll+delta,0,max_scroll(true))
	else: scroll=clampf(scroll+delta,0,max_scroll())
func input_event(m,e: InputEvent) -> bool:
	return m.inventory.input_event(m,e)
