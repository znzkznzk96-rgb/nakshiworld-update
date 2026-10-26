extends RefCounted
var pending: = {}
var rects: = {}
var notice: = ""
var notice_time: = -10.0
var notice_icon: Texture2D
func quote(v, m, a: String) -> Dictionary:
	var k = a.split(":"); var n: int = int(k[1]) if k.size() > 1 else 0
	var q: Dictionary = {"action": a, "currency": "gold", "price": 0, "title": "", "icon": null, "target": 0}
	match k[0]:
		"buyback":
			var entry: Dictionary=m.buyback.find(n)
			if entry.is_empty(): return {}
			q.title=m.FISH_NAME[int(entry.fish.sp)]+" · "+m.GRADE_N[int(entry.fish.grade)]+" · %.1fcm"%float(entry.fish.len)
			q.price=m.buyback.price(entry);q.target=n;q.icon=m.fish_tex[int(entry.fish.sp)]
		"rpart":
			if k.size()!=3 or n<0 or n>5 or not m.region_shop.is_unlocked(n): return {}
			var slot:=int(k[2])
			if slot<0 or slot>3: return {}
			var key: String=m.region_shop.part_key(n,slot)
			if key in m.parts_owned: return {}
			for i in slot:
				if m.region_shop.part_key(n,i) not in m.equipment.unlocked_parts: return {}
			q.title=m.region_shop.TITLES[n]+" "+v.PARTS[slot][1];q.price=m.region_shop.price(m,n,slot);q.icon=m.region_shop.icon(m,n,slot);q.target=n*4+slot
		"soul_pouch":
			if n not in [1,5,10]: return {}
			q.title="어혼 주머니 %d개"%n;q.price=m.expedition.data.POUCH_PRICE*n;q.target=n;q.icon=preload("res://addons/reservoir/soul_pouch_shop.gd").icon()
		"bait":
			if k.size()!=3 or not m.region_shop.bait_unlocked(n): return {}
			var count:=int(k[2])
			if count not in m.region_shop.QUANTITIES: return {}
			q.title=m.region_shop.BAIT_NAMES[n]+" %d개" % count;q.price=m.region_shop.BAIT_PRICES[n]*count;q.icon=m.region_shop.bait_icon(n);q.target=n*1000+count
		"part":
			if n < 0 or n >= v.PARTS.size(): return {}
			var p: Array = v.PARTS[n]
			if p[0] in m.parts_owned: return {}
			for i in n:
				if v.PARTS[i][0] not in m.equipment.unlocked_parts: return {}
			q.title = p[1];q.price = p[3];q.icon = v.tool_icons[p[0]];q.target = n
		"bag":
			n = m.equipment.bag_progress + 1
			if n >= m.BAG_CAP.size(): return {}
			q.title = m.BAG_NAME[n];q.price = m.BAG_PRICE[n];q.icon = v.tool_icons[preload("res://addons/reservoir/equipment_art.gd").container_name(n)];q.target = n
		"worm":
			if n not in [1, 10]: return {}
			q.title = "지렁이 %d개" % n;q.price = n * m.region_shop.BAIT_PRICES[0];q.icon = v.tool_icons.worm;q.target = n
		"rod":
			if n < 0 or n > m.rod_owned + 1 or n >= v.ROD_NAME.size() or n in m.equipment.rods: return {}
			q.title = v.ROD_NAME[n];q.price = v.ROD_COST[n];q.icon = v.rods[n];q.target = n
		"boat":
			if m.boat_lv >= 5: return {}
			q.title = "배 확장 Lv.%d" % (m.boat_lv + 2);q.price = v.UPGRADE_COST[m.boat_lv];q.icon = v.tool_icons.boat;q.target = m.boat_lv + 1
		"pondcap":
			if m.pond_cap_lv >= 5: return {}
			q.title = "어장 규모 확장";q.price = v.POND_CAP_COST[m.pond_cap_lv];q.icon = m.V.art.stock;q.target = m.pond_cap_lv + 1
		"pondregen":
			if m.pond_regen_lv >= 5: return {}
			q.title = "어장 회복 시설";q.price = v.POND_REGEN_COST[m.pond_regen_lv];q.icon = m.V.art.stock;q.target = m.pond_regen_lv + 1
		"aexpand":
			if m.aqua_lv >= 4: return {}
			q.title = "수족관 %d마리 확장" % m.AQUA_CAP[m.aqua_lv + 1];q.price = m.AQUA_COST[m.aqua_lv];q.icon = v.tool_icons.bucket;q.target = m.aqua_lv + 1
		"forge_ticket":
			q.title = "하락 보호권 1장";q.price = 1;q.currency = "pearl";q.icon = m.icons.pearl_s;q.target = m.protection_tickets + 1
		_: return {}
	return q
func request(v, m, a: String) -> bool:
	var q: = quote(v, m, a)
	if q.is_empty(): return false
	pending = q;m.holding = false;m.play("ui", -8.0);return true
func balance(m, q: Dictionary) -> int: return m.pearl if q.currency == "pearl" else m.gold
func confirm(v, m) -> bool:
	if pending.is_empty(): return false
	var q: Dictionary = pending.duplicate(); var current: = quote(v, m, q.action)
	if current.is_empty() or current.target != q.target or current.price != q.price:
		pending = {};notice = "상품 상태가 바뀌었어요. 다시 선택해 주세요.";notice_time = m.ui_clock;return false
	if balance(m, q) < q.price: return false

	pending = {}; var before: = balance(m, q)
	if str(q.action).begins_with("buyback:"):
		if not m.buyback.purchase(m,int(q.target)):
			notice="보관통과 어깨 공간을 확인해 주세요.";notice_time=m.ui_clock;return false
	else: v._act(m, q.action)
	if before - balance(m, q) != int(q.price): return false
	notice = "%s 구매되었습니다." % q.title;notice_time = m.ui_clock;notice_icon = q.icon;m.toast_t = 0.0
	return true
