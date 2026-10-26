extends RefCounted
var mirrors = {}
var fish_rects = []
var scroll := 0.0
var viewport := Rect2()
var count := 0
var pointer := false
var dragged := false
var origin := Vector2.ZERO
var last := Vector2.ZERO
var touch_id := -1
var native_until := 0
var down_action := ""
var down_fish = null
var list_bag := true
var visible: Array = []

func reset() -> void:
	scroll=0;pointer=false;dragged=false;touch_id=-1;down_action="";down_fish=null

func maximum() -> float:
	return maxf(0,count*44.0-8-viewport.size.y)

func action_at(v, p: Vector2) -> String:
	for row in v.rects.get("rows",[]):
		if row[0].has_point(p) and (str(row[1]).begins_with("put:") or str(row[1]).begins_with("take:")):
			return str(row[1])
	return ""

func begin(v, m, p: Vector2) -> void:
	pointer=true;dragged=false;origin=p;last=p
	down_action=action_at(v,p);down_fish=null
	if not down_action.is_empty():
		var i:=int(down_action.get_slice(":",1))
		var items: Array=m.bag if list_bag else m.aqua
		if i<items.size() and items[i]!=null: down_fish=items[i].duplicate(true)

func move(p: Vector2) -> void:
	if p.distance_to(origin)>5: dragged=true
	if dragged: scroll=clampf(scroll+last.y-p.y,0,maximum())
	last=p

func finish(v, m, p: Vector2) -> void:
	pointer=false
	var action:=action_at(v,p)
	if not dragged and viewport.has_point(p) and action==down_action and not action.is_empty():
		var i:=int(action.get_slice(":",1))
		var items: Array=m.bag if list_bag else m.aqua
		if i<items.size() and items[i]==down_fish: act(v,m,action)
	down_action="";down_fish=null

func input_event(v, m, e: InputEvent) -> bool:
	if v.shop!="aqua" or not v.aqua_manage: return false
	if e is InputEventMouseButton or e is InputEventMouseMotion:
		if Time.get_ticks_msec()<native_until: return true
	if v.shop!="aqua" or not v.aqua_manage: return false
	if m.market_open or m.settings_open or m.lesson_open or not m.trans.is_empty() or not v.commerce.pending.is_empty() or m.inventory.selected>=0: return false
	if e is InputEventScreenTouch:
		var p: Vector2=e.position-Vector2(m.ox,0)
		if e.pressed and touch_id<0 and viewport.has_point(p):
			touch_id=e.index;native_until=Time.get_ticks_msec()+350;begin(v,m,p);return true
		if e.index==touch_id:
			native_until=Time.get_ticks_msec()+350
			if not e.pressed:
				if e.canceled: pointer=false;down_action="";down_fish=null
				else: finish(v,m,p)
				touch_id=-1
			return true
	if e is InputEventScreenDrag and e.index==touch_id:
		native_until=Time.get_ticks_msec()+350;move(e.position-Vector2(m.ox,0));return true
	if e is InputEventMouseButton:
		var p: Vector2=e.position-Vector2(m.ox,0)
		if e.pressed and e.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and viewport.has_point(p):
			scroll=clampf(scroll+(44 if e.button_index==MOUSE_BUTTON_WHEEL_DOWN else -44),0,maximum());return true
		if e.button_index==MOUSE_BUTTON_LEFT:
			if e.pressed and viewport.has_point(p): begin(v,m,p);return true
			if not e.pressed and pointer: finish(v,m,p);return true
	if e is InputEventMouseMotion and pointer:
		move(e.position-Vector2(m.ox,0));return true
	return false


func _button(v, m, r: Rect2, label: String, action: String, enabled: bool = true) -> void :
	m._ui_style_box(v.active_style.header if enabled else v.active_style.card, r)
	m._text(label, r.position + Vector2(r.size.x / 2, 18), 10, Color("fff0d1") if enabled else Color("817767"), true, r.size.x - 6)
	if enabled or (action == "aexpand" and m.aqua_lv < 4): v.rects.rows.append([r, action])
