extends RefCounted
# Existing museum panel/art, now connected to specimen donations.
const SPOTS = preload("res://addons/reservoir/spot_selection.gd")
const CATALOG = preload("res://addons/reservoir/regional_catalog.gd")
var region := 0
var tab := 0
var selected := -1
var page := 0
var rects := {}
var legacy_dex := false
var licenses := {}
func button(m, key: String, label: String, r: Rect2, active: bool=false) -> void:
	m._ui_style_box(m.sb_primary if active else m.sb_btn,r)
	m._text(label,r.get_center()+Vector2(0,4),11,Color("fff0d1") if active else Color("382619"),true,r.size.x-8)
	rects[key]=r
func species_id(target: Dictionary) -> int:
	var key: String=target.get("species","")
	return int(key.get_slice(":",0).trim_prefix("r"))*20+int(key.get_slice(":",1).trim_prefix("s"))
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
	m._ui_rect(Rect2(map.position+Vector2(0,2),map.size),Color("8b7650"));m._ui_rect(map,Color("275665"))
	for x in range(32,240,8): m._ui_rect(Rect2(x,y+28,3,2),Color("e9d9b3"))
	var start:=clampi(region-1,0,3)
	for j in 3:
		var n:=start+j
		var tile:=Rect2(25+j*79,y+7,62,38)
		m._ui_rect(Rect2(tile.position+Vector2(2,3),tile.size),Color(0,0,0,0.3))
		m._ui_rect(tile.grow(2),Color("e5c671") if n==region else Color("587782"))
		var tex: Texture2D=m.spots.images[n];var ts:=tex.get_size()
		m._ui_texture_rect_region(tex,tile,Rect2(0,0,ts.x,ts.x*38.0/62.0),Color.WHITE if n==region else Color(0.55,0.62,0.63))
		m._text(str(n+1),Vector2(tile.position.x+7,tile.end.y-3),9,Color("fff0d1"),true,12,true)
		rects["region:%d"%n]=tile.grow(3)
		if n==region: m._ui_rect(Rect2(tile.position.x+18,tile.end.y+4,26,2),Color("e5c671"))
	y=map.end.y+6
	button(m,"prev","<",Rect2(17,y,30,24));button(m,"next",">",Rect2(223,y,30,24))
	m._text(SPOTS.NAMES[region],Vector2(135,y+15),12,Color("382619"),true,170)
	y+=30
	for i in 3: button(m,["main","sub","owner"][i],["필수 번들","서브 번들","주인 번들"][i],Rect2(17+i*80,y,76,26),tab==i)
	y+=36
	m._text(["다음 낚시터 라이선스","비늘과 물고기의 혼","낚시터 주인에게 도전"][tab],Vector2(22,y+4),11,Color("382619"),false,226)
	y+=12
	var bottom: float=r.end.y-9
	var grid_end: float=bottom-103
	var cell_h: float=floorf((grid_end-y-5)/2.0)
	var targets: Array=m.progression.bundle_targets(region,tab)
	var counts: Array=m.progression.bundle_counts(region,tab)
	var done: bool=m.progression.bundle_done(region,tab)
	var total:=0
	for count in counts: total+=int(count)
	for i in (1 if tab==2 else 6):
		var cell:=Rect2(98 if tab==2 else 19+(i%3)*79,y+floori(i/3.0)*(cell_h+5),74,cell_h)
		m._ui_rect(Rect2(cell.position+Vector2(0,2),cell.size),Color("c6b68f"));m._ui_rect(cell,Color("f3e6c9"))
		if i<targets.size():
			var sp:=species_id(targets[i])
			m._ui_fish(sp,Rect2(cell.position+Vector2(5,5),Vector2(64,maxf(20,cell_h-38))))
			m._text(m._ui_wrap(m.FISH_NAME[sp],10,68,2),Vector2(cell.get_center().x,cell.end.y-26),10,Color("382619"),true,68)
			m._text("기증 완료" if int(counts[i])>0 else "★%d · 미기증"%(star(sp)+1),Vector2(cell.get_center().x,cell.end.y-6),9,Color("456a50") if int(counts[i])>0 else Color("68533d"),true,68)
		else:
			m._text("?",cell.get_center(),16,Color("aa9d7f"),true,60)
			m._text("준비 중",Vector2(cell.get_center().x,cell.end.y-6),10,Color("68533d"),true,68)
		rects["fish:%d"%i]=cell
	var reward:=Rect2(17,bottom-93,236,38)
	m._ui_rect(reward,Color("e7d8b6"))
	if tab==0:
		if not licenses.has(region): licenses[region]=load("res://art/rewards67/license_%d.png"%region)
		m._ui_texture_rect(licenses[region],Rect2(reward.position+Vector2(3,3),Vector2(48,32)),false)
		m._text("낚시 자격증 %d급"%(region+1),reward.position+Vector2(56,14),11,Color("382619"),false,175)
		m._text("다음 낚시터 구매 자격",reward.position+Vector2(56,29),8,Color("513b29"),false,175)
	else:
		m._ui_texture_rect(m.V.tool_icons.scale,Rect2(reward.position+Vector2(8,7),Vector2(24,24)),false)
		var caption: String="보상 준비 중"
		if region<2: caption="판매가 합계 120%% + 혼 %d"%m.progression.SOUL_REWARD[region] if tab==1 else "판매가 150% + 진주 2개"
		m._text(caption,reward.position+Vector2(39,16),10,Color("382619"),false,192)
		m._text("완료 시 자동 지급" if tab==2 else "제출한 실제 개체 판매가 기준",reward.position+Vector2(39,30),9,Color("513b29"),false,192)
	button(m,"register","완료" if done else ("기증 %d / %d"%[total,targets.size()] if not targets.is_empty() else "번들 준비 중"),Rect2(17,bottom-48,154,29),done)
	button(m,"dex","도감",Rect2(177,bottom-48,76,29))
	m._text("물고기를 눌러 한 마리씩 기증 · 등급 무관",Vector2(135,bottom-7),9,Color("68533d"),true,236)
	if selected>=0: detail(m,h,targets,counts)
