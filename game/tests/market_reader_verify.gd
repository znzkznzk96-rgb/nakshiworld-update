extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func paint(m, height: float=540) -> void:
	m.text_items=[];m.ui_commands=[];m.V.draw_shop(m,height)
func event(m, button: int, pressed: bool, p: Vector2) -> void:
	var e:=InputEventMouseButton.new()
	e.button_index=button;e.pressed=pressed;e.position=p+Vector2(m.ox,0);m._unhandled_input(e)
func run() -> void:
	var m=load("res://main.gd").new()
	m.SET.sfx=0;m.SET.music=0;m.title_open=false;root.add_child(m);await process_frame;m.set_process(false)
	m.title_open=false;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.settings_open=false;m.market_open=false;m.lesson_open=false
	m.scene="village";m.inventory.selected=-1;m.V.commerce.pending={}
	m.bag=[]
	for i in 25:
		m.bag.append({"sp":1,"star":0,"grade":0,"w":0.01,"len":float(10+i),"price":100+i,"shoulder":false})
	m.V.open_shop(m,"work");paint(m)
	var list=m.V.market_list
	var before: Array=m.bag.duplicate(true)
	var gold: int=m.gold
	var souls: int=m.souls
	var p: Vector2=list.viewport.get_center()
	for i in 40: event(m,MOUSE_BUTTON_WHEEL_DOWN,true,p)
	paint(m)
	check(list.visible.has(24),"last fish reachable by wheel")
	check(list.scroll==list.maximum(),"wheel bounded")
	check(m.bag==before and m.gold==gold and m.souls==souls,"scroll preserves fish and currency")
	for row in m.V.rects.rows:
		if str(row[1]).begins_with("sell:"):
			check(row[0].position.y>=list.viewport.position.y and row[0].end.y<=list.viewport.end.y,"buttons inside viewport")
		if row[1]=="sellall": check(row[0].position.y>list.viewport.end.y,"sell all fixed outside scrolling")
	var target:=Vector2.ZERO
	for row in m.V.rects.rows:
		if row[1]=="sell:24": target=row[0].get_center()
	check(target!=Vector2.ZERO,"last sell button")
	event(m,MOUSE_BUTTON_LEFT,true,target)
	var drag:=InputEventMouseMotion.new();drag.position=target+Vector2(m.ox,-35);m._unhandled_input(drag)
	event(m,MOUSE_BUTTON_LEFT,false,target+Vector2(0,-35))
	check(m.bag==before,"mouse drag cannot sell")
	list.scroll=list.maximum();paint(m)
	event(m,MOUSE_BUTTON_LEFT,true,target);event(m,MOUSE_BUTTON_LEFT,false,target)
	check(m.bag.size()==24 and m.gold==gold+124 and m.bag.back().len==33.0,"last fish sold exactly once")
	m.V._act(m,"tab:clean");paint(m)
	check(list.scroll==0,"tab resets scroll")
	p=list.viewport.get_center()
	var touch:=InputEventScreenTouch.new();touch.index=0;touch.pressed=true;touch.position=p+Vector2(m.ox,0);m._unhandled_input(touch)
	var move:=InputEventScreenDrag.new();move.index=0;move.position=p+Vector2(m.ox,-70);m._unhandled_input(move)
	touch.pressed=false;touch.position=move.position;m._unhandled_input(touch)
	check(list.scroll>0 and m.bag.size()==24 and m.souls==souls,"touch drag scrolls without cleaning")
	list.native_until=0;list.scroll=list.maximum();paint(m)
	target=Vector2.ZERO
	for row in m.V.rects.rows:
		if row[1]=="clean:23": target=row[0].get_center()
	check(target!=Vector2.ZERO,"last clean button")
	var reward: int=m.V.soul_of(m.bag.back())
	event(m,MOUSE_BUTTON_LEFT,true,target);event(m,MOUSE_BUTTON_LEFT,false,target)
	check(m.bag.size()==23 and m.souls==souls+reward,"correct offscreen fish cleaned")
	for height in [480,540,600]:
		list.scroll=99999;paint(m,height)
		check(list.scroll<=list.maximum() and list.visible.has(22),"resized viewport clamps and reaches final fish")
	m.bag=[];paint(m);check(list.scroll==0 and list.visible.is_empty(),"empty list clears scroll")
	var layout=load("res://addons/reservoir/text_layout.gd")
	for text in ["물고기를 선택한 뒤 판매하거나 손질할 수 있어요. 아래 목록도 천천히 확인해 주세요.", "가나다라마바사아자차카타파하가나다라마바사아자차카타파하", "안내 문장을 읽고 보상을 받아 주세요!"]:
		for width in [80,150,208]:
			var lines: Array=layout.wrap(m,text,11,width)
			check("".join(lines)==text,"wrap preserves source")
			for line in lines: check(m._text_w(line,11)<=width,"real font width bounded")
	for width in range(70,209,7):
		var lines: Array=layout.wrap(m,"설명 문장은 끝까지 읽어 주세요. 다음 페이지로 넘어가요",11,width)
		if lines.size()>1 and str(lines.back()).strip_edges().length()<=2:
			var previous: String=lines[lines.size()-2]
			var boundary:=previous.strip_edges().rfind(" ")
			if boundary>0:
				check(m._text_w(previous.substr(boundary+1)+str(lines.back()),11)>width,"short final line only when no whole word fits")
	var reader=load("res://addons/reservoir/topic_reader.gd")
	var paragraphs: Array=[]
	for i in 20: paragraphs.append("긴 설명도 빠짐없이 확인할 수 있도록 다음 페이지에 이어서 표시합니다.")
	var restored:=""
	for page in reader.pages(m,paragraphs):
		check(page.size()<=6,"reader page bounds")
		for line in page: restored+=line
	check(restored=="".join(paragraphs),"long reader retains all content")
	print("MARKET_READER_VERIFY failures=",failures)
	m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
