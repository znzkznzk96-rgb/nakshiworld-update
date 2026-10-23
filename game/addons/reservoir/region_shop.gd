extends RefCounted
# Future ground content unlocks through this shared saved flag; no paid unlock of unfinished grounds.
const SPOTS = preload("res://addons/reservoir/spot_selection.gd")
const KEYS := ["float", "hook", "line", "reel"]
const TITLES := ["낡은", "폭포", "청자", "균열", "심해", "성운"]
const BAIT_NAMES := ["지렁이", "갯지렁이", "새우", "오징어", "황금 루어", "전설의 미끼"]
const BAIT_PRICES := [5,15,20,1200,3000,6000]
const BAIT_MULT := [1.0,1.0,1.5,1.8,2.1,2.5]
const BAIT_ROLES := ["기본","대물","희귀","희귀","희귀","희귀"]
# Existing design: shrimp aboard ship, squid/golden lure in deep sea, legendary in space.
const BAIT_REGION := [0,0,0,4,4,5]
const QUANTITIES := [1,5,10,50,100]
var unlocked: Array = [0]
var region := 0
var stocks: Array = [0,0,0,0,0,0]
var selected_bait := 0
var last_bait := -1
var icons := {}
func restore(data: Dictionary) -> void:
	unlocked=[0]
	for value in data.get("unlocked",[]):
		var n:=int(value)
		if n>0 and n<6 and n not in unlocked: unlocked.append(n)
	stocks=[0,0,0,0,0,0]
	var saved: Array = data.get("stocks",[])
	for i in mini(6,saved.size()): stocks[i]=maxi(0,int(saved[i]))
	selected_bait=clampi(int(data.get("selected_bait",0)),0,5)
	if not bait_unlocked(selected_bait): selected_bait=0
func serialize() -> Dictionary:
	return {"unlocked":unlocked,"stocks":stocks,"selected_bait":selected_bait}
func is_unlocked(n: int) -> bool: return n in unlocked
func unlock(m, n: int) -> bool:
	if n<1 or n>5: return false
	if is_unlocked(n): return true
	if n not in m.progression.available_regions or not is_unlocked(n-1) or not m.progression.licensed(n): return false
	var cost: int = int(SPOTS.PRICES[n])
	if m.gold < cost: return false
	m.gold -= cost;unlocked.append(n);m._save_game()
	return true
func part_key(n: int, slot: int) -> String:
	return KEYS[slot] if n==0 else "r%d_%s" % [n,KEYS[slot]]
func part_region(key: String) -> int:
	return int(key.substr(1,1)) if key.begins_with("r") and key.contains("_") else 0
func slot_key(key: String) -> String:
	return key.get_slice("_",1) if key.begins_with("r") and key.contains("_") else key
# Equipment economics stay independent of entry-fee tuning.
const PART_PRICE_BASE: = [0, 3300, 52000, 1030000, 6700000, 28300000]
func price(m, n: int, slot: int) -> int:
	if n==0: return int(m.V.PARTS[slot][3])
	return maxi(10,roundi(PART_PRICE_BASE[n]*[0.05,0.10,0.18,0.30][slot]/10.0)*10)
func icon(m, n: int, slot: int) -> Texture2D:
	if n==0: return m.V.tool_icons[KEYS[slot]]
	var key:=part_key(n,slot)
	if not icons.has(key): icons[key]=load("res://art/guide64/"+key+".png")
	return icons[key]
func has_active(m, kind: String, area: int = -1) -> bool:
	for key in m.equipment.active_parts:
		if slot_key(key)==kind and is_unlocked(part_region(key)) and (area < 0 or part_region(key)==area): return true
	return false
func part_data(m, key: String) -> Dictionary:
	var n:=part_region(key);var slot:=KEYS.find(slot_key(key))
	if n<0 or n>5 or slot<0 or key!=part_key(n,slot): return {}
	return {"key":"part:"+key,"name":TITLES[n]+" "+m.V.PARTS[slot][1],"icon":icon(m,n,slot),"price":price(m,n,slot)/2,"equipped":key in m.equipment.active_parts,"desc":"지역 %d · %s" % [n+1,["★2 입질 해금","★3 입질 해금","★4 입질 해금","주인 낚시 준비"][slot]]}
func bait_unlocked(i: int) -> bool: return i>=0 and i<6 and is_unlocked(BAIT_REGION[i])
func stock(m, i: int) -> int: return m.bait if i==0 else int(stocks[i])
func take_bait(m) -> float:
	var i:=selected_bait
	if not bait_unlocked(i) or stock(m,i)<=0: i=0
	last_bait=-1
	if stock(m,i)<=0: return 0.85
	if i==0: m.bait-=1
	else: stocks[i]-=1
	last_bait=i
	return BAIT_MULT[i]
