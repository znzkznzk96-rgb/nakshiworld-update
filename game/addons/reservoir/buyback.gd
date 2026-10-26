extends RefCounted
# Persist exact sold specimens; stable IDs protect confirmation dialogs from list shifts.
const LIMIT := 10
var entries: Array = []
var next_id := 1
var scroll := 0.0
var viewport := Rect2()
var pointer := false
var dragged := false
var start := Vector2.ZERO
var last := Vector2.ZERO
func restore(data: Dictionary) -> void:
	entries = [];next_id = maxi(1,int(data.get("next_id",1)));scroll=0.0
	for entry in data.get("entries",[]):
		if entry is Dictionary and entry.get("fish") is Dictionary and int(entry.get("id",0))>0:
			entries.append(entry.duplicate(true));next_id=maxi(next_id,int(entry.id)+1)
		if entries.size()==LIMIT: break
func serialize() -> Dictionary: return {"entries":entries.duplicate(true),"next_id":next_id}
func remember(fish: Dictionary) -> void:
	entries.push_front({"id":next_id,"fish":fish.duplicate(true),"sold_price":maxi(0,int(fish.get("price",0)))})
	next_id+=1
	while entries.size()>LIMIT: entries.pop_back()
func find(id: int) -> Dictionary:
	for entry in entries:
		if int(entry.id)==id: return entry
	return {}
func price(entry: Dictionary) -> int:
	return ceili(int(entry.get("sold_price",0))*1.2)
func can_receive(m, entry: Dictionary) -> bool:
	return not entry.is_empty() and (float(entry.fish.get("w",0))<=m.bag_cap()-m.bag_weight() or not m.bag_shoulder())
func purchase(m, id: int) -> bool:
	var entry:=find(id)
	if entry.is_empty() or not can_receive(m,entry) or m.gold<price(entry): return false
	var fish: Dictionary=entry.fish.duplicate(true)
	fish.shoulder=float(fish.get("w",0))>m.bag_cap()-m.bag_weight()
	m.gold-=price(entry);m.bag.append(fish);entries.erase(entry);m._save_game()
	return true
func input_event(m, e: InputEvent) -> bool:
	if m.V.shop!="work" or m.V.tab!="buyback" or not m.V.commerce.pending.is_empty(): pointer=false;return false
	if e is InputEventMouseButton:
		var p: Vector2=e.position-Vector2(m.ox,0)
		if e.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and viewport.has_point(p):
			if e.pressed: scroll=clampf(scroll+(36 if e.button_index==MOUSE_BUTTON_WHEEL_DOWN else -36),0,max_scroll())
			return true
		if e.button_index==MOUSE_BUTTON_LEFT:
			if e.pressed and viewport.has_point(p): pointer=true;dragged=false;start=p;last=p;return true
			if not e.pressed and pointer:
				pointer=false
				if not dragged: m.V._shop_press(m,p)
				return true
	if e is InputEventMouseMotion and pointer:
		var p: Vector2=e.position-Vector2(m.ox,0)
		if p.distance_to(start)>5: dragged=true
		if dragged: scroll=clampf(scroll-(p.y-last.y),0,max_scroll())
		last=p;return true
	return false
func max_scroll() -> float: return maxf(0,entries.size()*44.0-viewport.size.y)
func draw(v, m, r: Rect2, y: float) -> void:
	m._text("최근 판매 10마리 · 판매가 +20%",Vector2(135,y+8),9,Color("68533d"),true,228)
	viewport=Rect2(r.position.x+10,y+18,r.size.x-20,r.end.y-y-36)
	scroll=clampf(scroll,0,max_scroll())
	if entries.is_empty(): m._text("재구매할 물고기가 없어요",viewport.get_center(),10,Color("68533d"),true,220);return
	# Draw only fully visible rows: no card/text can leak over the tabs or footer.
	for i in entries.size():
		var yy: float=viewport.position.y+i*44-scroll
		if yy<viewport.position.y or yy+36>viewport.end.y: continue
		var entry: Dictionary=entries[i];var f: Dictionary=entry.fish
		v._row(m,r,yy,m.fish_tex[int(f.sp)],m.FISH_NAME[int(f.sp)],"%s · %.1fcm"%[m.GRADE_N[int(f.grade)],float(f.len)],"",price(entry),true,"buyback:%d"%int(entry.id))
		v.rects.rows.append([Rect2(r.position.x+11,yy,r.size.x-22,36),"buyback:%d"%int(entry.id)])
	if max_scroll()>0:
		var bar_h: float=maxf(18,viewport.size.y*viewport.size.y/(entries.size()*44.0))
		m._ui_rect(Rect2(r.end.x-6,viewport.position.y+scroll/max_scroll()*(viewport.size.y-bar_h),2,bar_h),Color("a98b5c"))
	m._text("위아래로 밀어서 선택하세요",Vector2(135,r.end.y-9),8,Color("68533d"),true,220)
