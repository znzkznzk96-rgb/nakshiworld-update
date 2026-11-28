extends RefCounted
const TANK = preload("res://art/aquarium/tank_cozy.png")
const PLANTS = preload("res://art/aquarium/tank_plants.png")
const RS = preload("res://addons/reservoir/shop_restyle.gd")
# 수조 그림(244x256)을 세 기둥(왼 선반·물·오른 선반)으로 나눠 화면 높이에 맞춘다. 늘리지 않고
# 0=고정 구간, 1=민무늬 구간(줄을 복제·생략해 길이를 맞춤), 2=높이가 모자라면 빼는 장식 구간.
const COLS = [[0, 36, [[0, 32, 0], [32, 98, 2], [98, 103, 1], [103, 166, 0], [166, 176, 1], [176, 256, 0]]],
	[36, 204, [[0, 48, 0], [48, 128, 1], [128, 256, 0]]],
	[204, 244, [[0, 54, 0], [54, 106, 2], [106, 160, 0], [160, 176, 1], [176, 256, 0]]]]
var tank_layout := []
var effects_enabled := true
var icon_cache := {}
var room_bounds := Rect2()
var swim_bounds := Rect2()
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
	m._ui_style_box(m.sb_btn, r)
	m._text(label, r.position + Vector2(r.size.x / 2, 18), 10, Color("513b29") if enabled else Color("817767"), true, r.size.x - 6)
	if enabled or (action == "aexpand" and m.FACILITIES.unlocked(m,"aexpand")): v.rects.rows.append([r, action])
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

func _icon(m, name: String, r: Rect2) -> void:
	if not icon_cache.has(name):
		var path: String="res://art/ui/aquarium/"+name+".png"
		if ResourceLoader.exists(path): icon_cache[name]=load(path)
	if icon_cache.has(name): m._ui_texture_rect(icon_cache[name],r)

func draw_room(v,m,h: float) -> void:
	var top: float=m.top_y+76
	# Preserve the displayed tank dimensions; compact only its surrounding UI.
	var tank_height: float=maxf(188.0,h-m.top_y-312)   # 새 수조 그림의 최소 높이(장식을 빼도 남는 고정 구간)
	var r:=Rect2(8,top,254,62+tank_height+80)
	v.active_style={"panel":m.sb_btn,"header":m.hud_reference_style,"card":m.sb_btn,"ink":RS.INK,"icon":"soul"}
	RS.panel(m,r)
	var header:=Rect2(r.position+Vector2(4,4),Vector2(246,30))
	preload("res://addons/reservoir/shop_restyle.gd").header(m,header)
	m._ui_texture_rect(v.tool_icons.soul,Rect2(header.position+Vector2(8,4),Vector2(22,22)))
	m._text("수족관",Vector2(135,header.position.y+21),14,Color("fff0d1"),true,170)
	var close:=Rect2(header.end.x-29,header.position.y+4,22,23)
	m._ui_texture(m.icons.close,close.position)
	v.rects={"close":close.grow(3),"panel":r,"rows":[]}
	draw(v,m,r,r.position.y+42)

func _effects(m, r: Rect2, front: bool) -> void:
	if not effects_enabled: return
	var t: float=m.ui_clock
	if not front:
		# Light shafts are independent translucent polygons behind the fish.
		for i in 3:
			var x: float=r.position.x+r.size.x*(.2+i*.28)+sin(t*.3+i)*3
			var pts:=PackedVector2Array([Vector2(x,r.position.y),Vector2(x+7,r.position.y),Vector2(x+21,r.end.y),Vector2(x-14,r.end.y)])
			var col:=Color(.65,.94,.84,.055+.018*sin(t*.7+i))
			m._ui_polygon(pts,PackedColorArray([col,col,Color(col,0),Color(col,0)]))

	else:
		# Bubble positions wrap inside the water and never touch the frame.
		for i in 12:
			var x: float=r.position.x+5+fposmod(i*37.0,r.size.x-10)+sin(t+i)*1.5
			var y: float=r.end.y-fposmod(t*(6+i%3)+i*19,r.size.y-4)
			var p:=Vector2(roundf(x),roundf(y))
			m._ui_rect(Rect2(p,Vector2(1,2)),Color(.7,.96,.96,.5))
			m._ui_rect(Rect2(p+Vector2(1,-1),Vector2(2,1)),Color(.7,.96,.96,.35))

