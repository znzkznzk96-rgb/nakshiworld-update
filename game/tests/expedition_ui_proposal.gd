extends "res://addons/expedition/view.gd"
# Review-only render. Production view never loads this script.
var proposal: String=""
func draw(m,h: float) -> void:
	if proposal=="compact":
		compact(m)
		return
	if proposal not in ["success","failure"]:
		super.draw(m,h);return
	var win: bool=proposal=="success"
	var y: float=maxf(m.top_y+76,(h-292)/2)
	m._ui_rect(Rect2(0,m.top_y+66,270,h-m.top_y-66),Color(0.04,.06,.07,.65))
	m.text_items=m.text_items.filter(func(it): return it[1].y<m.top_y+65)
	panel(m,Rect2(16,y,238,292))
	m._ui_style_box(m.hud_reference_style,Rect2(21,y+5,228,31))
	m._text("탐험 성공" if win else "탐험 실패",Vector2(135,y+26),16,Color("ffe4a2") if win else Color("ffc3a2"),true,214)
	m._text("1-3 · 반짝이는 세면대",Vector2(135,y+53),10,Color("6c553b"),true,216)
	room(m,Rect2(26,y+65,218,75),2)
	for i in 3: sprite(m,int(data.battle.fighters[i].id),Rect2(34+i*65,y+77,64,61),0,1.0 if win else .72)
	m._text("첫 돌파! 길이 열렸어요" if win else "마지막 적에게 막혔어요",Vector2(135,y+160),11,Color("8c6421") if win else Color("8c4935"),true,216)
	m._ui_rect(Rect2(31,y+171,208,54),Color("e8d4a8"))
	m._text("획득 보상" if win else "탐험 기록",Vector2(135,y+185),9,Color("725636"),true,196)
	m._text("비늘 78    어혼 주머니 2개" if win else "처치한 적 2 / 3",Vector2(135,y+203),11,Color("382619"),true,200)
	m._text("다음 탐사 구역 1-4 개방" if win else "병사를 강화하거나 편성을 바꿔 보세요",Vector2(135,y+218),8,Color("725636"),true,202)
	primary(m,"review_claim",Rect2(30,y+239,210,30),"보상 받기" if win else "병사 배치")
	m._text("보상 수령 후 편성으로" if win else "병사는 사라지지 않아요",Vector2(135,y+282),8,Color("796044"),true,210)
func compact(m) -> void:
	var r:=Rect2(8,m.top_y+70,254,47)
	m._ui_style_box(m.hud_reference_style,r)
	m._text("탐험 1-3",r.position+Vector2(9,15),9,Color("ffe3a0"),false,67)
	m._text("2 / 3 전투",r.position+Vector2(85,15),8,Color("f6e6c1"),false,100)
	m._text("64%",r.position+Vector2(235,15),10,Color("85e3d5"),true,35)
	m._ui_rect(Rect2(r.position+Vector2(8,20),Vector2(238,3)),Color("493a2b"))
	m._ui_rect(Rect2(r.position+Vector2(8,20),Vector2(152,3)),Color("30baa8"))
	for visual in 3:
		var f: Dictionary=data.battle.fighters[2-visual]
		var x: float=r.position.x+10+visual*78
		symbol(m,str(data.catalog.soldiers[int(f.id)].role),Rect2(x,r.position.y+28,12,12))
		health_bar(m,Rect2(x+16,r.position.y+31,49,5),float(f.hp),float(f.max_hp),float(f.hp),Color("75cc78"))
