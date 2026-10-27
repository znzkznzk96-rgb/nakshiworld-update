extends RefCounted
# Permanent personal best specimens, independent of inventory and museum donations.
const CATALOG = preload("res://addons/reservoir/regional_catalog.gd")
const TYPES := ["grade","length","weight"]
const INK := Color("513b29")
const MUTED := Color("7c6448")
var records: Dictionary = {}
var opened := false
var region := 0
var category := "fish"
var row_height := 52.0
const REGIONS := ["동네 저수지","거꾸로 폭포 계곡","타일 바다","균열 해역","심해","우주 바다"]
const SKILLS := {"pierce":"관통 공격","guard":"단단한 방어","poison":"독 공격","heal":"치유","regen":"지속 회복","shield":"보호막","splash":"광역 공격","stun":"기절","slow":"감속","execute":"마무리 공격","drain":"흡수","buff":"아군 강화","bolt":"번개 공격","counter":"반격","curse":"저주","flurry":"연속 공격","mend":"아군 치유","reflect":"피해 반사","thorns":"가시 반격","ward":"아군 보호","weaken":"적 약화"}
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
	opened=true;region=clampi(m.active_region,0,5);category="fish";selected=-1;trophy=0;scroll=0;role_filter="all";cancel_pointer()
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
func maximum() -> float: return maxf(0,(rows_total-visible_rows)*row_height)
func cancel_pointer() -> void:
	pointer=false;drag=false;touch_id=-1;down_id=-1
func icon(m,kind: String,box: Rect2) -> void:
	if kind in ["attack","defense"]:m.expedition.symbol(m,kind,box);return
	record_icon(m,kind,box)
func label_lines(m,text: String,pos: Vector2,width: float,size: int=10,lines: int=2,color: Color=INK) -> void:
	var parts: Array[String]=preload("res://addons/reservoir/text_layout.gd").wrap(m,text,size,width)
	for i in mini(parts.size(),lines):m._text(parts[i],pos+Vector2(0,i*(size+3)),size,color,false,width)
func soldier_mode() -> bool:return category=="soldier"
func area_ids() -> Array:
	var ids: Array=[]
	for sp in CATALOG.NAMES.size():
		if CATALOG.region(sp)==region:ids.append(sp)
	return ids
func draw(m,h: float) -> void:
	if not opened:return
	m.text_items=[];m.ui_commands=[]
	m._ui_rect(Rect2(-m.ox,0,270+2*m.ox,h),Color(.04,.06,.1,.82))
	var height: float=minf(620,h-20)
	var r:=Rect2(8,floorf((h-height)/2),254,height)
	m._ui_style_box(m.sb_panel,r)
	preload("res://addons/reservoir/ui_theme.gd").title(m,r,"도감" if selected<0 else ("병사 상세" if soldier_mode() else "물고기 상세"))
	var close:=Rect2(r.end.x-31,r.position.y+9,22,23)
	m._ui_style_box(m.sb_btn,close);icon(m,"close",close.grow(-5))
	rects={"close":close.grow(3),"regions":[],"categories":[],"fish":[],"tabs":[],"filters":[],"back":Rect2()}
	list_view=Rect2()
	if selected>=0:
		if soldier_mode():draw_soldier_detail(m,r)
		else:draw_trophy(m,r)
		return
	for tab in 2:
		var b:=Rect2(r.position+Vector2(13+tab*116,46),Vector2(111,27))
		button(m,b,["물고기","병사"][tab],category==["fish","soldier"][tab]);icon(m,["fish","soldier"][tab],Rect2(b.position+Vector2(8,6),Vector2(16,16)));rects.categories.append(b)
	draw_collection(m,r)
