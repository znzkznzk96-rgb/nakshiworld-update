extends RefCounted
# Permanent personal best specimens, independent of inventory and museum donations.
const CATALOG = preload("res://addons/reservoir/regional_catalog.gd")
const TYPES := ["grade","length","weight"]
const INK := Color("513b29")
const MUTED := Color("7c6448")
var records: Dictionary = {}
var opened := false
var region := 0
var selected := -1
var trophy := 0
var rects: Dictionary = {}
var touch_time := -1000
var scroll := 0.0
var role_filter := "all"
var list_view := Rect2()
var rows_total := 0
var visible_rows := 0
var pointer := false
var drag := false
var origin := Vector2.ZERO
var last := Vector2.ZERO
var touch_id := -1
var down_id := -1
var record_icons := {}
func restore(data: Dictionary) -> void:
	records = {}
	var source = data.get("records",{})
	if not source is Dictionary: return
	for sp in CATALOG.NAMES.size():
		var key: String=CATALOG.key(sp)
		var entry=source.get(key,{})
		if not entry is Dictionary: continue
		var clean := {}
		for kind in TYPES:
			var f=entry.get(kind,{})
			if not f is Dictionary or not f.has_all(["grade","len","w"]): continue
			var length: float=float(f.len);var weight: float=float(f.w);var grade: int=int(f.grade)
			if not is_finite(length) or not is_finite(weight) or length<=0 or weight<=0 or grade<0 or grade>4: continue
			clean[kind]={"grade":grade,"len":length,"w":weight,"date":str(f.get("date",""))}
		if not clean.is_empty(): records[key]=clean
func serialize() -> Dictionary: return {"version":1,"records":records.duplicate(true)}
func observe(sp: int, grade: int, length: float, weight: float, date: String) -> void:
	if sp<0 or sp>=CATALOG.NAMES.size() or grade<0 or grade>4 or not is_finite(length) or not is_finite(weight) or length<=0 or weight<=0: return
	var key: String=CATALOG.key(sp)
	var row: Dictionary=records.get(key,{})
	var fish := {"grade":grade,"len":length,"w":weight,"date":date}
	for kind in TYPES:
		var old: Dictionary=row.get(kind,{})
		var better: bool=old.is_empty()
		if not better:
			match kind:
				"grade": better=grade>int(old.grade) or (grade==int(old.grade) and length>float(old.len))
				"length": better=length>float(old.len)
				"weight": better=weight>float(old.w)
		if better: row[kind]=fish.duplicate()
	records[key]=row
func best(m, sp: int, kind: String) -> Dictionary:
	var row: Dictionary=records.get(CATALOG.key(sp),{})
	var f: Dictionary=row.get(kind,{}).duplicate()
	# Legacy grades/lengths remain authoritative; missing specimen details stay unknown.
	if kind=="grade":
		var highest: int=-1
		for value in m.fish_grades(sp): highest=maxi(highest,int(value))
		if highest>int(f.get("grade",-1)): return {"grade":highest,"legacy":true}
	elif kind=="length":
		var old: float=m.fish_record_cm(sp)
		if old>float(f.get("len",0)): return {"len":old,"legacy":true}
	return f
func open(m) -> void:
	opened=true;region=clampi(m.active_region,0,1);selected=-1;trophy=0;scroll=0;role_filter="all";cancel_pointer()
	m.menu_open=false;m.holding=false
func value(m, f: Dictionary, kind: String) -> String:
	if f.is_empty(): return "기록 없음"
	if kind=="grade": return m.GRADE_N[int(f.grade)]
	if kind=="length": return "%.1fcm"%float(f.len)
	return m._wtxt(float(f.w))
func details(m, f: Dictionary) -> String:
	if f.is_empty(): return "새로 잡으면 기록이 남아요"
	if f.get("legacy",false): return "이전 기록 · 개체 상세 없음"
	return "%s · %.1fcm · %s"%[m.GRADE_N[int(f.grade)],float(f.len),m._wtxt(float(f.w))]
func button(m, r: Rect2, label: String, active: bool=false) -> void:
	m._ui_style_box(m.sb_btn,r)
	if active:
		m._ui_rect(r.grow(-4),Color("08646b"))
		m._ui_rect(Rect2(r.position+Vector2(5,4),Vector2(r.size.x-10,1)),Color("48b6b2"))
	m._text(label,r.get_center()+Vector2(0,4),10,Color("fff0d1") if active else INK,true,r.size.x-10)
func maximum() -> float: return maxf(0,(rows_total-visible_rows)*52.0)
func cancel_pointer() -> void:
	pointer=false;drag=false;touch_id=-1;down_id=-1
