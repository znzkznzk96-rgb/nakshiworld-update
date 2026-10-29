extends RefCounted
# Compact left-side bait selection. All stats and inventory belong to region_shop.
var opened := false
var button := Rect2()
var panel := Rect2()
var cells: Array[Rect2] = []
var bare_button := Rect2()
var last_native := -1000
var pointer := -2
var start := Vector2.ZERO
var dragging := false

func visible(m) -> bool:
	return m.scene=="fish" and not m.title_open and not m.lesson_open and not m.menu_open and not m.settings_open and not m.market_open and not m.personal_dex.opened and not m.mailbox.opened and not m.guide.opened and m.expedition.opened=="" and m.trans.is_empty()
func can_change(m) -> bool:
	return m.S.phase=="idle" or (m.S.phase=="result" and not m.S.get("ok",false))
func layout(y: float) -> void:
	button=Rect2(52,y+3,32,32)
	panel=Rect2(6,y-212,204,204)
	cells.clear()
	for i in 6: cells.append(Rect2(14+(i%2)*96,panel.position.y+31+(i/2)*46,92,42))
	bare_button=Rect2(14,panel.end.y-29,188,21)
func draw_button(m,y: float) -> void:
	if not visible(m):
		opened=false;button=Rect2();return
	layout(y)
	var id: int=m.region_shop.selected_bait if can_change(m) else m.S.get("bait_id",m.region_shop.selected_bait)
	m._ui_texture_rect(m.e_slots.slot,button)
	if id>=0:
		m._ui_texture_rect(m.region_shop.bait_icon(id),Rect2(button.position+Vector2(5,3),Vector2(22,22)))
	else: draw_empty_tin(m,button.position+Vector2(5,3))
	var count: String=str(m.region_shop.stock(m,id)) if id>=0 else "—"
	if id>=0 and m.region_shop.stock(m,id)>999: count="999+"
	m._text(count,button.position+Vector2(16,27),8,Color("fff0d1"),true,26,true)
	if can_change(m) and id>=0 and m.region_shop.stock(m,id)==0:
		m._text("소진",button.position+Vector2(16,-3),7,Color("ffcc9b"),true,32,true)
func draw_empty_tin(m,p: Vector2) -> void:
	# Open, visibly empty bait tin: native integer pixel shapes, no equipment hook.
	for part in [
		[Rect2(3,3,16,3),"243536"],[Rect2(4,3,14,1),"b0d4c4"],
		[Rect2(2,7,18,12),"243536"],[Rect2(3,8,16,10),"547c73"],
		[Rect2(4,9,14,5),"b0d4c4"],[Rect2(5,10,12,3),"182f30"],
		[Rect2(4,15,14,2),"729e8c"],[Rect2(6,19,10,1),"182f30"]]:
		var r: Rect2=part[0];r.position+=p;m._ui_rect(r,Color(part[1]))
func draw_popup(m) -> void:
	if not opened or not visible(m): return
	if not can_change(m): opened=false;return
	m._ui_style_box(m.sb_panel,panel)
	m._text("미끼 선택",panel.position+Vector2(102,20),10,Color("513b29"),true,170)
	for i in 6:
		var r: Rect2=cells[i]
		var available: bool=m.region_shop.bait_unlocked(i) and m.region_shop.stock(m,i)>0
		var selected: bool=m.region_shop.selected_bait==i
		m._ui_style_box(m.sb_btn,r)
		if selected:
			m._ui_rect(r.grow(-4),Color("07515c"))
			m._ui_rect(Rect2(r.position+Vector2(6,5),Vector2(r.size.x-12,1)),Color("16a4ab"))
		m._ui_texture_rect(m.region_shop.bait_icon(i),Rect2(r.position+Vector2(4,4),Vector2(23,23)),false,Color.WHITE if available else Color(0.6,0.6,0.6,0.65))
		var ink: Color=Color("fff0d1") if selected else Color("513b29") if available else Color("8e8069")
		m._text(m.region_shop.BAIT_NAMES[i],r.position+Vector2(29,13),8,ink,false,59)
		var count: String="%d개"%m.region_shop.stock(m,i) if m.region_shop.bait_unlocked(i) else "잠김"
		m._text(count,r.position+Vector2(29,24),7,ink,false,56)
		var effect: String="빠른 입질" if i==0 else "대물 유인" if i==1 else "희귀 확률↑"
		m._text(effect,r.position+Vector2(46,35),7,ink,true,84)
		if selected: m._text("✓",r.position+Vector2(84,10),8,Color("fff0d1"),true,10)
	m._ui_style_box(m.sb_btn,bare_button)
	if m.region_shop.selected_bait<0: m._ui_rect(bare_button.grow(-4),Color("07515c"))
	m._text("미끼 없음",bare_button.get_center()+Vector2(0,3),8,Color("fff0d1") if m.region_shop.selected_bait<0 else Color("513b29"),true,170)
func select(m,id: int) -> bool:
	if not can_change(m) or (id>=0 and (not m.region_shop.bait_unlocked(id) or m.region_shop.stock(m,id)<=0)): return false
	if id < -1 or id>5: return false
	m.region_shop.selected_bait=id;m._save_game();opened=false;m.holding=false;m.play("ui");return true
func press(m,p: Vector2) -> bool:
	if not visible(m): return false
	if opened:
		m.holding=false
		for i in cells.size():
			if cells[i].has_point(p): select(m,i);return true
		if bare_button.has_point(p): select(m,-1);return true
		if not panel.has_point(p): opened=false
		return true
	if button.grow(2).has_point(p):
		m.holding=false
		if can_change(m): opened=true;m.play("ui")
		return true
	return false
func input_event(m,e: InputEvent) -> bool:
	if (e is InputEventMouseButton or e is InputEventMouseMotion) and e.device==-1:
		var on_button: bool=e is InputEventMouseButton and visible(m) and button.grow(2).has_point(e.position-Vector2(m.ox,0))
		if opened or pointer!=-2 or on_button or Time.get_ticks_msec()-last_native<500: return true
	if e is InputEventScreenTouch:
		var p: Vector2=e.position-Vector2(m.ox,0)
		if e.pressed and visible(m) and (opened or button.grow(2).has_point(p)):
			last_native=Time.get_ticks_msec()
			if pointer==-2: pointer=e.index;start=p;dragging=false
			return true
		if pointer==e.index:
			last_native=Time.get_ticks_msec();pointer=-2
			if not e.canceled and not dragging: press(m,p)
			return true
		return opened
	if e is InputEventScreenDrag and pointer==e.index:
		last_native=Time.get_ticks_msec();dragging=dragging or e.position.distance_to(start+Vector2(m.ox,0))>5;return true
	if e is InputEventMouseButton and e.button_index==MOUSE_BUTTON_LEFT:
		var p: Vector2=e.position-Vector2(m.ox,0)
		if visible(m) and (opened or button.grow(2).has_point(p)):
			if e.pressed: press(m,p)
			return true
	return opened