func press(v, m, p: Vector2) -> void :
	for item in rects.get("quantities",[]):
		if item[0].has_point(p):
			pending=quote(v,m,"bait:%s:%d" % [pending.action.get_slice(":",1),item[1]]);return
	if rects.get("buy", Rect2()).has_point(p): confirm(v, m);return
	if rects.get("cancel", Rect2()).has_point(p) or not rects.get("panel", Rect2()).has_point(p): pending = {}
func draw(v, m, h: float) -> void :
	if not pending.is_empty():
		m.text_items = m.text_items.filter( func(it): return it[1].y < m.top_y + 70)
		m._ui_rect(Rect2( - m.ox, 0, m.VW + 2 * m.ox, h), Color(0.025, 0.04, 0.07, 0.78))
		var is_bait: bool = str(pending.action).begins_with("bait:")
		var r: = Rect2(20, roundf(h * 0.5) - (160 if is_bait else 140), 230, 320 if is_bait else 240)
		m._ui_style_box(m.sb_panel, r)
		m._ui_style_box(m.hud_reference_style, Rect2(r.position + Vector2(7, 7), Vector2(216, 31)))
		m._text("구매 확인", Vector2(135, r.position.y + 28), 14, Color("fff0d1"), true, 200)
		var icon: Texture2D = pending.icon
		if str(pending.action).begins_with("buyback:"):
			var entry: Dictionary=m.buyback.find(int(pending.target))
			if not entry.is_empty(): m._ui_fish(int(entry.fish.sp),Rect2(85,r.position.y+49,100,58))
		elif icon:
			var master: Texture2D = icon.get_meta("master", icon)
			var size: Vector2 = master.get_size()
			if size.x <= 80 and size.y <= 80: m._ui_texture(master, Vector2(135, r.position.y + 82) - size / 2)
			else: m._ui_texture(icon, Vector2(135, r.position.y + 82) - icon.get_size() / 2)
		m._text(m._ui_wrap(pending.title, 12, 208, 2), Vector2(135, r.position.y + 132), 12, Color("513b29"), true, 208)
		var unit: String = "진주" if pending.currency == "pearl" else "비늘"
		m._text("%s %s" % [str(pending.price), unit], Vector2(135, r.position.y + 157), 14, Color("513b29"), true, 205)
		var enough: bool = balance(m, pending) >= pending.price
		m._text("보유 %d %s" % [balance(m, pending), unit], Vector2(135, r.position.y + 176), 10, Color("6d644f") if enough else Color("a33c3c"), true, 208)
		var cancel: = Rect2(34, r.end.y - 48, 94, 29); var buy: = Rect2(142, r.end.y - 48, 94, 29)
		m._ui_style_box(m.sb_btn, cancel);m._ui_style_box(m.sb_primary if enough else m.sb_chip, buy)
		m._text("취소", cancel.get_center() + Vector2(0, 5), 12, Color("513b29"), true, 84)
		m._text("구매하기" if enough else "부족해요", buy.get_center() + Vector2(0, 5), 12, Color("fff0d1") if enough else Color("817767"), true, 86)
		rects = {"panel": r, "cancel": cancel, "buy": buy if enough else Rect2(), "quantities":[]}
		if is_bait:
			var bait_id: int=int(pending.action.get_slice(":",1))
			var desc: String="빈 바늘보다 입질 대기 33% 단축"
			var extra: String="해금된 ★2~4 어종을 더 잘 유인"
			if bait_id==1:
				desc="큰 개체를 유인 · 길이/무게 기록용"
				extra="개체 등급 확률은 지렁이와 같아요"
			elif bait_id>=2:
				desc="레어 이상 %.1f%% → %.1f%%"%[m.region_shop.grade_chance(m,0),m.region_shop.grade_chance(m,bait_id)]
				extra="현재 낚시터 · 챔질 등급 변화 전"
			m._text(desc,Vector2(135,r.position.y+232),9,Color("513b29"),true,208)
			m._text(extra,Vector2(135,r.position.y+247),8,Color("7c6448"),true,208)
			for i in m.region_shop.QUANTITIES.size():
				var amount: int=m.region_shop.QUANTITIES[i]
				var b:=Rect2(30+i*43,r.position.y+190,39,25)
				m._ui_style_box(m.sb_primary if int(pending.action.get_slice(":",2))==amount else m.sb_btn,b)
				m._text("%d개" % amount,b.get_center()+Vector2(0,4),9,Color("fff0d1") if int(pending.action.get_slice(":",2))==amount else Color("513b29"),true,36)
				rects.quantities.append([b,amount])
	var age: float = m.ui_clock - notice_time
	if notice != "" and age < 2.0:
		var alpha: float = minf(1, age / 0.12) * minf(1, (2 - age) / 0.4)
		var yy: float = m.top_y + 91 - 5 * smoothstep(0, 0.25, age)
		var toast: = Rect2(13, yy, 244, 41)
		m.text_items = m.text_items.filter( func(it): return not toast.grow(2).has_point(it[1]))
		m._ui_style_box(m.hud_reference_style, toast)
		m._text(m._ui_wrap(notice, 12, 224, 2), Vector2(135, yy + 25), 12, Color(1, 0.94, 0.72, alpha), true, 224, true)

