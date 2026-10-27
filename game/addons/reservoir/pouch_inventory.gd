extends RefCounted
const Shop=preload("res://addons/reservoir/soul_pouch_shop.gd")
var opened: bool=false
var result: Array=[]
var started: float=0.0
var error: String=""
var rects: Dictionary={}
var animation: Texture2D
func open(_m) -> void:
	opened=true;result=[];error="";rects={}
func busy(m) -> bool:
	return not result.is_empty() and m.ui_clock-started<1.6
func open_count(m,count: int) -> bool:
	if not result.is_empty(): return false
	if not Shop.open(m.V,m,count): error=m.V.pouch_error;return false
	result=m.V.pouch_last_open.duplicate();started=m.ui_clock;error=""
	return true
func draw(m) -> void:
	var h: float=m.get_viewport_rect().size.y
	var r:=Rect2(20,maxf(m.top_y+70,(h-304)/2),230,304)
	rects={};m.text_items.clear()
	m._ui_rect(Rect2(-m.ox,0,270+2*m.ox,h),Color(.025,.04,.07,.82))
	m.expedition.panel(m,r)
	m._text("어혼 주머니",Vector2(135,r.position.y+29),14,Color("513b29"),true,210)
	var box:=Rect2(71,r.position.y+40,128,128)
	if not result.is_empty() and ResourceLoader.exists("res://art/effects/pouch_open.png"):
		if animation==null: animation=load("res://art/effects/pouch_open.png")
		var frame: int=mini(15,int(maxf(0,m.ui_clock-started)*10))
		m._ui_texture_rect_region(animation,box,Rect2(frame*64,0,64,64))
	else: m._ui_texture_rect(Shop.icon(),Rect2(99,r.position.y+64,72,72))
	if result.is_empty():
		m._text("보유 %d개"%m.expedition.data.pouches,Vector2(135,r.position.y+181),12,Color("513b29"),true,210)
		m._text("주머니 1개 → 랜덤 어혼 1개",Vector2(135,r.position.y+204),10,Color("675c4b"),true,210)
		m._text("물 · 전기 · 독 · 빛 · 어둠 각 20%",Vector2(135,r.position.y+221),8,Color("675c4b"),true,210)
		if error!="": m._text(error,Vector2(135,r.position.y+237),8,Color("a34a40"),true,210)
		button(m,"one",Rect2(32,r.end.y-58,98,27),"1개 열기",m.expedition.data.pouches>0)
		button(m,"all",Rect2(140,r.end.y-58,98,27),"모두 열기",m.expedition.data.pouches>0)
		button(m,"close",Rect2(85,r.end.y-28,100,22),"닫기",true)
	elif busy(m):
		m._text("어혼이 깨어나는 중…",Vector2(135,r.position.y+192),12,Color("247e80"),true,210)
	else:
		m._text("획득한 어혼",Vector2(135,r.position.y+179),12,Color("247e80"),true,210)
		for i in 5:
			var x: float=35+i*41
			m._ui_texture_rect(m.expedition.textures[m.expedition.EFILES[i]],Rect2(x,r.position.y+191,36,36))
			m._text("+%d"%int(result[i]),Vector2(x+18,r.position.y+239),10,Color("513b29"),true,39)
		button(m,"confirm",Rect2(70,r.end.y-43,130,29),"확인",true)
func button(m,key: String,r: Rect2,label: String,enabled: bool) -> void:
	m._ui_style_box(m.sb_btn,r)
	m._text(label,r.get_center()+Vector2(0,4),10,Color("513b29") if enabled else Color("9a8a78"),true,r.size.x-8)
	if enabled: rects[key]=r
func press(m,p: Vector2) -> void:
	if busy(m): return
	for key in rects:
		if not rects[key].has_point(p): continue
		if key in ["close","confirm"]: opened=false;result=[];rects={}
		elif key=="one": open_count(m,1)
		elif key=="all": open_count(m,0)
		return
