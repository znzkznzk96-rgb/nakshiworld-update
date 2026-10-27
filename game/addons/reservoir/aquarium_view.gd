extends RefCounted
const ROOM = preload("res://art/aquarium/tank_clean.png")
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
func _dark_panel(m, r: Rect2, fill: Color = Color("123b47")) -> void:
	m._ui_style_box(m.hud_reference_style,r)
	m._ui_rect(Rect2(r.position+Vector2(4,4),r.size-Vector2(8,8)),fill)

func _icon(m, name: String, r: Rect2) -> void:
	if not icon_cache.has(name):
		var path: String="res://art/ui/aquarium/"+name+".png"
		if ResourceLoader.exists(path): icon_cache[name]=load(path)
	if icon_cache.has(name): m._ui_texture_rect(icon_cache[name],r)

func draw_room(v,m,h: float) -> void:
	var top: float=m.top_y+88
	var r:=Rect2(8,top,254,h-top-10)
	v.active_style={"panel":m.sb_btn,"header":m.hud_reference_style,"card":m.sb_btn,"ink":Color("fff0d1"),"icon":"soul"}
	_dark_panel(m,r,Color("132c37"))
	var header:=Rect2(r.position+Vector2(4,4),Vector2(246,34))
	_dark_panel(m,header)
	m._ui_texture_rect(v.tool_icons.soul,Rect2(header.position+Vector2(8,6),Vector2(22,22)))
	m._text("수족관",Vector2(135,header.position.y+23),14,Color("fff0d1"),true,170)
	var close:=Rect2(header.end.x-29,header.position.y+6,22,23)
	m._ui_texture(m.icons.close,close.position)
	v.rects={"close":close.grow(3),"panel":r,"rows":[]}
	draw(v,m,r,r.position.y+48)

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
		# Separate pixel stems and leaves gently sway; none are baked into the tank.
		for i in 7:
			var x: float=r.position.x+10+i*(r.size.x-20)/6
			for stem in 3:
				var height: int=12+(i%3)*7+stem*4
				for j in int(height/3):
					var sway: float=roundf(sin(t*1.1+i+stem*.6+j*.18)*j*.3)
					var p:=Vector2(x+(stem-1)*j*.7+sway,r.end.y-j*3)
					m._ui_rect(Rect2(p.round(),Vector2(2,4)),Color("4c8450"))
					if j>0 and j%2==0:
						var side: float=-1 if (j+stem)%4<2 else 1
						m._ui_rect(Rect2((p+Vector2(-4 if side<0 else 1,-1)).round(),Vector2(5,3)),Color("719b4e"))
						m._ui_rect(Rect2((p+Vector2(-3 if side<0 else 2,-2)).round(),Vector2(3,1)),Color("a3b65a"))

	else:
		# Bubble positions wrap inside the water and never touch the frame.
		for i in 12:
			var x: float=r.position.x+5+fposmod(i*37.0,r.size.x-10)+sin(t+i)*1.5
			var y: float=r.end.y-fposmod(t*(6+i%3)+i*19,r.size.y-4)
			var p:=Vector2(roundf(x),roundf(y))
			m._ui_rect(Rect2(p,Vector2(1,2)),Color(.7,.96,.96,.5))
			m._ui_rect(Rect2(p+Vector2(1,-1),Vector2(2,1)),Color(.7,.96,.96,.35))

func draw(v, m, r: Rect2, y: float) -> void:
	var chip:=Rect2(13,y-6,244,25)
	_dark_panel(m,chip)
	m._text("%d / %d마리 · 분당 %.1f 비늘"%[m.aqua_count(),m.aqua_capacity(),m.aqua_rate()],chip.get_center()+Vector2(0,4),10,Color("e8f1df"),true,232)
	if v.pick_slot>=0 or v.aqua_manage:
		v.active_style.ink=Color("513b29")
		fish_rects.clear();room_bounds=Rect2();swim_bounds=Rect2()
		m._ui_rect(Rect2(14,y+21,242,r.end.y-y-27),Color("e6eee4"))
		_manage(v,m,r,y+22)
		return
	room_bounds=Rect2(13,y+23,244,r.end.y-143-(y+23))
	m._ui_texture_rect(ROOM,room_bounds)
	var water:=Rect2(room_bounds.position+Vector2(12,room_bounds.size.y*.14),Vector2(220,room_bounds.size.y*.69))
	_effects(m,water,false)
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
	var buttons_y: float=room_bounds.end.y+24
	var manage:=Rect2(15,buttons_y,240,40)
	var expand:=Rect2(15,buttons_y+45,240,45)
	_dark_panel(m,manage,Color("155363"));_dark_panel(m,expand)
	_icon(m,"manage",Rect2(manage.position+Vector2(16,4),Vector2(32,32)))
	m._text("물고기 관리",manage.get_center()+Vector2(12,5),14,Color("fff0d1"),true,165)
	v.rects.rows.append([manage,"amanage"])
	_icon(m,"expand",Rect2(expand.position+Vector2(10,7),Vector2(30,30)))
	m._text("수족관 확장",Vector2(151,expand.position.y+17),11,Color("fff0d1"),true,185)
	if m.aqua_lv<4:
		m._text("%d → %d마리 · %d 비늘"%[m.aqua_capacity(),m.AQUA_CAP[m.aqua_lv+1],m.AQUA_COST[m.aqua_lv]],Vector2(151,expand.position.y+33),9,Color("f0c46e") if m.gold>=m.AQUA_COST[m.aqua_lv] else Color("e89c85"),true,185)
		v.rects.rows.append([expand,"aexpand"])
	else: m._text("최대 크기 · %d마리"%m.aqua_capacity(),Vector2(151,expand.position.y+33),9,Color("a4bdba"),true,180)
	m._text(v.aqua_notice if v.aqua_notice!="" else "쉬는 동안에도 최대 8시간 수입",Vector2(135,r.end.y-13),9,Color("b3cccb"),true,232)

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