func _fish(m, f: Dictionary, box: Rect2, flip: bool = false) -> void :
	var sp = int(f.sp)
	var tx: Texture2D = m.fish_tex[sp]
	var src: Rect2 = Rect2(m.fish_used[sp])
	if flip:
		if not mirrors.has(sp):
			var image = tx.get_image();image.flip_x()
			mirrors[sp] = [ImageTexture.create_from_image(image), Rect2(tx.get_width() - src.end.x, src.position.y, src.size.x, src.size.y)]
		tx = mirrors[sp][0];src = mirrors[sp][1]
	var sz = src.size * minf(box.size.x / src.size.x, box.size.y / src.size.y)
	var dest = Rect2(box.get_center() - sz / 2, sz)

	for i in 6:
		var d = Rect2(dest.position + Vector2(dest.size.x * i / 6, 0), Vector2(dest.size.x / 6 + 0.12, dest.size.y))
		d.position.y += sin(m.ui_clock * 5 + i * 0.55 + sp) * pow(float(i if flip else 5 - i) / 5, 2) * 0.8
		m._ui_texture_rect_region(tx, d, Rect2(src.position + Vector2(src.size.x * i / 6, 0), Vector2(src.size.x / 6, src.size.y)))
func draw(v, m, r: Rect2, y: float) -> void :
	m._text("%d / %d마리 · 분당 %.1f 비늘" % [m.aqua_count(), m.aqua_capacity(), m.aqua_rate()], Vector2(135, y + 3), 12, v.active_style.ink, true, 230)
	y += 13
	if v.pick_slot >= 0 or v.aqua_manage:
		_manage(v, m, r, y)
		return
	var width = 158.0 + m.aqua_lv * 18
	var height = minf(112.0 + m.aqua_lv * 12, r.end.y - y - 115)
	var tank = Rect2(135 - width / 2, y + 9, width, height)
	m._ui_rect(tank.grow(6), Color("302b25"))
	m._ui_rect(tank.grow(4), Color("8e663b"))
	m._ui_rect(tank.grow(2), Color("dfbf83"))
	m._ui_rect(tank, Color("104658"))
	for row in 18:
		var ratio = float(row) / 18
		m._ui_rect(Rect2(tank.position + Vector2(0, height * ratio), Vector2(width, height / 18 + 1)), Color("217a8f").lerp(Color("0d344e"), ratio))


	m._ui_rect(Rect2(tank.position + Vector2(0, 5), Vector2(width, 2)), Color("b7f4e8"))
	m._ui_rect(Rect2(tank.position + Vector2(5, 8), Vector2(2, height - 16)), Color("b8edf0"))
	m._ui_rect(Rect2(tank.position + Vector2(width - 7, 8), Vector2(2, height - 16)), Color("6bd0dc"))
	for wave in 5:
		var wx = tank.position.x + 10 + wave * (width - 20) / 5
		var wy = tank.position.y + 10 + sin(m.ui_clock * 1.8 + wave) * 1.5
		m._ui_line(Vector2(wx, wy), Vector2(wx + 8, wy), Color(0.72, 0.96, 0.91, 0.7), 0.7)
	for ray in 4:
		var x = tank.position.x + 12 + ray * width / 4 + sin(m.ui_clock * 0.25 + ray) * 3
		m._ui_polygon(PackedVector2Array([Vector2(x, tank.position.y), Vector2(x + 6, tank.position.y), Vector2(x + 28, tank.end.y), Vector2(x + 8, tank.end.y)]), PackedColorArray([Color(0.5, 0.9, 1, 0.04)]))
	m._ui_rect(Rect2(tank.position + Vector2(0, height - 13), Vector2(width, 13)), Color("70614b"))
	m._ui_rect(Rect2(tank.position + Vector2(0, height - 13), Vector2(width, 3)), Color("b5a77c"))

	for stone in 13:
		var sx = tank.position.x + 4 + fposmod(stone * 23.7, width - 8)
		var sw = 2 + stone % 4
		var sh = 1 + stone % 2
		m._ui_rect(Rect2(sx, tank.end.y - 5 + stone % 3, sw, sh), Color("c2b18a") if stone % 3 else Color("4b5960"))
	for rock in 6:
		var rx = tank.position.x + 10 + rock * (width - 20) / 5
		m._ui_polygon(PackedVector2Array([Vector2(rx - 5, tank.end.y - 3), Vector2(rx - 3, tank.end.y - 8 - rock % 3), Vector2(rx + 2, tank.end.y - 9 - rock % 3), Vector2(rx + 6, tank.end.y - 3)]), PackedColorArray([Color("657774")]))
	for plant in 8:
		var px = tank.position.x + 5 + plant * (width - 10) / 7
		var ph = 12 + plant % 3 * 5
		var foot = Vector2(px, tank.end.y - 6)
		for branch in 3:
			var lean = sin(m.ui_clock * 0.55 + plant * 0.7 + branch) * 2
			var tip = foot + Vector2(lean + (branch - 1) * 3, - ph + branch * 2)
			m._ui_line(foot, tip, Color("356c60"), 3)
			m._ui_line(foot + Vector2(1, 0), tip + Vector2(1, 0), Color("75aa78"), 1)
			m._ui_polygon(PackedVector2Array([tip, tip + Vector2(-3, 3), tip + Vector2(1, 5)]), PackedColorArray([Color("91bd78")]))

	for rock in 4:
		var rx = tank.position.x + 18 + rock * (width - 36) / 3
		m._ui_polygon(PackedVector2Array([Vector2(rx - 5, tank.end.y - 7), Vector2(rx - 3, tank.end.y - 11 - rock % 2 * 2), Vector2(rx + 3, tank.end.y - 10), Vector2(rx + 6, tank.end.y - 7)]), PackedColorArray([Color("566c6c")]))
	for bubble in 12:
		var bx = tank.position.x + 5 + fposmod(bubble * 31.7, width - 10)
		var by = tank.end.y - 5 - fposmod(m.ui_clock * (5 + bubble % 4) + bubble * 11, height - 10)
		m._ui_circle(Vector2(bx + sin(m.ui_clock + bubble), by), 0.6, Color(0.7, 1, 1, 0.35))
	fish_rects.clear()
	for i in m.aqua.size():
		var f = m.aqua[i]
		if f == null: continue
		var phase = fposmod(m.ui_clock * (0.018 + (i % 4) * 0.002) + i * 0.618034, 2.0)
		var fishw = clampf(20 + sqrt(float(f.get("len", 20))) * 2, 24, minf(40, 20 + 64 / sqrt(maxi(1, m.aqua_count()))))
		var travel = phase if phase <= 1.0 else 2.0 - phase
		var lanes = mini(4, maxi(1, m.aqua_count()))
		var lane = (i % lanes + 0.5) / lanes
		var center = Vector2(tank.position.x + fishw / 2 + 6 + travel * (width - fishw - 12), tank.position.y + 12 + lane * (height - 40) + sin(m.ui_clock * 0.4 + i) * 8)
		var box = Rect2(center - Vector2(fishw / 2, 10), Vector2(fishw, 20))
		_fish(m, f, box, phase > 1.0)
		fish_rects.append([box.grow(4), i])
		if i == v.aqua_selected: m._ui_arc(center, fishw * 0.6, 0, TAU, 24, Color(0.8, 1, 0.8, 0.6), 0.6)

	for j in range(fish_rects.size() - 1, -1, -1): v.rects.rows.append([fish_rects[j][0], "afish:%d" % fish_rects[j][1]])
	var info = "물고기를 터치하면 이름을 볼 수 있어요"
	if v.aqua_selected >= 0 and v.aqua_selected < m.aqua.size() and m.aqua[v.aqua_selected] != null:
		var f: Dictionary = m.aqua[v.aqua_selected]
		info = "%s · %s · %.1fcm" % [m.FISH_NAME[int(f.sp)], m.GRADE_N[int(f.grade)], float(f.len)]
	m._text(info, Vector2(135, tank.end.y + 17), 10, v.active_style.ink, true, 230)
	_button(v, m, Rect2(24, tank.end.y + 27, 222, 27), "물고기 넣기 · 빼기", "amanage")
	var label = "최대 크기 · 20마리"
	var enabled: bool = m.aqua_lv < 4
	if enabled: label = "수족관 확장 %d → %d · %d 비늘" % [m.aqua_capacity(), m.AQUA_CAP[m.aqua_lv + 1], m.AQUA_COST[m.aqua_lv]]
	_button(v, m, Rect2(24, tank.end.y + 60, 222, 27), label, "aexpand", enabled and m.gold >= m.AQUA_COST[m.aqua_lv] if enabled else false)
	m._text(v.aqua_notice if v.aqua_notice != "" else "쉬는 동안에도 최대 8시간 수입", Vector2(135, r.end.y - 12), 10, v.active_style.ink, true, 230)