func draw(v, m, r: Rect2, y: float) -> void:
	v.commerce.feedback_rect=Rect2(18,r.end.y-25,234,18);v.commerce.feedback_dark=false
	var chip:=Rect2(13,y-6,244,25)
	RS.frame(m,chip,Color("f3e5c5"))
	m._text("%d / %d마리 · 분당 %.1f 비늘"%[m.aqua_count(),m.aqua_capacity(),m.aqua_rate()],chip.get_center()+Vector2(0,4),10,RS.INK,true,232)
	if v.pick_slot>=0 or v.aqua_manage:
		v.active_style.ink=Color("513b29")
		fish_rects.clear();room_bounds=Rect2();swim_bounds=Rect2()
		m._ui_rect(Rect2(14,y+21,242,r.end.y-y-27),Color("e6eee4"))
		_manage(v,m,r,y+22)
		return
	room_bounds=Rect2(13,y+20,244,floorf(r.size.y-142))
	_tank(m,room_bounds)
	var water:=Rect2(room_bounds.position+Vector2(44,_map(1,40)),Vector2(152,_map(1,214)-_map(1,40)))
	_effects(m,water,false)
	if effects_enabled: _plants(m,room_bounds);_gadgets(m,room_bounds)
	swim_bounds=Rect2(water.position+Vector2(6,6),water.size-Vector2(12,32))
	fish_rects.clear()
	var visible_index: int=0
	for i in m.aqua.size():
		var f=m.aqua[i]
		if f==null: continue
		var phase: float=fposmod(m.ui_clock*(.018+(i%4)*.002)+i*.618034,2.0)
		var travel: float=phase if phase<=1 else 2-phase
		var lanes: int=mini(4,maxi(1,m.aqua_count()))
		var fishw: float=clampf(20+sqrt(float(f.get("len",20)))*2,24,minf(38,20+64/sqrt(maxi(1,m.aqua_count()))))
		var fishh: float=minf(16,swim_bounds.size.y/lanes-2)
		var lane: float=(visible_index%lanes+.5)/lanes
		var center:=Vector2(swim_bounds.position.x+fishw/2+travel*(swim_bounds.size.x-fishw),swim_bounds.position.y+lane*swim_bounds.size.y)
		center.y+=sin(m.ui_clock*.4+i)*minf(2,(swim_bounds.size.y/lanes-fishh)/2)
		var box:=Rect2((center-Vector2(fishw,fishh)/2).round(),Vector2(fishw,fishh))
		_fish(m,f,box,phase>1)
		fish_rects.append([box,i])
		if i==v.aqua_selected:
			m._ui_rect(Rect2(box.position-Vector2(1,2),Vector2(4,1)),Color("ffdf8d"))
			m._ui_rect(Rect2(box.end+Vector2(-3,1),Vector2(4,1)),Color("ffdf8d"))
		visible_index+=1
	_effects(m,water,true)
	for j in range(fish_rects.size()-1,-1,-1): v.rects.rows.append([fish_rects[j][0],"afish:%d"%fish_rects[j][1]])
	var info: String="물고기를 눌러 살펴보세요" if m.aqua_count()>0 else "물고기를 넣어 전시를 시작해 보세요"
	if v.aqua_selected>=0 and v.aqua_selected<m.aqua.size() and m.aqua[v.aqua_selected]!=null:
		var f: Dictionary=m.aqua[v.aqua_selected]
		info="%s · %s · %.1fcm"%[m.FISH_NAME[int(f.sp)],m.GRADE_N[int(f.grade)],float(f.len)]
	m._text(info,Vector2(135,room_bounds.end.y+14),9,v.active_style.ink,true,232)
	var buttons_y: float=room_bounds.end.y+20
	var manage:=Rect2(15,buttons_y,116,36)
	var expand:=Rect2(135,buttons_y,120,36)
	RS.draw_art(m,"button",manage);RS.draw_art(m,"button",expand)
	_icon(m,"manage",Rect2(manage.position+Vector2(6,7),Vector2(22,22)))
	m._text("물고기 관리",manage.get_center()+Vector2(12,4),10,Color("fff0d1"),true,82)
	v.rects.rows.append([manage,"amanage"])
	_icon(m,"expand",Rect2(expand.position+Vector2(4,5),Vector2(19,19)))
	m._text("수족관 확장",Vector2(201,expand.position.y+14),9,Color("fff0d1"),true,91)
	if m.FACILITIES.unlocked(m,"aexpand"):
		m._text("%d→%d · %d비늘"%[m.aqua_capacity(),m.AQUA_CAP[m.aqua_lv+1],m.AQUA_COST[m.aqua_lv]],Vector2(195,expand.position.y+29),7,Color("f0c46e") if m.gold>=m.AQUA_COST[m.aqua_lv] else Color("e89c85"),true,114)
		v.rects.rows.append([expand,"aexpand"])
	else: m._text(m.FACILITIES.lock_label(m,"aexpand"),Vector2(195,expand.position.y+29),7,Color("cfe6e0"),true,110)
	m._text(v.aqua_notice if v.aqua_notice!="" else "쉬는 동안에도 최대 %d시간 수입" % m.AQUARIUM_OFFLINE_HOURS,Vector2(135,r.end.y-13),9,Color("6e5c49"),true,232)

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
		var allowed:bool=not list_bag or m.aqua_can_add(f)
		v._row(m,r,yy,m.fish_tex[int(f.sp)],m.FISH_NAME[int(f.sp)],"%s · %.1fcm"%[m.GRADE_N[int(f.grade)],float(f.len)],("넣기" if allowed else "전시 중") if list_bag else "빼기",0,allowed,("put:" if list_bag else "take:")+str(i))
	if items.is_empty(): m._text("보관통이 비었어요" if list_bag else "전시 중인 물고기가 없어요",Vector2(135,y+25),11,v.active_style.ink,true,220)
	if maximum()>0:
		var thumb:=maxf(12,viewport.size.y*viewport.size.y/(count*44.0-8))
		m._ui_rect(Rect2(248,y,2,viewport.size.y),Color("bba387"))
		m._ui_rect(Rect2(248,y+(viewport.size.y-thumb)*scroll/maximum(),2,thumb),Color("705139"))
	m._text(v.aqua_notice if v.aqua_notice!="" else "주인은 종류별 1마리 · 밀어서 보기",Vector2(135,r.end.y-49),9,v.active_style.ink,true,222)
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
			if not m.aqua_can_add(m.bag[i]): v.aqua_notice="같은 종류의 주인은 1마리만 전시할 수 있어요";return true
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