func draw_collection(m,r: Rect2) -> void:
	var ids: Array=[]
	var count:=0
	var y: float=r.position.y+81
	if soldier_mode():
		count=m.expedition.data.discovered.size()
		for id in m.expedition.data.catalog.soldiers.size():
			if role_filter=="all" or (m.expedition.data.is_discovered(id) and m.expedition.data.catalog.soldiers[id].role==role_filter):ids.append(id)
		ids.sort_custom(func(a,b):return int(m.expedition.data.is_discovered(a))>int(m.expedition.data.is_discovered(b)) if m.expedition.data.is_discovered(a)!=m.expedition.data.is_discovered(b) else a<b)
		m._text("제작 %d / %d종"%[count,m.expedition.data.catalog.soldiers.size()],Vector2(24,y+12),10,INK,false,220);y+=23
		for i in 4:
			var b:=Rect2(21+i*58,y,54,24)
			button(m,b,["전체","공격","방어","지원"][i],role_filter==["all","attack","defense","support"][i]);rects.filters.append(b)
		y+=31;row_height=68
	else:
		icon(m,"rod",Rect2(23,y-3,15,15));m._text("낚시터",Vector2(42,y+10),10,INK,false,200);y+=17
		for area in 6:
			var b:=Rect2(21+(area%2)*116,y+(area/2)*35,111,32)
			m._ui_style_box(m.sb_btn,b)
			if area==region:m._ui_rect(b.grow(-4),Color("08646b"))
			icon(m,"region%d"%area,Rect2(b.position+Vector2(4,4),Vector2(25,24)))
			label_lines(m,REGIONS[area],b.position+Vector2(32,13 if area==1 else 20),74,9,2,Color("fff0d1") if area==region else INK)
			rects.regions.append(b)
		y+=111;ids=area_ids()
		for sp in ids:
			if not best(m,sp,"grade").is_empty() or not best(m,sp,"length").is_empty():count+=1
		m._text("%s · 발견 %d / %d종"%[REGIONS[region],count,ids.size()] if not ids.is_empty() else REGIONS[region],Vector2(23,y+10),10,INK,false,224)
		var bar:=Rect2(23,y+17,222,4);m._ui_rect(bar,Color("d4c4a0"))
		if not ids.is_empty():m._ui_rect(Rect2(bar.position,Vector2(bar.size.x*count/ids.size(),4)),Color("228b82"))
		y+=29;row_height=52
	rows_total=ids.size();visible_rows=maxi(1,floori((r.end.y-32-y)/row_height));scroll=clampf(scroll,0,maximum())
	list_view=Rect2(21,y,225,visible_rows*row_height)
	var start:=floori(scroll/row_height)
	for i in mini(visible_rows,maxi(0,ids.size()-start)):
		var id: int=ids[start+i]
		var cell:=Rect2(list_view.position+Vector2(0,i*row_height),Vector2(222,row_height-3))
		m._ui_rect(Rect2(cell.position+Vector2(0,cell.size.y),Vector2(cell.size.x,1)),Color("bda274"))
		var known: bool=m.expedition.data.is_discovered(id) if soldier_mode() else (not best(m,id,"grade").is_empty() or not best(m,id,"length").is_empty())
		var picture:=Rect2(cell.position+Vector2(3,5),Vector2(46,46 if soldier_mode() else 36))
		if known:
			if soldier_mode():m.expedition.sprite(m,id,picture)
			else:m._ui_fish(id,picture)
			var name: String=m.expedition.data.catalog.soldiers[id].name if soldier_mode() else m.FISH_NAME[id]
			m._text(name,cell.position+Vector2(55,17),11,INK,false,150)
			if soldier_mode():
				var spec: Dictionary=m.expedition.data.catalog.soldiers[id]
				var role: String=spec.role
				m.expedition.symbol(m,role,Rect2(cell.position+Vector2(55,23),Vector2(12,12)))
				m._text(m.expedition.ROLES[role],cell.position+Vector2(71,33),9,Color(m.expedition.ROLE_COLORS[role]),false,130)
				label_lines(m,spec.description,cell.position+Vector2(55,47),150,9,2,MUTED)
			else:
				m._text("수집 등급",cell.position+Vector2(55,36),9,MUTED,false,60)
				var grades: Array=m.fish_grades(id)
				for g in 5:
					var mark:=Rect2(cell.position+Vector2(115+g*16,25),Vector2(14,14))
					if g in grades:icon(m,"fish",mark)
					else:
						record_icon(m,"fish",mark)
						m._ui_rect(mark,Color(.92,.88,.77,.7))
			icon(m,"right",Rect2(cell.position+Vector2(209,cell.size.y/2-5),Vector2(11,11)))
			rects.fish.append([cell,id])
		else:
			m._text("?",picture.get_center()+Vector2(0,6),18,MUTED,true,40)
			m._text("미제작" if soldier_mode() else "미발견",cell.position+Vector2(55,25),11,MUTED,false,150)
			if soldier_mode():m._text("아직 만나지 못한 병사예요",cell.position+Vector2(55,44),9,MUTED,false,155)
			else:rects.fish.append([cell,id])
	if ids.is_empty():
		m._text("발견한 병사가 없어요" if soldier_mode() else "물고기 도감 준비 중",Vector2(135,y+38),12,MUTED,true,220)
		if not soldier_mode():m._text("어종이 추가되면 이곳에서 볼 수 있어요",Vector2(135,y+59),9,MUTED,true,220)
	if rows_total>visible_rows:
		var track:=Rect2(r.end.x-14,y,3,list_view.size.y-4)
		m._ui_rect(track,Color("d1bc91"))
		var thumb: float=maxf(12,track.size.y*visible_rows/rows_total)
		m._ui_rect(Rect2(track.position+Vector2(0,(track.size.y-thumb)*scroll/maximum()),Vector2(3,thumb)),Color("8d6037"))
	m._text("합성 후에도 제작 기록은 남아요" if soldier_mode() else "판매·기증 후에도 기록은 남아요",Vector2(135,r.end.y-16),9,MUTED,true,230)