func _manage(v, m, r: Rect2, y: float) -> void:
	_button(v,m,Rect2(24,y+3,107,26),"보관통 · 넣기","alist_bag")
	_button(v,m,Rect2(139,y+3,107,26),"전시 중 · 빼기","alist_tank")
	y+=37
	var items: Array=[]
	if list_bag:
		for i in m.bag.size(): items.append(i)
	else:
		for i in m.aqua.size():
			if m.aqua[i]!=null: items.append(i)
	count=items.size();viewport=Rect2(24,y,222,maxf(0,r.end.y-69-y))
	scroll=clampf(scroll,0,maximum())
	for j in items.size():
		var yy: float=y+j*44-scroll
		if yy<viewport.position.y or yy+36>viewport.end.y: continue
		var i: int=items[j]
		var f: Dictionary=m.bag[i] if list_bag else m.aqua[i]
		v._row(m,r,yy,m.fish_tex[int(f.sp)],m.FISH_NAME[int(f.sp)],"%s · %.1fcm"%[m.GRADE_N[int(f.grade)],float(f.len)],"넣기" if list_bag else "빼기",0,true,("put:" if list_bag else "take:")+str(i))
	if items.is_empty(): m._text("보관통이 비었어요" if list_bag else "전시 중인 물고기가 없어요",Vector2(135,y+25),11,v.active_style.ink,true,220)
	if maximum()>0:
		var thumb:=maxf(12,viewport.size.y*viewport.size.y/(count*44.0-8))
		m._ui_rect(Rect2(248,y,2,viewport.size.y),Color("bba387"))
		m._ui_rect(Rect2(248,y+(viewport.size.y-thumb)*scroll/maximum(),2,thumb),Color("705139"))
	m._text(v.aqua_notice if v.aqua_notice!="" else "휠 / 위아래로 밀어 보기",Vector2(135,r.end.y-49),9,v.active_style.ink,true,222)
	_button(v,m,Rect2(76,r.end.y-36,118,26),"수족관 보기","aback")
