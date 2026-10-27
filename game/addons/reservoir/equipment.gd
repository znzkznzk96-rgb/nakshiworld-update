extends RefCounted
# Owned items and equipped slots are independent. Progress remains after a sale.
var rods: Array = [0]
var bags: Array = [0]
var rod_equipped := true
var active_parts: Array = []
var unlocked_parts: Array = []
var bag_progress := 0
var page := 0
var sale_page := 0
var inventory_scroll := {"inventory":0.0,"equipment":0.0}
var inventory_viewport := Rect2()
var inventory_count := 0
var inventory_tab := "inventory"
var rects := {}
var pending_sale := ""
var notice := ""
var notice_at := -10.0

func restore(m, data: Dictionary) -> void:
	rods = []
	bags = [0]
	for n in data.get("rods", range(m.rod_owned + 1)):
		if int(n) >= 0 and int(n) < 6 and int(n) not in rods: rods.append(int(n))
	for n in data.get("bags", range(m.bag_lv + 1)):
		if int(n) > 0 and int(n) < m.BAG_CAP.size() and int(n) not in bags: bags.append(int(n))
	rod_equipped = bool(data.get("rod_equipped", true)) and m.rod_lv in rods
	active_parts = []
	for key in data.get("active_parts", m.parts_owned):
		if key in m.parts_owned and key not in active_parts: active_parts.append(key)
	unlocked_parts = data.get("unlocked_parts", m.parts_owned).duplicate()
	bag_progress = clampi(int(data.get("bag_progress", m.bag_lv)), m.bag_lv, m.BAG_CAP.size() - 1)
	if m.bag_lv not in bags: m.bag_lv = 0

func serialize() -> Dictionary:
	return {"rods": rods, "bags": bags, "rod_equipped": rod_equipped, "active_parts": active_parts, "unlocked_parts": unlocked_parts, "bag_progress": bag_progress}

func item(m, key: String) -> Dictionary:
	var bits := key.split(":")
	if bits.size() != 2: return {}
	var kind: String = bits[0]
	var n := int(bits[1])
	if kind == "rod" and n >= 0 and n < 6 and n in rods:
		return {"key": key, "name": m.V.ROD_NAME[n], "icon": m.V.rods[n], "price": m.V.ROD_COST[n] / 2, "equipped": rod_equipped and m.rod_lv == n, "desc": "강화 +%d" % int(m.rod_enh[n])}
	if kind == "bag" and n >= 0 and n < m.BAG_CAP.size() and n in bags:
		return {"key": key, "name": m.BAG_NAME[n], "icon": m.V.tool_icons[preload("res://addons/reservoir/equipment_art.gd").container_name(n)], "price": m.BAG_PRICE[n] / 2, "equipped": m.bag_lv == n, "desc": "보관 %s" % m._wtxt(m.BAG_CAP[n])}
	if kind == "part" and bits[1] in m.parts_owned:
		return m.region_shop.part_data(m,bits[1])
	return {}

func entries(m, equipped: bool) -> Array:
	var out: Array = []
	for n in rods:
		var d := item(m, "rod:%d" % int(n))
		if bool(d.equipped) == equipped: out.append(d)
	for n in bags:
		if n == 0: continue
		var d := item(m, "bag:%d" % int(n))
		if bool(d.equipped) == equipped: out.append(d)
	for key in m.parts_owned:
		var d := item(m, "part:" + str(key))
		if not d.is_empty() and bool(d.equipped) == equipped: out.append(d)
	return out

func can_sell(m, key: String) -> bool:
	var d := item(m, key)
	return not d.is_empty() and not bool(d.equipped) and int(d.price) > 0 and not m.V.enhancement.busy()

func equip(m, key: String, on: bool) -> bool:
	if m.V.enhancement.busy(): return false
	var d := item(m, key)
	if d.is_empty(): return false
	var bits := key.split(":")
	var n := int(bits[1])
	match bits[0]:
		"rod":
			if not on and (not rod_equipped or m.rod_lv != n): return false
			if on: m.rod_lv = n
			rod_equipped = on
		"bag":
			var target := n if on else 0
			if not on and m.bag_lv != n: return false
			if m.bag_weight() > float(m.BAG_CAP[target]):
				notice = "보관통의 물고기를 먼저 비워 주세요";notice_at = m.ui_clock
				return false
			m.bag_lv = target
		"part":
			if on:
				if not m.region_shop.is_unlocked(m.region_shop.part_region(bits[1])): return false
				for existing in active_parts.duplicate():
					if m.region_shop.slot_key(existing)==m.region_shop.slot_key(bits[1]): active_parts.erase(existing)
				active_parts.append(bits[1])
			elif not on: active_parts.erase(bits[1])
	m._save_game()
	m.play("ui", -8.0)
	return true

