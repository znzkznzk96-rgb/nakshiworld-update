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
	opened=true;region=clampi(m.active_region,0,1);selected=-1;trophy=0
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
	m._ui_style_box(m.sb_btn if active else m.sb_chip,r)
	m._text(label,r.get_center()+Vector2(0,4),10,INK,true,r.size.x-8)
func draw(m, h: float) -> void:
	if not opened: return
	m.text_items=[];m.ui_commands=[]
	m._ui_rect(Rect2(-m.ox,0,270+2*m.ox,h),Color(.04,.06,.1,.78))
	var height: float=minf(444,h-24)
	var r:=Rect2(10,floorf((h-height)/2),250,height)
	m._ui_style_box(m.sb_panel,r)
	preload("res://addons/reservoir/ui_theme.gd").title(m,r,"도감")
	var close:=Rect2(r.end.x-31,r.position.y+9,22,23)
	m._ui_texture(m.icons.close,close.position)
	rects={"close":close.grow(4),"regions":[],"fish":[],"tabs":[],"back":Rect2()}
	for area in 3:
		var b:=Rect2(r.position+Vector2(13+area*76,46),Vector2(72,25))
		button(m,b,["저수지","계곡","병사"][area],region==area)
		rects.regions.append(b)
	if region==2: draw_soldiers(m,r);return
	if selected<0: draw_collection(m,r)
	else: draw_trophy(m,r)
func draw_collection(m,r: Rect2) -> void:
	var count:=0
	for sp in range(region*20,region*20+20):
		if not best(m,sp,"grade").is_empty() or not best(m,sp,"length").is_empty(): count+=1
	m._text("발견 %d / 20종"%count,r.position+Vector2(15,88),10,INK,false,210)
	for i in 20:
		var sp: int=region*20+i
		var f: Dictionary=best(m,sp,"grade")
		var seen: bool=not f.is_empty() or not best(m,sp,"length").is_empty()
		var cell:=Rect2(r.position+Vector2(13+i%4*57,98+floori(i/4.0)*57),Vector2(53,53))
		m._ui_style_box(m.sb_chip,cell)
		if seen:
			m._ui_fish(sp,Rect2(cell.position+Vector2(5,4),Vector2(43,22)))
			m._text(m.FISH_NAME[sp],Vector2(cell.get_center().x,cell.position.y+35),8,INK,true,47)
			if not f.is_empty(): m._ui_rect(Rect2(cell.position+Vector2(8,49),Vector2(37,2)),m.GRADE_C[int(f.grade)])
		else:
			m._text("?",Vector2(cell.get_center().x,cell.position.y+26),16,MUTED,true,44)
			m._text("미발견",Vector2(cell.get_center().x,cell.position.y+43),8,MUTED,true,47)
		rects.fish.append([cell,sp])
	m._text("물고기를 누르면 나의 최고 기록",Vector2(135,r.end.y-38),9,MUTED,true,226)
	m._text("판매·기증 후에도 기록은 남아요",Vector2(135,r.end.y-20),9,MUTED,true,226)
func draw_soldiers(m,r: Rect2) -> void:
	var data=m.expedition.data
	m._text("제작 %d / 15종"%data.discovered.size(),r.position+Vector2(15,88),10,INK,false,210)
	if selected>=0 and data.is_discovered(selected):
		var spec: Dictionary=data.catalog.soldiers[selected]
		m._text(spec.name,Vector2(135,r.position.y+118),13,INK,true,220)
		var showcase:=Rect2(r.position+Vector2(35,133),Vector2(180,112))
		m._ui_style_box(m.sb_chip,showcase)
		m.expedition.sprite(m,selected,showcase.grow(-12))
		m._text(m.expedition.ROLES[spec.role],Vector2(135,r.position.y+266),11,INK,true,216)
		m._text(spec.description,Vector2(135,r.position.y+291),10,INK,true,220)
		m._text("어혼 · %s + %s"%[data.ELEMENTS[int(spec.elements[0])],data.ELEMENTS[int(spec.elements[1])]],Vector2(135,r.position.y+320),10,MUTED,true,220)
		var back:=Rect2(77,r.end.y-39,116,26);button(m,back,"목록으로",true);rects.back=back
		return
	for id in 15:
		var seen: bool=data.is_discovered(id)
		var cell:=Rect2(r.position+Vector2(13+id%3*76,98+floori(id/3.0)*57),Vector2(72,53))
		m._ui_style_box(m.sb_chip,cell)
		if seen:
			m.expedition.sprite(m,id,Rect2(cell.position+Vector2(17,2),Vector2(38,33)))
			m._text(data.catalog.soldiers[id].name,Vector2(cell.get_center().x,cell.end.y-6),7,INK,true,66)
			rects.fish.append([cell,id])
		else:
			m._text("?",Vector2(cell.get_center().x,cell.position.y+25),17,MUTED,true,60)
			m._text("미제작",Vector2(cell.get_center().x,cell.end.y-6),8,MUTED,true,66)
	m._text("병사를 누르면 특징과 어혼 조합",Vector2(135,r.end.y-38),9,MUTED,true,226)
	m._text("합성 후에도 제작 기록은 남아요",Vector2(135,r.end.y-20),9,MUTED,true,226)