func back_button(m,r: Rect2) -> void:
	var b:=Rect2(r.position+Vector2(13,46),Vector2(64,23));button(m,b,"목록");icon(m,"left",Rect2(b.position+Vector2(5,6),Vector2(11,11)));rects.back=b
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
	icon(m,"star",Rect2(115,y+31,12,12));m._text("%d · %s"%[star,REGIONS[region]],Vector2(130,y+43),10,MUTED,false,110)
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
		if acquired:icon(m,"check",Rect2(b.end.x-12,b.position.y+1,10,10))
	m._text("판매·기증 후에도 기록은 남아요",Vector2(135,r.end.y-13),9,MUTED,true,230)
func section(m,r: Rect2,title: String) -> void:
	m._ui_style_box(m.sb_chip,r)
	m._ui_rect(Rect2(r.position+Vector2(5,4),Vector2(r.size.x-10,22)),Color("185760"))
	m._text(title,Vector2(r.get_center().x,r.position.y+19),11,Color("fff0d1"),true,r.size.x-18)
func draw_soldier_detail(m,r: Rect2) -> void:
	back_button(m,r)
	var data=m.expedition.data
	if not data.is_discovered(selected):selected=-1;return
	var spec: Dictionary=data.catalog.soldiers[selected]
	var y: float=r.position.y+75
	var extra: float=maxf(0,r.size.y-460)
	var hero_h: float=96+extra*.28
	m.expedition.sprite(m,selected,Rect2(26,y+5,86,hero_h-8))
	label_lines(m,spec.name,Vector2(121,y+24),119,14,2)
	icon(m,"leaf" if spec.role=="support" else spec.role,Rect2(122,y+52,15,15))
	m._text(m.expedition.ROLES[spec.role],Vector2(143,y+64),11,Color(m.expedition.ROLE_COLORS[spec.role]),false,91)
	m._text("제작 완료",Vector2(123,y+84),10,MUTED,false,111)
	y+=hero_h+6
	var skill_h: float=75+extra*.22
	section(m,Rect2(21,y,228,skill_h),SKILLS.get(str(spec.skill),"특수 능력"))
	label_lines(m,spec.description,Vector2(33,y+44),204,11,3)
	y+=skill_h+8
	var combo_h: float=98+extra*.20
	section(m,Rect2(21,y,228,combo_h),"어혼 조합")
	for i in 2:
		var el: int=int(spec.elements[i]);var x: float=34+i*58
		icon(m,"soul%d"%el,Rect2(x,y+34,30,30))
		m._text(data.ELEMENTS[el],Vector2(x+15,y+80),10,INK,true,42)
	icon(m,"plus",Rect2(73,y+43,12,12));icon(m,"right",Rect2(136,y+43,15,15))
	m.expedition.sprite(m,selected,Rect2(167,y+30,48,48))
	label_lines(m,spec.name,Vector2(164,y+79),74,9,2)
	y+=combo_h+8
	var stats: Dictionary=spec.base
	section(m,Rect2(21,y,228,67),"기본 능력치 · ★1 기준")
	for i in 3:
		var x: float=27+i*74
		icon(m,["heart","attack","defense"][i],Rect2(x,y+33,16,16))
		m._text(["체력","공격","방어"][i],Vector2(x+20,y+43),9,MUTED,false,50)
		m._text(str(int(stats[["hp","atk","def"][i]])),Vector2(x+42,y+61),13,INK,true,60)
	m._text("합성 후에도 제작 기록은 남아요",Vector2(135,r.end.y-14),9,MUTED,true,230)
func hit_id(p: Vector2) -> int:
	for row in rects.get("fish",[]):
		if row[0].has_point(p):return int(row[1])
	return -1
func press(m,p: Vector2) -> void:
	if rects.get("close",Rect2()).has_point(p):opened=false;cancel_pointer();return
	for i in rects.get("categories",[]).size():
		if rects.categories[i].has_point(p):category=["fish","soldier"][i];selected=-1;scroll=0;role_filter="all";cancel_pointer();return
	for i in rects.get("regions",[]).size():
		if rects.regions[i].has_point(p):region=i;selected=-1;scroll=0;cancel_pointer();return
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
		if e.pressed and list_view.has_point(p) and e.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:scroll=clampf(scroll+(row_height if e.button_index==MOUSE_BUTTON_WHEEL_DOWN else -row_height),0,maximum())
		elif e.button_index==MOUSE_BUTTON_LEFT:
			if e.pressed:
				if list_view.has_point(p):begin(p)
				else:press(m,p)
			elif pointer:finish(m,p)
	elif e is InputEventMouseMotion and pointer:move(e.position-Vector2(m.ox,0))
	return true