func grade_chance(m, i: int) -> float:
	var base: Array=m.GRADE_P if m.active_region==0 else m.OTHER_REGION_GRADE_P
	var total:=0.0;var rare:=0.0
	for grade in 5:
		var weight: float=float(base[grade])*pow(BAIT_MULT[i],grade)
		total+=weight
		if grade>0: rare+=weight
	return rare/total*100.0
func bait_description(m,i: int) -> String:
	if i==0: return "%d비늘 · 빠른 입질" % BAIT_PRICES[i]
	if i==1: return "%d비늘 · 대물 유인" % BAIT_PRICES[i]
	return "%d비늘 · 희귀/레어↑%.0f%%"%[BAIT_PRICES[i],grade_chance(m,i)]
func region_buttons(m, v, r: Rect2, y: float) -> void:
	for n in 6:
		var b:=Rect2(r.position.x+12+n*38,y,35,22)
		m._ui_style_box(m.sb_primary if n==region else m.sb_btn,b)
		m._text(str(n+1),b.get_center()+Vector2(0,3),7,Color("fff0d1") if n==region else Color("68533d"),true,33)
		if not is_unlocked(n):
			m._ui_rect(Rect2(b.end.x-10,b.position.y+9,5,5),Color("817767"))
			m._ui_rect(Rect2(b.end.x-9,b.position.y+6,3,4),Color("817767"))
			m._ui_rect(Rect2(b.end.x-8,b.position.y+7,1,2),Color("f4e7c7"))
		v.rects.rows.append([b,"region:%d" % n])
func draw_parts(m,v,r: Rect2,y: float) -> float:
	m._text("낚시터 파츠 · "+SPOTS.NAMES[region],Vector2(r.position.x+16,y+6),9,Color("6a4a2a"),false,230)
	region_buttons(m,v,r,y+12);y+=39
	for slot in 4:
		var key:=part_key(region,slot)
		var owned: bool=key in m.parts_owned
		var previous:=true
		for j in slot:
			if part_key(region,j) not in m.equipment.unlocked_parts: previous=false
		var available:=is_unlocked(region) and previous
		var cost:=price(m,region,slot)
		var label: String="잠김" if not is_unlocked(region) else ("장착됨" if key in m.equipment.active_parts else "보유 중") if owned else "이전 파츠" if not previous else ""
		v._row(m,r,y,icon(m,region,slot),TITLES[region]+" "+v.PARTS[slot][1],["★2 입질 해금","★3 입질 해금","★4 입질 해금","주인 낚시 준비"][slot],label, cost if available and not owned else 0,available and not owned and m.gold>=cost,"rpart:%d:%d" % [region,slot])
		y+=38
	return y
func bait_icon(i: int) -> Texture2D:
	var key: String="bait_%d"%i
	if not icons.has(key): icons[key]=load("res://art/rewards67/"+key+".png")
	return icons[key]
func draw_bait(m,v,r: Rect2,y: float) -> void:
	m._text("사용 미끼: "+BAIT_NAMES[selected_bait],Vector2(135,y+3),9,Color("6a4a2a"),true,230);y+=12
	for i in 6:
		var cell:=Rect2(r.position.x+12,y+i*34,230,32)
		m._ui_style_box(v.active_style.card,cell)
		m._ui_texture_rect(bait_icon(i),Rect2(cell.position+Vector2(3,3),Vector2(26,26)),false)
		m._text(BAIT_NAMES[i]+(" [사용]" if selected_bait==i else "")+" · %d개" % stock(m,i),cell.position+Vector2(33,12),9,v.active_style.ink,false,116)
		m._text(bait_description(m,i) if bait_unlocked(i) else "지역 %d 해금 시 구매" % (BAIT_REGION[i]+1),cell.position+Vector2(33,25),8,Color("675c4b"),false,116)
		var buy:=Rect2(cell.position+Vector2(151,3),Vector2(74,26))
		m._ui_style_box(m.sb_btn,buy)
		m._text("구매" if bait_unlocked(i) else "잠김",buy.get_center()+Vector2(0,4),9,v.active_style.ink,true,68)
		if bait_unlocked(i): v.rects.rows.append([buy,"bait:%d:1" % i])
		if bait_unlocked(i) and stock(m,i)>0: v.rects.rows.append([Rect2(cell.position,Vector2(148,32)),"baitselect:%d" % i])
	m._text("미끼 이름을 눌러 사용 선택 · 없으면 지렁이",Vector2(135,y+219),8,Color("675c4b"),true,232)