## 높이 h에 맞춘 기둥별 구간 [원본 시작, 원본 끝, 화면 시작, 화면 끝, 종류]
func _layout(h: float) -> void:
	tank_layout = []
	for col in COLS:
		var fixed := 0;var opt := 0;var flex := 0
		for s in col[2]:
			var n: int = s[1] - s[0]
			if s[2] == 0: fixed += n
			elif s[2] == 1: flex += n
			else: opt += n
		var keep_opt: bool = h - fixed - opt >= 0
		var room: int = maxi(0, int(h) - fixed - (opt if keep_opt else 0))
		var segs := [];var y := 0;var given := 0
		var flex_left := flex
		for s in col[2]:
			var n: int = s[1] - s[0]
			if s[2] == 2 and not keep_opt: continue
			if s[2] == 1:
				var share: int = room - given if n == flex_left else int(round(float(room) * n / flex))
				given += share;flex_left -= n;n = share
			segs.append([s[0], s[1], y, y + n, s[2]]);y += n
		tank_layout.append(segs)

## 원본 y가 화면(수조 안)에서 어디에 오는지. 빠진 장식 구간이면 -1
func _map(c: int, y: float) -> float:
	for s in tank_layout[c]:
		if y >= s[0] and y < s[1]:
			if s[4] == 1: return s[2] + (y - s[0]) * (s[3] - s[2]) / maxf(1.0, s[1] - s[0])
			return s[2] + y - s[0]
	return -1.0

func _tank(m, room: Rect2) -> void:
	_layout(room.size.y)
	for c in COLS.size():
		var x0: int = COLS[c][0];var w: int = COLS[c][1] - x0
		for s in tank_layout[c]:
			var dst_h: int = s[3] - s[2]
			if dst_h <= 0: continue
			if s[4] != 1:
				m._ui_texture_rect_region(TANK, Rect2(room.position + Vector2(x0, s[2]), Vector2(w, dst_h)), Rect2(x0, s[0], w, dst_h))
				continue
			var src_h: int = s[1] - s[0]
			var i := 0
			while i < dst_h:   # 민무늬 구간: 원본 줄을 정수 줄 단위로 복제하거나 건너뛴다
				var sy: int = s[0] + int(i * src_h / dst_h)
				var run := 1
				while i + run < dst_h and s[0] + int((i + run) * src_h / dst_h) == sy: run += 1
				m._ui_texture_rect_region(TANK, Rect2(room.position + Vector2(x0, s[2] + i), Vector2(w, run)), Rect2(x0, sy, w, 1))
				i += run