func star(sp: int) -> int:
	for i in 5:
		if sp%20 in CATALOG.BY_STAR[i]: return i
	return 0
func detail(m,h: float,targets: Array,counts: Array) -> void:
	m.text_items=m.text_items.filter(func(it): return it[1].y<m.top_y+20)
	m._ui_rect(Rect2(-m.ox,0,270+2*m.ox,h),Color(0.025,0.04,0.07,0.82))
	var r:=Rect2(18,roundf(h/2)-145,234,290)
	m._ui_style_box(m.sb_panel,r)
	if selected>=targets.size():
		m._text("조건 준비 중",Vector2(135,r.position.y+35),12,Color("513b29"),true,208)
	else:
		var sp:=species_id(targets[selected])
		m._text(m.FISH_NAME[sp],Vector2(135,r.position.y+27),13,Color("513b29"),true,208)
		m._text("기증 완료" if int(counts[selected])>0 else "등급 무관 · 선택한 물고기는 소모돼요",Vector2(135,r.position.y+48),9,Color("68533d"),true,214)
		var matches: Array=m.progression.matching_bag(m,region,tab,selected)
		page=clampi(page,0,maxi(0,ceili(matches.size()/3.0)-1))
		if matches.is_empty() and int(counts[selected])==0: m._text("가방에 해당 물고기가 없어요",Vector2(135,r.position.y+110),10,Color("68533d"),true,214)
		for row in 3:
			var at:=page*3+row
			if at>=matches.size(): break
			var index: int=int(matches[at]);var fish: Dictionary=m.bag[index]
			var yy: float=r.position.y+65+row*45
			m._ui_fish(sp,Rect2(28,yy,39,26))
			m._text("%s · %.1fcm"%[m.GRADE_N[int(fish.grade)],float(fish.len)],Vector2(70,yy+12),9,Color("513b29"),false,104)
			m._text("판매가 %d"%int(fish.price),Vector2(70,yy+27),9,Color("68533d"),false,104)
			button(m,"donate:%d"%index,"기증",Rect2(183,yy,54,31))
		if matches.size()>3:
			button(m,"page_prev","<",Rect2(65,r.end.y-79,30,24));button(m,"page_next",">",Rect2(175,r.end.y-79,30,24))
			m._text("%d / %d"%[page+1,ceili(matches.size()/3.0)],Vector2(135,r.end.y-63),9,Color("68533d"),true,65)
	button(m,"detail_close","닫기",Rect2(83,r.end.y-40,104,27))
func press(m,p: Vector2) -> void:
	m.play("ui")
	if selected>=0:
		if rects.get("detail_close",Rect2()).has_point(p): selected=-1;return
		if rects.get("page_prev",Rect2()).has_point(p): page=maxi(0,page-1);return
		if rects.get("page_next",Rect2()).has_point(p): page+=1;return
		for key in rects:
			if str(key).begins_with("donate:") and rects[key].has_point(p):
				if m.progression.donate_bundle(m,region,tab,int(str(key).get_slice(":",1)),selected): selected=-1;page=0
				return
		return
	if rects.get("dex",Rect2()).has_point(p): legacy_dex=true;return
	if rects.get("close",Rect2()).has_point(p): m.V.shop="";return
	if rects.get("prev",Rect2()).has_point(p): region=maxi(0,region-1);return
	if rects.get("next",Rect2()).has_point(p): region=mini(5,region+1);return
	for i in 3:
		if rects.get(["main","sub","owner"][i],Rect2()).has_point(p): tab=i;page=0;return
	for n in 6:
		if rects.get("region:%d"%n,Rect2()).has_point(p): region=n;return
		if rects.get("fish:%d"%n,Rect2()).has_point(p): selected=n;page=0;return
	if rects.get("register",Rect2()).has_point(p): selected=0;page=0

func _amount(value: int) -> String:
	var raw:=str(value);var result:=""
	for i in raw.length():
		if i>0 and (raw.length()-i)%3==0: result+="," 
		result+=raw[i]
	return result
