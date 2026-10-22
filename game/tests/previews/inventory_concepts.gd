extends RefCounted
# Proposal renderer only. Does not replace inventory.gd, mutate fish, or write saves.
var regions: Array=[]
static func groups(items: Array) -> Array:
	var result: Array=[]
	var lookup: Dictionary={}
	for i in items.size():
		var f: Dictionary=items[i]
		var key: String="%d:%d"%[int(f.sp),int(f.grade)]
		if not lookup.has(key):
			lookup[key]=result.size()
			result.append({"sp":int(f.sp),"grade":int(f.grade),"indices":[],"min_weight":float(f.w),"max_weight":float(f.w),"total_weight":0.0})
		var g: Dictionary=result[int(lookup[key])]
		g.indices.append(i);g.min_weight=minf(g.min_weight,float(f.w));g.max_weight=maxf(g.max_weight,float(f.w));g.total_weight+=float(f.w)
	return result
func weight(m, g: Dictionary) -> String:
	if is_equal_approx(g.min_weight,g.max_weight): return m._wtxt(g.min_weight)
	return "%s~%s"%[m._wtxt(g.min_weight),m._wtxt(g.max_weight)]
func badge(m, g: Dictionary, rect: Rect2) -> void:
	m._ui_style_box(m.sb_chip,rect)
	m._ui_rect(Rect2(rect.position+Vector2(3,3),Vector2(3,rect.size.y-6)),m.GRADE_C[int(g.grade)])
	m._text(m.GRADE_N[int(g.grade)],rect.get_center()+Vector2(3,4),9,Color("513b29"),true,rect.size.x-8)
func draw(m, h: float, variant: String) -> void:
	m.text_items=[];m.ui_commands=[];regions=[]
	m._ui_rect(Rect2(-m.ox,0,270+2*m.ox,h),Color("1c3445"))
	var panel_height: float=minf(444,h-24)
	var r:=Rect2(10,(h-panel_height)/2,250,panel_height)
	m._ui_style_box(m.sb_panel,r)
	preload("res://addons/reservoir/ui_theme.gd").title(m,r,"가방")
	m._ui_texture(m.icons.close,r.position+Vector2(r.size.x-31,9))
	for i in 3:
		var tab:=Rect2(r.position+Vector2(10+i*78,45),Vector2(74,25))
		m._ui_style_box(m.sb_btn if i==0 else m.sb_chip,tab)
		m._text(["물고기","인벤토리","장비"][i],tab.get_center()+Vector2(0,4),10,Color("513b29"),true,70)
	var entries:=groups(m.bag)
	m._text("보유 %d마리 · %d묶음"%[m.bag.size(),entries.size()],r.position+Vector2(13,87),10,Color("513b29"),false,218)
	var y: float=r.position.y+97
	var footer: float=r.end.y-42
	if variant=="A":
		var row_h: float=floorf((footer-y-5)/6)
		for i in mini(6,entries.size()):
			var g: Dictionary=entries[i]
			var row:=Rect2(r.position.x+10,y+i*row_h,r.size.x-20,row_h-4)
			m._ui_style_box(m.sb_chip,row)
			m._ui_fish(int(g.sp),Rect2(row.position+Vector2(4,5),Vector2(40,row.size.y-10)))
			var name_pos: Vector2=row.position+Vector2(50,16)
			m._text(m.FISH_NAME[int(g.sp)],name_pos,11,Color("382619"),false,172)
			badge(m,g,Rect2(row.position+Vector2(50,23),Vector2(45,18)))
			m._text("%d마리"%g.indices.size(),row.position+Vector2(101,36),9,Color("513b29"),false,38)
			m._text(weight(m,g),Vector2(row.end.x-39,row.position.y+36),9,Color("7c6448"),true,72)
			regions.append({"rect":row,"name_y":name_pos.y,"weight_y":row.position.y+36,"group":g})
	else:
		var card_h: float=floorf((footer-y-5)/3)
		for i in mini(6,entries.size()):
			var g: Dictionary=entries[i]
			var card:=Rect2(r.position.x+10+(i%2)*117,y+floori(i/2.0)*card_h,113,card_h-5)
			m._ui_style_box(m.sb_chip,card)
			m._ui_fish(int(g.sp),Rect2(card.position+Vector2(20,4),Vector2(73,27)))
			m._text(m.FISH_NAME[int(g.sp)],Vector2(card.get_center().x,card.position.y+43),10,Color("382619"),true,107)
			badge(m,g,Rect2(card.position+Vector2(6,49),Vector2(49,18)))
			m._text("×%d"%g.indices.size(),Vector2(card.end.x-22,card.position.y+62),10,Color("513b29"),true,32)
			m._text(weight(m,g),Vector2(card.get_center().x,card.end.y-7),9,Color("7c6448"),true,103)
			regions.append({"rect":card,"name_y":card.position.y+43,"weight_y":card.end.y-7,"group":g})
	m._text("%s / %s"%[m._wtxt(m.bag_weight()),m._wtxt(m.bag_cap())],Vector2(135,r.end.y-27),10,Color("513b29"),true,226)
	m._text("물고기를 눌러 개체를 선택하세요",Vector2(135,r.end.y-11),9,Color("7c6448"),true,228)