func sell(m, key: String) -> bool:
	if not can_sell(m, key): return false
	var d := item(m, key)
	var bits := key.split(":")
	var n := int(bits[1])
	match bits[0]:
		"rod": rods.erase(n);m.rod_enh[n] = 0
		"bag": bags.erase(n)
		"part": m.parts_owned.erase(bits[1])
	m.gold += int(d.price)
	m._save_game()
	m.play("catch")
	m.V.commerce.notice = "%s 판매 · +%d 비늘" % [d.name, int(d.price)]
	m.V.commerce.notice_time = m.ui_clock
	return true

func act(m, action: String) -> bool:
	if action.begins_with("sellgear:"):
		var key := action.trim_prefix("sellgear:")
		if can_sell(m, key): pending_sale = key
		return true
	if action.begins_with("gearpage:"):
		sale_page = maxi(0, sale_page + int(action.get_slice(":", 1)))
		return true
	return false

func button(m, r: Rect2, text: String, action: String) -> void:
	m._ui_style_box(m.sb_btn, r)
	m._text(text, r.get_center() + Vector2(0, 4), 9, Color("513b29"), true, r.size.x - 5)
	rects.rows.append([r, action])

func draw_inventory(m, r: Rect2, tab: String) -> void:
	rects = {"rows": []}
	var equipped := tab == "equipment"
	var list := entries(m, equipped)
	if not equipped:
		list.push_front({"key":"pouch","name":"어혼 주머니","icon":preload("res://addons/reservoir/soul_pouch_shop.gd").icon(),"desc":"보유 %d개 · 눌러서 열기"%m.expedition.data.pouches})
		list.append({"key": "bait", "name": "지렁이", "icon": m.V.tool_icons.worm, "desc": "보유 %d개" % m.bait})
		for i in range(1,6):
			if m.region_shop.stock(m,i)>0:
				list.append({"key":"bait%d" % i,"name":m.region_shop.BAIT_NAMES[i],"icon":null,"desc":"보유 %d개 · 상점에서 선택" % m.region_shop.stock(m,i)})
		list.append({"key": "ticket", "name": "하락 보호권", "icon": m.V.tool_icons.soul, "desc": "보유 %d장" % m.protection_tickets})
	inventory_tab=tab;inventory_count=list.size()
	inventory_viewport=Rect2(r.position+Vector2(11,96),Vector2(218,r.size.y-154))
	inventory_scroll[tab]=clampf(float(inventory_scroll[tab]),0,inventory_max_scroll())
	m._text("현재 장착 중인 장비 · 탈착하면 인벤토리로" if equipped else "어혼 주머니 · 장비 · 파츠 · 미끼", Vector2(135, r.position.y + 86), 9, Color("6c5843"), true, 218)
	for i in list.size():
		var d: Dictionary = list[i]
		var row := Rect2(inventory_viewport.position+Vector2(0,i*36-roundf(float(inventory_scroll[tab]))),Vector2(218,33))
		if row.position.y<inventory_viewport.position.y or row.end.y>inventory_viewport.end.y: continue
		m._ui_style_box(m.sb_chip, row)
		if d.icon: m._ui_texture_rect(d.icon, Rect2(row.position + Vector2(4, 3), Vector2(26, 26)))
		m._text(d.name, row.position + Vector2(36, 13), 10, Color("513b29"), false, 124)
		m._text(d.desc, row.position + Vector2(36, 26), 8, Color("77644d"), false, 124)
		if d.key=="pouch": button(m,Rect2(row.end.x-49,row.position.y+4,45,25),"열기","pouch")
		if ":" in str(d.key): button(m, Rect2(row.end.x - 49, row.position.y + 4, 45, 25), "탈착" if equipped else "장착", ("off:" if equipped else "on:") + d.key)
	if list.is_empty(): m._text("장착한 장비가 없어요", Vector2(135, r.position.y + 170), 12, Color("77644d"), true, 210)
	var maximum: float=inventory_max_scroll()
	if maximum>0:
		var thumb: float=maxf(20,inventory_viewport.size.y*inventory_viewport.size.y/(list.size()*36.0))
		m._ui_rect(Rect2(inventory_viewport.end.x+2,inventory_viewport.position.y,2,inventory_viewport.size.y),Color("d3c39e"))
		m._ui_rect(Rect2(inventory_viewport.end.x+2,inventory_viewport.position.y+float(inventory_scroll[tab])/maximum*(inventory_viewport.size.y-thumb),2,thumb),Color("9d7c4c"))
	m._text("보유 %d개 · 위아래로 밀어서 보기"%list.size(),Vector2(135,r.end.y-24),9,Color("6c5843"),true,218)
	if m.ui_clock - notice_at < 3.5: m._text(notice, Vector2(135, r.end.y - 7), 8, Color("a34a40"), true, 220)

