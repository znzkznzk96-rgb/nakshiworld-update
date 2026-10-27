extends "res://addons/reservoir/mailbox.gd"
var variant: String="A"
const ITEMS=[
 ["탐험 결과",["성공·실패를 작은 결과 카드로 표시해요.","보상과 처치 기록을 바로 확인해요."]],
 ["낚시터 진행 표시",["탐험 단계와 진행률을 한 줄로 표시해요.","낚시하면서 탐험 상황을 확인해요."]],
 ["병사 배치",["위쪽 병사 카드에서 바로 해제해요.","결과 확인 후 병사 배치로 이동해요."]],
 ["전투 피해 표시",["역할 아이콘과 색으로 피해를 구분해요.","회복·보호막은 별도로 표시해요."]]
]
func line(m,s: String,x: float,y: float,size: int=9,col: Color=Color("513b29")) -> void:
	m._text(s,Vector2(x,y),size,col,false,216)
func draw(m,h: float) -> void:
	var r:=Rect2(13,maxf(8,(h-440)/2),244,440)
	m.text_items=m.text_items.filter(func(it):return it[1].y<m.top_y+35)
	m._ui_rect(Rect2(-m.ox,0,270+2*m.ox,h),Color(.015,.025,.04,.86))
	m.expedition.panel(m,r)
	m._ui_style_box(m.hud_reference_style,Rect2(18,r.position.y+5,234,31))
	m._ui_texture_rect(preload("res://art/guide64/mail.png"),Rect2(27,r.position.y+10,22,22))
	line(m,"업데이트 우편",56,r.position.y+27,12,Color("fff0d1"))
	m._ui_texture(m.icons.close,Vector2(225,r.position.y+10))
	line(m,"v0.87",27,r.position.y+56,11,Color("247e80"))
	m._text("읽음",Vector2(237,r.position.y+55),8,Color("847052"),true,29)
	line(m,"탐험 화면과 병사 배치 개선",27,r.position.y+78,11,Color("382619"))
	line(m,"이번 업데이트의 주요 변경 사항",27,r.position.y+95,8,Color("847052"))
	if variant=="A":
		m._ui_rect(Rect2(27,r.position.y+106,216,1),Color("c5ae7b"))
		for i in 4:
			var y: float=r.position.y+126+i*58
			m._ui_rect(Rect2(27,y-8,3,10),Color("247e80"))
			line(m,ITEMS[i][0],37,y,10,Color("382619"))
			for n in 2: line(m,ITEMS[i][1][n],37,y+18+n*14,8)
	else:
		for i in 4:
			var y: float=r.position.y+107+i*65
			m._ui_rect(Rect2(26,y,218,59),Color("e8d7b3"))
			m._ui_rect(Rect2(26,y,3,59),Color("247e80"))
			if i==0: m._ui_texture_rect(m.expedition.textures.explore,Rect2(34,y+5,22,22))
			elif i==1: m._ui_texture_rect(m.icons.rod,Rect2(34,y+5,22,22))
			elif i==2: m.expedition.sprite(m,0,Rect2(32,y+3,26,26))
			else: m.expedition.symbol(m,"attack",Rect2(34,y+5,22,22))
			line(m,ITEMS[i][0],62,y+19,10,Color("382619"))
			for n in 2: line(m,ITEMS[i][1][n],36,y+35+n*14,8)
	line(m,"기존 보유품과 진행 기록은 그대로 유지돼요.",27,r.position.y+379,8,Color("847052"))
	var back:=Rect2(27,r.end.y-47,87,30);var next:=Rect2(156,r.end.y-47,87,30)
	for b in [back,next]: m._ui_style_box(m.sb_btn,b)
	m._text("목록으로",back.get_center()+Vector2(0,4),10,Color("513b29"),true,77)
	m._text("상세 보기 >",next.get_center()+Vector2(0,4),9,Color("513b29"),true,77)
	m._text("요약",Vector2(135,r.end.y-27),8,Color("847052"),true,36)
