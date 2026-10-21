extends RefCounted
# Design preview only. No inventory, currency, unlock, or save mutations.
const SPOTS = preload("res://addons/reservoir/spot_selection.gd")
var region := 0
var tab := 0
var selected := -1
var rects := {}
var legacy_dex := false
var licenses := {}
func button(m, key: String, label: String, r: Rect2, active: bool=false) -> void:
	m._ui_style_box(m.sb_primary if active else m.sb_btn,r)
	m._text(label,r.get_center()+Vector2(0,4),12,Color("fff0d1") if active else Color("382619"),true,r.size.x-10)
	rects[key]=r
func draw(m,h: float) -> void:
	m.text_items.clear();m.ui_commands.clear();rects.clear()
	m._ui_rect(Rect2(-m.ox,0,270+2*m.ox,h),Color("17383f"))
	var available: float=h-m.top_y-8
	var panel_height: float=minf(490.0,available-32.0)
	var r:=Rect2(7,m.top_y+floorf((available-panel_height)/2.0),256,panel_height)
	m._ui_style_box(m.sb_panel,r)
	var head:=Rect2(12,r.position.y+5,246,32)
	m._ui_style_box(m.hud_reference_style,head)
	m._text("어류 박물관",head.get_center()+Vector2(-8,5),14,Color("fff0d1"),true,190)
	m._ui_texture(m.icons.close,Vector2(head.end.x-27,head.position.y+5));rects.close=Rect2(head.end.x-31,head.position.y,31,32)
	var y: float=head.end.y+7
	var map:=Rect2(17,y,236,56)
	# Reuse existing region artwork with layered inset/shadow, rather than new paintings.
	m._ui_rect(Rect2(map.position+Vector2(0,2),map.size),Color("8b7650"))
	m._ui_rect(map,Color("275665"))
	for x in range(32,240,8): m._ui_rect(Rect2(x,y+28,3,2),Color("e9d9b3"))
	var start:=clampi(region-1,0,3)
	for j in 3:
		var n:=start+j
		var tile:=Rect2(25+j*79,y+7,62,38)
		m._ui_rect(Rect2(tile.position+Vector2(2,3),tile.size),Color(0,0,0,0.3))
		m._ui_rect(tile.grow(2),Color("e5c671") if n==region else Color("587782"))
		var tex: Texture2D=m.spots.images[n]
		var ts:=tex.get_size()
		m._ui_texture_rect_region(tex,tile,Rect2(0,0,ts.x,ts.x*38.0/62.0),Color.WHITE if n==region else Color(0.55,0.62,0.63))
		m._text(str(n+1),Vector2(tile.position.x+7,tile.end.y-3),9,Color("fff0d1"),true,12,true)
		rects["region:%d"%n]=tile.grow(3)
		if n==region: m._ui_rect(Rect2(tile.position.x+18,tile.end.y+4,26,2),Color("e5c671"))
	y=map.end.y+6
	button(m,"prev","<",Rect2(17,y,30,24));button(m,"next",">",Rect2(223,y,30,24))
	m._text(SPOTS.NAMES[region],Vector2(135,y+15),12,Color("382619"),true,170)
	y+=30
	button(m,"main","필수 번들",Rect2(17,y,115,26),tab==0)
	button(m,"sub","서브 번들",Rect2(138,y,115,26),tab==1)
	y+=36
	m._text("다음 낚시터 준비" if tab==0 else "해금 자금 모으기",Vector2(22,y+4),12,Color("382619"),false,195)
	
	y+=12
	var bottom: float=r.end.y-9
	var grid_end: float=bottom-103
	var cell_h: float=floorf((grid_end-y-5)/2.0)
	for i in 6:
		var cell:=Rect2(19+(i%3)*79,y+floori(i/3.0)*(cell_h+5),74,cell_h)
		m._ui_rect(Rect2(cell.position+Vector2(0,2),cell.size),Color("c6b68f"))
		m._ui_rect(cell,Color("a98b5c") if selected==i else Color("d4c29e"))
		m._ui_rect(cell.grow(-1),Color("fff0ce") if selected==i else Color("f3e6c9"))
		m._ui_rect(Rect2(cell.position+Vector2(2,2),Vector2(70,1)),Color("fff8e4"))
		if region==0:
			m._ui_fish(i,Rect2(cell.position+Vector2(5,6),Vector2(64,maxf(20,cell_h-38))))
			m._text(m.FISH_NAME[i],Vector2(cell.get_center().x,cell.end.y-21),12,Color("382619"),true,68)
		else:
			m._text("?",cell.get_center(),16,Color("aa9d7f"),true,60)
			m._text("어종 미정",Vector2(cell.get_center().x,cell.end.y-21),12,Color("513b29"),true,68)
		m._text("★ 준비 중",Vector2(cell.get_center().x,cell.end.y-6),10,Color("68533d"),true,68)
		rects["fish:%d"%i]=cell
	var reward:=Rect2(17,bottom-93,236,38)
	m._ui_rect(reward,Color("e7d8b6"));m._ui_rect(Rect2(reward.position,Vector2(236,1)),Color("baa57e"))
	if tab==0:
		if not licenses.has(region): licenses[region]=load("res://art/rewards67/license_%d.png"%region)
		m._ui_texture_rect(licenses[region],Rect2(reward.position+Vector2(3,3),Vector2(48,32)),false)
		m._text("낚시 자격증 %d급"%(region+1),reward.position+Vector2(56,14),11,Color("382619"),false,175)
		m._text("다음 낚시터 입장 라이선스" if region<5 else "최종 지역 자격증 · 용도 준비 중",reward.position+Vector2(56,29),9,Color("513b29"),false,175)
	else:
		m._ui_texture_rect(m.V.tool_icons.scale,Rect2(reward.position+Vector2(8,7),Vector2(24,24)),false)
		var amount: String="%s 비늘" % _amount(roundi(SPOTS.PRICES[region+1]*0.2)) if region<5 else "보상 준비 중"
		m._text(amount,reward.position+Vector2(40,16),14,Color("382619"),false,185)
		m._text("서브 번들 완료 보상" if region<5 else "최종 지역 보상은 추후 공개",reward.position+Vector2(40,30),10,Color("513b29"),false,185)

	button(m,"register","번들 준비 중",Rect2(17,bottom-48,154,29))
	button(m,"dex","도감",Rect2(177,bottom-48,76,29))
	m._text("번들 공개 전 · 기증은 아직 불가해요",Vector2(135,bottom-7),10,Color("68533d"),true,236)
	if selected>=0:
		var detail:=Rect2(22,y+12,226,108)
		m._ui_style_box(m.sb_panel,detail)
		m._text(m.FISH_NAME[selected] if region==0 else "어종 미정",detail.position+Vector2(113,27),13,Color("513b29"),true,190)
		m._text("기증 조건을 준비하고 있어요",detail.position+Vector2(113,49),9,Color("68533d"),true,198)
		button(m,"detail_close","확인",Rect2(detail.position+Vector2(56,66),Vector2(114,27)))
func press(m,p: Vector2) -> void:
	m.play("ui")
	if selected>=0:
		if rects.get("detail_close",Rect2()).has_point(p): selected=-1
		return
	if rects.get("dex",Rect2()).has_point(p): legacy_dex=true;return
	if rects.get("close",Rect2()).has_point(p): m.V.shop="";return
	if rects.get("prev",Rect2()).has_point(p): region=maxi(0,region-1);return
	if rects.get("next",Rect2()).has_point(p): region=mini(5,region+1);return
	if rects.get("main",Rect2()).has_point(p): tab=0;return
	if rects.get("sub",Rect2()).has_point(p): tab=1;return
	for n in 6:
		if rects.get("region:%d"%n,Rect2()).has_point(p): region=n;return
		if rects.get("fish:%d"%n,Rect2()).has_point(p): selected=n;return
	if rects.get("register",Rect2()).has_point(p): selected=0

func _amount(value: int) -> String:
	var raw:=str(value);var result:=""
	for i in raw.length():
		if i>0 and (raw.length()-i)%3==0: result+=","
		result+=raw[i]
	return result