func act(v, m, a: String) -> bool:
	var k = a.split(":")
	var i = int(k[1]) if k.size() > 1 else -1
	match k[0]:
		"amanage": v.aqua_manage = true;v.aqua_notice = "";list_bag=true;reset()
		"alist_bag", "alist_tank": list_bag=k[0]=="alist_bag";reset();v.aqua_notice=""
		"aback":
			v.pick_slot=-1;v.aqua_manage=false;reset()
		"afish": v.aqua_selected = i
		"aprev", "anext":
			var delta = 1 if k[0] == "anext" else -1
			if v.pick_slot >= 0: v.aqua_pick_page = maxi(0, v.aqua_pick_page + delta)
			else: v.aqua_page = maxi(0, v.aqua_page + delta)
		"aexpand":
			if m.aqua_expand(): v.aqua_notice = "수족관이 더 넓어졌어요!";m.play("catch")
		"slot":
			if i >= 0 and i < m.aqua.size() and m.aqua[i] == null: v.pick_slot = i;v.aqua_manage=true;list_bag=true;reset();v.aqua_notice = ""
		"put":
			if i<0 or i>=m.bag.size(): return true
			var slot: int=m.aqua.find(null)
			if slot<0: v.aqua_notice="수족관이 가득 찼어요";return true
			var old_bag: Array=m.bag.duplicate(true)
			var f: Dictionary=m.bag[i].duplicate(true);f.erase("shoulder")
			m.aqua[slot]=f;m.bag.remove_at(i)
			if not m._save_game(): m.bag=old_bag;m.aqua[slot]=null;v.aqua_notice="저장하지 못했어요";return true
			v.pick_slot=-1;v.aqua_manage=true;v.aqua_notice="물고기가 수족관에 들어왔어요";m.play("splash_s",-6)
		"take":
			if i<0 or i>=m.aqua.size() or m.aqua[i]==null: return true
			var f: Dictionary=m.aqua[i]
			if float(f.w)>m.bag_cap()-m.bag_weight(): v.aqua_notice="보관통에 자리가 없어요";return true
			m.bag.append(f);m.aqua[i]=null
			if not m._save_game(): m.bag.pop_back();m.aqua[i]=f;v.aqua_notice="저장하지 못했어요";return true
			v.aqua_notice="보관통으로 돌아왔어요"
		_: return false
	return true