func inventory_max_scroll() -> float:
	return maxf(0,inventory_count*36.0-inventory_viewport.size.y)

func scroll_inventory(delta: float) -> void:
	inventory_scroll[inventory_tab]=clampf(float(inventory_scroll[inventory_tab])+delta,0,inventory_max_scroll())

func press_inventory(m, p: Vector2) -> void:
	for row in rects.get("rows", []):
		if not inventory_viewport.has_point(p) or not row[0].has_point(p): continue
		var action: String = row[1]
		if action=="pouch": m.inventory.pouch.open(m)
		elif action.begins_with("page:"): page = maxi(0, page + int(action.get_slice(":", 1)))
		elif action.begins_with("on:"): equip(m, action.trim_prefix("on:"), true)
		elif action.begins_with("off:"): equip(m, action.trim_prefix("off:"), false)
		return

func draw_shop(v, m, r: Rect2, y: float) -> void:
	var list := entries(m, false).filter(func(d): return int(d.price) > 0)
	var pages := maxi(1, ceili(list.size() / 5.0))
	sale_page = clampi(sale_page, 0, pages - 1)
	m._text("탈착한 장비만 · 기본 구매가의 50%", Vector2(135, y + 6), 9, Color("6a4a2a"), true, 230)
	for i in 5:
		var index := sale_page * 5 + i
		if index >= list.size(): break
		var d: Dictionary = list[index]
		v._row(m, r, y + 14 + i * 38, d.icon, d.name, d.desc, "%d 비늘" % int(d.price), 0, can_sell(m, d.key), "sellgear:" + d.key)
	if list.is_empty(): m._text("팔 수 있는 탈착 장비가 없어요", Vector2(135, y + 70), 11, Color("77644d"), true, 225)
	for i in 2:
		var b := Rect2(55 + i * 130, r.end.y - 35, 30, 24)
		m._ui_style_box(m.sb_btn, b)
		m._text("<" if i == 0 else ">", b.get_center() + Vector2(0, 4), 10, Color("513b29"), true, 25)
		v.rects.rows.append([b, "gearpage:-1" if i == 0 else "gearpage:1"])
	m._text("%d / %d" % [sale_page + 1, pages], Vector2(135, r.end.y - 18), 10, Color("513b29"), true, 70)

func draw_confirmation(m, h: float) -> void:
	if pending_sale.is_empty(): return
	var d := item(m, pending_sale)
	if d.is_empty(): pending_sale = "";return
	m.text_items.clear()
	m._ui_rect(Rect2(-m.ox, 0, 270 + 2 * m.ox, h), Color(0.025, 0.04, 0.07, 0.86))
	var r := Rect2(20, h * 0.5 - 113, 230, 226)
	m._ui_style_box(m.sb_panel, r)
	m._text("장비 판매 확인", Vector2(135, r.position.y + 34), 14, Color("513b29"), true, 208)
	m._ui_texture_rect(d.icon, Rect2(115, r.position.y + 48, 40, 40))
	m._text(d.name, Vector2(135, r.position.y + 112), 12, Color("513b29"), true, 208)
	m._text("판매 금액 %d 비늘" % int(d.price), Vector2(135, r.position.y + 137), 12, Color("513b29"), true, 208)
	m._text("판매하면 이 장비의 강화도 사라져요", Vector2(135, r.position.y + 158), 9, Color("a34a40"), true, 210)
	var cancel := Rect2(33, r.end.y - 49, 98, 31)
	var yes := Rect2(139, r.end.y - 49, 98, 31)
	m._ui_style_box(m.sb_btn, cancel);m._ui_style_box(m.sb_primary, yes)
	m._text("취소", cancel.get_center() + Vector2(0, 5), 11, Color("513b29"), true, 90)
	m._text("판매하기", yes.get_center() + Vector2(0, 5), 11, Color("fff0d1"), true, 90)
	rects.confirm_cancel = cancel;rects.confirm_yes = yes

func press_confirmation(m, p: Vector2) -> void:
	if rects.get("confirm_cancel", Rect2()).has_point(p): pending_sale = ""
	elif rects.get("confirm_yes", Rect2()).has_point(p):
		var key := pending_sale
		pending_sale = ""
		sell(m, key)