func draw(m,h: float) -> void:
	if not opened:return
	m.text_items=[];m.ui_commands=[]
	m._ui_rect(Rect2(-m.ox,0,270+2*m.ox,h),Color(.04,.06,.1,.82))
	var height: float=minf(548,h-20)
	var r:=Rect2(8,floorf((h-height)/2),254,height)
	m._ui_style_box(m.sb_panel,r)
	preload("res://addons/reservoir/ui_theme.gd").title(m,r,"도감" if selected<0 else ("병사 도감" if region==2 else "물고기 도감"))
	var close:=Rect2(r.end.x-31,r.position.y+9,22,23);m._ui_texture(m.icons.close,close.position)
	rects={"close":close.grow(3),"regions":[],"fish":[],"tabs":[],"filters":[],"back":Rect2()}
	list_view=Rect2()
	if selected>=0:
		if region==2:draw_soldier_detail(m,r)
		else:draw_trophy(m,r)
		return
	for area in 3:
		var b:=Rect2(r.position+Vector2(13+area*77,46),Vector2(73,25))
		button(m,b,["저수지","계곡","병사"][area],region==area);rects.regions.append(b)
	draw_collection(m,r)
func draw_collection(m,r: Rect2) -> void:
	var ids: Array=[]
	var count:=0
	if region==2:
		count=m.expedition.data.discovered.size()
		for id in 15:
			if role_filter=="all" or (m.expedition.data.is_discovered(id) and m.expedition.data.catalog.soldiers[id].role==role_filter): ids.append(id)
		ids.sort_custom(func(a,b): return int(m.expedition.data.is_discovered(a))>int(m.expedition.data.is_discovered(b)) if m.expedition.data.is_discovered(a)!=m.expedition.data.is_discovered(b) else a<b)
	else:
		for sp in range(region*20,region*20+20):
			ids.append(sp)
			if not best(m,sp,"grade").is_empty() or not best(m,sp,"length").is_empty():count+=1
	m._text(("제작 %d / 15종" if region==2 else "발견 %d / 20종")%count,r.position+Vector2(15,88),10,INK,false,126)
	var progress:=Rect2(r.position+Vector2(143,79),Vector2(96,7))
	m._ui_rect(progress,Color("d4c4a0"));m._ui_rect(Rect2(progress.position,Vector2(progress.size.x*count/(15.0 if region==2 else 20.0),7)),Color("228b82"))
	var y: float=r.position.y+100
	if region==2:
		for i in 4:
			var b:=Rect2(r.position.x+13+i*58,y,54,24)
			button(m,b,["전체","공격","방어","지원"][i],role_filter==["all","attack","defense","support"][i]);rects.filters.append(b)
		y+=31
	rows_total=ids.size();visible_rows=maxi(1,floori((r.end.y-34-y)/52.0));scroll=clampf(scroll,0,maximum())
	list_view=Rect2(r.position.x+13,y,225,visible_rows*52)
	var start:=floori(scroll/52.0)
	for i in mini(visible_rows,maxi(0,ids.size()-start)):
		var id: int=ids[start+i]
		var cell:=Rect2(list_view.position+Vector2(0,i*52),Vector2(222,48))
		m._ui_style_box(m.sb_chip,cell)
		var known: bool=m.expedition.data.is_discovered(id) if region==2 else (not best(m,id,"grade").is_empty() or not best(m,id,"length").is_empty())
		var icon:=Rect2(cell.position+Vector2(5,4),Vector2(42,38))
		if known:
			if region==2:m.expedition.sprite(m,id,icon)
			else:m._ui_fish(id,icon)
			var name: String=m.expedition.data.catalog.soldiers[id].name if region==2 else m.FISH_NAME[id]
			m._text(name,cell.position+Vector2(53,19),11,INK,false,153)
			if region==2:
				var role: String=m.expedition.data.catalog.soldiers[id].role
				m.expedition.symbol(m,role,Rect2(cell.position+Vector2(53,26),Vector2(14,14)))
				m._text(m.expedition.ROLES[role],cell.position+Vector2(72,37),10,Color(m.expedition.ROLE_COLORS[role]),false,110)
			else:
				var f: Dictionary=best(m,id,"grade")
				m._text("최고 "+value(m,f,"grade"),cell.position+Vector2(53,37),10,MUTED,false,145)
			m._text("›",cell.position+Vector2(211,29),14,MUTED,true,12)
			rects.fish.append([cell,id])
		else:
			m._text("?",icon.get_center()+Vector2(0,6),16,MUTED,true,35)
			m._text("미제작" if region==2 else "미발견",cell.position+Vector2(53,27),10,MUTED,false,150)
			if region!=2:rects.fish.append([cell,id])
	if ids.is_empty():m._text("발견한 병사가 없어요",Vector2(135,y+32),10,MUTED,true,220)
	if rows_total>visible_rows:
		var track:=Rect2(r.end.x-14,y,3,list_view.size.y-4)
		m._ui_rect(track,Color("d1bc91"))
		var thumb: float=maxf(12,track.size.y*visible_rows/rows_total)
		m._ui_rect(Rect2(track.position+Vector2(0,(track.size.y-thumb)*scroll/maximum()),Vector2(3,thumb)),Color("8d6037"))
	m._text("합성 후에도 제작 기록은 남아요" if region==2 else "판매·기증 후에도 기록은 남아요",Vector2(135,r.end.y-17),9,MUTED,true,230)