func draw_trophy(m,r: Rect2) -> void:
	var y: float=r.position.y+88
	var star:=0
	for tier in CATALOG.BY_STAR.size():
		if selected%20 in CATALOG.BY_STAR[tier]: star=tier+1
	var known: bool=not best(m,selected,"grade").is_empty() or not best(m,selected,"length").is_empty()
	m._text((m.FISH_NAME[selected] if known else "미발견 물고기")+" ★%d"%star,Vector2(26,y),12,INK,false,160)
	var total:=0
	for n in m.fish_counts(selected): total+=int(n)
	m._text("포획 %d"%total,Vector2(218,y),9,MUTED,true,56)
	for i in 3:
		var b:=Rect2(23+i*76,y+10,72,24)
		button(m,b,["최고 등급","최대 길이","최대 무게"][i],trophy==i);rects.tabs.append(b)
	var f: Dictionary=best(m,selected,TYPES[trophy])
	var showcase:=Rect2(23,y+42,224,126)
	m._ui_style_box(m.sb_chip,showcase)
	m._ui_style_box(m.hud_reference_style,Rect2(34,y+49,202,23))
	m._text(value(m,f,TYPES[trophy]),Vector2(135,y+65),13,Color("fff0d1"),true,188)
	if known: m._ui_fish(selected,Rect2(70,y+78,130,48))
	else: m._text("?",Vector2(135,y+109),25,MUTED,true,150)
	m._text(details(m,f),Vector2(135,y+144),9,INK,true,204)
	var date: String=str(f.get("date",""))
	m._text(date if date!="" else ("첫 기록을 기다리는 중" if f.is_empty() else "날짜 기록 없음"),Vector2(135,y+158),8,MUTED,true,200)
	var row_y: float=y+176
	for i in 3:
		if i==trophy: continue
		var other: Dictionary=best(m,selected,TYPES[i])
		m._ui_style_box(m.sb_chip,Rect2(23,row_y,224,35))
		m._text(["최고 개체 등급","최대 길이","최대 무게"][i],Vector2(33,row_y+14),9,INK,false,118)
		m._text(value(m,other,TYPES[i]),Vector2(207,row_y+15),11,INK,true,70)
		m._text(details(m,other),Vector2(33,row_y+28),8,MUTED,false,204)
		row_y+=39
	for i in 5:
		var b:=Rect2(23+i*45,y+260,43,23)
		m._ui_style_box(m.sb_chip,b)
		var acquired: bool=i in m.fish_grades(selected)
		m._ui_rect(Rect2(b.position+Vector2(6,4),Vector2(31,2)),m.GRADE_C[i] if acquired else Color("b8aa92"))
		m._text(m.GRADE_N[i],b.get_center()+Vector2(0,5),8,INK if acquired else MUTED,true,39)
	var back:=Rect2(77,r.end.y-39,116,26);button(m,back,"목록으로",true);rects.back=back
func press(m,p: Vector2) -> void:
	if rects.get("close",Rect2()).has_point(p): opened=false;return
	for i in rects.get("regions",[]).size():
		if rects.regions[i].has_point(p): region=i;selected=-1;trophy=0;return
	for row in rects.get("fish",[]):
		if row[0].has_point(p): selected=int(row[1]);trophy=0;m.play("ui");return
	for i in rects.get("tabs",[]).size():
		if rects.tabs[i].has_point(p): trophy=i;return
	if rects.get("back",Rect2()).has_point(p): selected=-1
func input_event(m,e: InputEvent) -> bool:
	if not opened: return false
	if e is InputEventScreenTouch and e.pressed:
		touch_time=Time.get_ticks_msec();press(m,e.position-Vector2(m.ox,0))
	elif e is InputEventMouseButton and e.button_index==MOUSE_BUTTON_LEFT and e.pressed and Time.get_ticks_msec()-touch_time>300: press(m,e.position-Vector2(m.ox,0))
	elif e is InputEventKey and e.pressed and e.keycode==KEY_ESCAPE: opened=false
	return true
