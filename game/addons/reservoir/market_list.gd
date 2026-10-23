extends RefCounted
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
var down_fish: Dictionary = {}
var visible: Array = []

func reset() -> void:
	scroll=0;pointer=false;dragged=false;touch_id=-1;down_action="";down_fish={}

func maximum() -> float:
	return maxf(0,count*44.0-8-viewport.size.y)

func action_at(v, p: Vector2) -> String:
	for row in v.rects.get("rows",[]):
		if row[0].has_point(p) and (str(row[1]).begins_with("sell:") or str(row[1]).begins_with("clean:")):
			return str(row[1])
	return ""

func begin(v, m, p: Vector2) -> void:
	pointer=true;dragged=false;origin=p;last=p
	down_action=action_at(v,p);down_fish={}
	if not down_action.is_empty():
		var i:=int(down_action.get_slice(":",1))
		if i<m.bag.size(): down_fish=m.bag[i].duplicate(true)

func move(p: Vector2) -> void:
	if p.distance_to(origin)>5: dragged=true
	if dragged: scroll=clampf(scroll+last.y-p.y,0,maximum())
	last=p

func finish(v, m, p: Vector2) -> void:
	pointer=false
	var action:=action_at(v,p)
	if not dragged and viewport.has_point(p) and action==down_action and not action.is_empty():
		var i:=int(action.get_slice(":",1))
		if i<m.bag.size() and m.bag[i]==down_fish: v._shop_press(m,p)
	down_action="";down_fish={}

func input_event(v, m, e: InputEvent) -> bool:
	if e is InputEventMouseButton or e is InputEventMouseMotion:
		if Time.get_ticks_msec()<native_until: return true
	if v.shop!="work" or v.tab not in ["sell","clean"]: return false
	if m.market_open or m.settings_open or m.lesson_open or not m.trans.is_empty() or not v.commerce.pending.is_empty() or m.inventory.selected>=0: return false
	if e is InputEventScreenTouch:
		var p: Vector2=e.position-Vector2(m.ox,0)
		if e.pressed and touch_id<0 and viewport.has_point(p):
			touch_id=e.index;native_until=Time.get_ticks_msec()+350;begin(v,m,p);return true
		if e.index==touch_id:
			native_until=Time.get_ticks_msec()+350
			if not e.pressed:
				if e.canceled: pointer=false;down_action="";down_fish={}
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

func draw(v, m, r: Rect2, y: float, items: Array) -> void:
	count=items.size()
	viewport=Rect2(r.position.x+10,y,r.size.x-20,maxf(0,r.end.y-(72 if v.tab=="sell" else 28)-y))
	scroll=clampf(scroll,0,maximum());visible=[]
	if items.is_empty():
		reset();m._text("보관통이 비었어요",Vector2(135,y+40),10,Color("6a4a2a"),true);return
	for i in items.size():
		var yy: float=y+i*44-scroll
		if yy<viewport.position.y or yy+36>viewport.end.y: continue
		var f: Dictionary=items[i]
		var nm: String=m.FISH_NAME[int(f.sp)]+(" (어깨)" if f.get("shoulder",false) else "")
		var desc: String="%s · %.1fcm" % [m.GRADE_N[int(f.grade)],float(f.len)]
		v._row(m,r,yy,m.fish_tex[int(f.sp)],nm,desc,"" if v.tab=="sell" else "혼 +%d" % v.soul_of(f),int(f.price) if v.tab=="sell" else 0,true,"%s:%d" % [v.tab,i])
		visible.append(i)
	if maximum()>0:
		var track:=Rect2(r.end.x-7,viewport.position.y,2,viewport.size.y)
		m._ui_rect(track,Color("bba387"))
		var thumb:=maxf(12,viewport.size.y*viewport.size.y/(count*44.0-8))
		m._ui_rect(Rect2(track.position+Vector2(0,(track.size.y-thumb)*scroll/maximum()),Vector2(2,thumb)),Color("705139"))
		m._text("휠 / 위아래로 밀어 보기",Vector2(135,viewport.end.y+10),9,Color("6a4a2a"),true,220)