## 바닥 수초: 뿌리는 그대로, 위로 갈수록 좌우로 살랑(정수 도트)
func _plants(m, room: Rect2) -> void:
	var t: float = m.ui_clock
	for y in range(135, 206):
		var dy: float = _map(1, y)
		if dy < 0: continue
		var amp: float = 2.0 * (205.0 - y) / 70.0
		for half in 2:
			var x0: int = 36 if half == 0 else 120
			var off: float = roundf(sin(t * 1.3 + y * 0.07 + half * 1.9) * amp)
			m._ui_texture_rect_region(PLANTS, Rect2(room.position + Vector2(x0 + off, dy), Vector2(84, 1)), Rect2(x0, y, 84, 1))

func _dot(m, room: Rect2, c: int, p: Vector2, s: Vector2, col: Color) -> void:
	var dy: float = _map(c, p.y)
	if dy >= 0: m._ui_rect(Rect2((room.position + Vector2(p.x, dy)).round(), s), col)

## 선반 물건: 전구 반짝, 하트 두근, 구슬 빛, 온도계·게이지 오르내림, 버튼 깜빡, 병 속 기포
func _gadgets(m, room: Rect2) -> void:
	var t: float = m.ui_clock
	var bulbs := [[0, Vector2(15, 18)], [0, Vector2(32, 20)], [1, Vector2(49, 18)], [1, Vector2(192, 18)], [2, Vector2(206, 20)], [2, Vector2(228, 18)]]
	for i in bulbs.size():
		var a: float = 0.15 + 0.35 * (0.5 + 0.5 * sin(t * 2.3 + i * 1.7))
		_dot(m, room, bulbs[i][0], bulbs[i][1] - Vector2(2, 2), Vector2(5, 5), Color(1, 0.9, 0.5, a * 0.5))
		_dot(m, room, bulbs[i][0], bulbs[i][1] - Vector2(1, 1), Vector2(3, 3), Color(1, 0.95, 0.7, a))
	var beat: float = fposmod(t, 1.2)
	var pulse: float = maxf(0.0, 1.0 - beat / 0.25) + maxf(0.0, 1.0 - absf(beat - 0.32) / 0.12) * 0.6
	_dot(m, room, 0, Vector2(6, 109), Vector2(13, 12), Color(1, 0.6, 0.7, 0.35 * pulse))
	var oa: float = t * 1.6
	_dot(m, room, 0, Vector2(12 + roundf(cos(oa) * 3), 129 + roundf(sin(oa) * 3)), Vector2(1, 1), Color(1, 1, 1, 0.9))
	var lv: int = 3 + int(round(5.0 * (0.5 + 0.5 * sin(t * 0.8))))
	_dot(m, room, 0, Vector2(12, 145), Vector2(1, 10), Color("e9f3f4"))
	_dot(m, room, 0, Vector2(12, 155 - lv), Vector2(1, lv), Color("d8434e"))
	for k in 2:
		var on: bool = int(t * 1.5) % 2 == k
		_dot(m, room, 0, Vector2(14, 184 if k == 0 else 227), Vector2(7, 4), Color(1, 0.95, 0.6, 0.45 if on else 0.0))
	var lit: int = int(t * 2.5) % 5
	for k in 4:
		_dot(m, room, 2, Vector2(219 + k * 4, 44), Vector2(3, 4), Color("7ff5ff") if k < lit else Color("1d4250"))
	var fill: int = 6 + int(round(12.0 * (0.5 + 0.5 * sin(t * 0.7))))
	_dot(m, room, 2, Vector2(214, 182), Vector2(20, 4), Color("26303a"))
	_dot(m, room, 2, Vector2(214, 182), Vector2(fill, 4), Color("f2a33a"))
	var nx: float = 220.0 + roundf(sin(t * 1.1) * 6.0)
	_dot(m, room, 2, Vector2(nx, 193), Vector2(1, 5), Color("2b3640"))
	var blink: bool = int(t * 2.0) % 2 == 0
	_dot(m, room, 2, Vector2(212, 208), Vector2(9, 9), Color(1, 0.7, 0.7, 0.4 if blink else 0.0))
	_dot(m, room, 2, Vector2(228, 208), Vector2(9, 9), Color(0.7, 1, 0.7, 0.0 if blink else 0.4))
	for k in 3:
		var jx: float = [214.0, 229.0, 230.0][k];var jy0: float = [72.0, 72.0, 150.0][k]
		var ph: float = fposmod(t * 0.7 + k * 0.37, 1.0)
		_dot(m, room, 2, Vector2(jx, jy0 - roundf(ph * 10.0)), Vector2(1, 1), Color(0.85, 1, 1, 0.8 * (1.0 - ph)))
	m._text("수족관", room.position + Vector2(122, _map(1, 25)), 12, Color("f6d58f"), true, 70)