func back_button(m,r: Rect2) -> void:
	var b:=Rect2(r.position+Vector2(13,46),Vector2(64,23));button(m,b,"‹ 목록");rects.back=b
func record_icon(m,kind: String,box: Rect2) -> void:
	if not record_icons.has(kind):
		var path: String="res://art/ui/codex/%s.png"%kind
		if ResourceLoader.exists(path):record_icons[kind]=load(path)
	if record_icons.has(kind):m._ui_texture_rect(record_icons[kind],box,false)
func specimen(m,f: Dictionary,kind: String) -> String:
	if f.is_empty():return "아직 기록이 없어요"
	if f.get("legacy",false):return "길이·무게 기록 없음" if kind=="grade" else "등급·무게 기록 없음"
	match kind:
		"grade":return "%.1fcm · %s"%[float(f.len),m._wtxt(float(f.w))]
		"length":return "%s · %s"%[m.GRADE_N[int(f.grade)],m._wtxt(float(f.w))]
	return "%s · %.1fcm"%[m.GRADE_N[int(f.grade)],float(f.len)]
func draw_trophy(m,r: Rect2) -> void:
	back_button(m,r)
	var y: float=r.position.y+76
	var star:=0
	for tier in CATALOG.BY_STAR.size():
		if selected%20 in CATALOG.BY_STAR[tier]:star=tier+1
	var known: bool=not best(m,selected,"grade").is_empty() or not best(m,selected,"length").is_empty()
	var hero:=Rect2(21,y,228,78);m._ui_style_box(m.sb_chip,hero)
	if known:m._ui_fish(selected,Rect2(29,y+14,76,44))
	else:m._text("?",Vector2(67,y+46),24,MUTED,true,70)
	m._text(m.FISH_NAME[selected] if known else "미발견 물고기",Vector2(116,y+23),14,INK,false,124)
	m._text("★%d · %s"%[star,"저수지" if region==0 else "계곡"],Vector2(116,y+43),10,MUTED,false,124)
	var total:=0
	for n in m.fish_counts(selected):total+=int(n)
	m._text("총 포획 %d마리"%total,Vector2(116,y+62),10,INK,false,124)
	y+=86
	m._ui_style_box(m.sb_btn,Rect2(21,y,228,25));m._ui_rect(Rect2(26,y+4,218,17),Color("07515c"))
	m._text("나의 최고 기록",Vector2(135,y+17),11,Color("fff0d1"),true,210)
	y+=31
	var card_h: float=clampf((r.end.y-y-99)/3.0,48,62)
	for i in 3:
		var f: Dictionary=best(m,selected,TYPES[i])
		var card:=Rect2(21,y,228,card_h-4);m._ui_style_box(m.sb_chip,card)
		record_icon(m,["medal","ruler","weight"][i],Rect2(29,y+(card_h-4-25)/2,25,25))
		m._text(["최고 등급","최대 길이","최대 무게"][i],Vector2(62,y+18),11,INK,false,84)
		m._text(value(m,f,TYPES[i]),Vector2(204,y+20),14,Color("246da4") if i==0 and not f.is_empty() else INK,true,76)
		m._text(specimen(m,f,TYPES[i]),Vector2(62,y+35),9,MUTED,false,177)
		if card_h>=58 and not str(f.get("date","")).is_empty():m._text(str(f.date),Vector2(62,y+49),9,MUTED,false,177)
		y+=card_h
	m._text("기록마다 다른 물고기일 수 있어요",Vector2(135,y+10),9,MUTED,true,230);y+=23
	var grades: Array=m.fish_grades(selected)
	m._text("등급 수집 %d / 5"%grades.size(),Vector2(26,y+9),10,INK,false,220);y+=17
	for i in 5:
		var b:=Rect2(22+i*46,y,42,29)
		m._ui_style_box(m.sb_chip,b)
		var acquired: bool=i in grades
		m._ui_rect(Rect2(b.position+Vector2(5,4),Vector2(32,2)),m.GRADE_C[i] if acquired else Color("c9bfa9"))
		m._text(m.GRADE_N[i],b.get_center()+Vector2(0,2),9,INK if acquired else MUTED,true,38)
		if acquired:m._text("✓",Vector2(b.get_center().x,b.end.y-2),9,Color("247651"),true,30)
	m._text("판매·기증 후에도 기록은 남아요",Vector2(135,r.end.y-13),9,MUTED,true,230)
func draw_soldier_detail(m,r: Rect2) -> void:
	back_button(m,r)
	var data=m.expedition.data
	if not data.is_discovered(selected):selected=-1;return
	var spec: Dictionary=data.catalog.soldiers[selected]
	var y: float=r.position.y+78
	m._ui_style_box(m.sb_chip,Rect2(21,y,228,104))
	m.expedition.sprite(m,selected,Rect2(29,y+14,76,76))
	m._text(spec.name,Vector2(114,y+34),11,INK,false,125)
	m.expedition.symbol(m,spec.role,Rect2(115,y+50,16,16))
	m._text(m.expedition.ROLES[spec.role],Vector2(136,y+63),10,Color(m.expedition.ROLE_COLORS[spec.role]),false,96)
	y+=116
	m._ui_style_box(m.sb_chip,Rect2(21,y,228,84))
	m._text("병사 특징",Vector2(32,y+21),12,INK,false,205)
	m._text(m._ui_wrap(spec.description,10,202,3),Vector2(32,y+43),10,MUTED,false,202)
	y+=96
	m._ui_style_box(m.sb_chip,Rect2(21,y,228,72))
	m._text("어혼 조합",Vector2(32,y+21),12,INK,false,205)
	for i in 2:
		var el: int=int(spec.elements[i]);var x: float=46+i*104
		m._ui_texture_rect(m.expedition.textures[m.expedition.EFILES[el]],Rect2(x,y+32,23,23),false)
		m._text(data.ELEMENTS[el],Vector2(x+28,y+48),10,INK,false,60)
	m._text("+",Vector2(135,y+49),12,MUTED,true,20)
	m._text("합성 후에도 제작 기록은 남아요",Vector2(135,r.end.y-17),9,MUTED,true,230)
func hit_id(p: Vector2) -> int:
	for row in rects.get("fish",[]):
		if row[0].has_point(p):return int(row[1])
	return -1
func press(m,p: Vector2) -> void:
	if rects.get("close",Rect2()).has_point(p):opened=false;cancel_pointer();return
	for i in rects.get("regions",[]).size():
		if rects.regions[i].has_point(p):region=i;selected=-1;scroll=0;role_filter="all";cancel_pointer();return
	for i in rects.get("filters",[]).size():
		if rects.filters[i].has_point(p):role_filter=["all","attack","defense","support"][i];scroll=0;cancel_pointer();return
	if rects.get("back",Rect2()).has_point(p):selected=-1;cancel_pointer();return
	var id:=hit_id(p)
	if id>=0:selected=id;trophy=0;cancel_pointer();m.play("ui")
func begin(p: Vector2) -> void:
	pointer=true;drag=false;origin=p;last=p;down_id=hit_id(p)
func move(p: Vector2) -> void:
	if p.distance_to(origin)>5:drag=true
	if drag:scroll=clampf(scroll+last.y-p.y,0,maximum())
	last=p
func finish(m,p: Vector2) -> void:
	if not drag and down_id==hit_id(p):press(m,p)
	cancel_pointer()
func input_event(m,e: InputEvent) -> bool:
	if not opened:return false
	if e is InputEventKey and e.pressed and e.keycode==KEY_ESCAPE:
		if selected>=0:selected=-1
		else:opened=false
		cancel_pointer();return true
	if (e is InputEventMouseButton or e is InputEventMouseMotion) and (e.device==-1 or Time.get_ticks_msec()-touch_time<350):return true
	if e is InputEventScreenTouch:
		var p: Vector2=e.position-Vector2(m.ox,0);touch_time=Time.get_ticks_msec()
		if e.pressed and touch_id<0:
			if list_view.has_point(p):touch_id=e.index;begin(p)
			else:press(m,p)
		elif e.index==touch_id:
			if e.canceled:cancel_pointer()
			elif not e.pressed:finish(m,p)
	elif e is InputEventScreenDrag and e.index==touch_id:touch_time=Time.get_ticks_msec();move(e.position-Vector2(m.ox,0))
	elif e is InputEventMouseButton:
		var p: Vector2=e.position-Vector2(m.ox,0)
		if e.pressed and list_view.has_point(p) and e.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:scroll=clampf(scroll+(52 if e.button_index==MOUSE_BUTTON_WHEEL_DOWN else -52),0,maximum())
		elif e.button_index==MOUSE_BUTTON_LEFT:
			if e.pressed:
				if list_view.has_point(p):begin(p)
				else:press(m,p)
			elif pointer:finish(m,p)
	elif e is InputEventMouseMotion and pointer:move(e.position-Vector2(m.ox,0))
	return true
