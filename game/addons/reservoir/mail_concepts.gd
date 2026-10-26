extends RefCounted
# Design alternatives only, enabled with --mail-a / --mail-b. Uses existing UI assets.
static func draw(m,h: float,kind: int) -> void:
	m.text_items.clear();m.ui_commands.clear()
	m._ui_rect(Rect2(-m.ox,0,270+2*m.ox,h),Color("18393e"))
	var r:=Rect2(12,maxf(m.top_y+16,(h-440)/2),246,440)
	m._ui_style_box(m.sb_panel,r)
	m._ui_style_box(m.hud_reference_style,Rect2(r.position+Vector2(5,5),Vector2(236,34)))
	m._text("업데이트 우편함",Vector2(128,r.position.y+27),14,Color("fff0d1"),true,205)
	m._ui_texture(m.icons.close,Vector2(r.end.x-30,r.position.y+10))
	var y: float=r.position.y+53
	m._text("v0.66",Vector2(29,y+4),16,Color("376556"),false,80)
	m._text("읽음",Vector2(231,y+4),10,Color("68533d"),true,35)
	m._text("박물관 새 단장과 물가의 소리",Vector2(135,y+26),12,Color("382619"),true,220)
	m._ui_rect(Rect2(27,y+38,216,1),Color("c3ad83"))
	var titles:=["박물관", "물고기 연출", "소리"]
	var bodies:=[ ["번들 화면을 둘러볼 수 있어요.","기증 기능은 준비 중이에요.","기존 도감은 그대로 볼 수 있어요."], ["물고기 몸통을 더 선명하게!","착수 챔질은 글자만 표시해요."], ["마을에 갈매기와 뱃고동 추가","버튼 클릭음도 새로 바뀌었어요."] ]
	y+=49
	if kind==0:
		for i in 3:
			var card:=Rect2(25,y+i*83,220,77)
			m._ui_rect(Rect2(card.position+Vector2(0,2),card.size),Color("d5c29e"))
			m._ui_rect(card,Color("f3e6c9"))
			m._ui_rect(Rect2(card.position,Vector2(3,77)),Color("4c7d6b"))
			m._text(titles[i],card.position+Vector2(10,17),12,Color("376556"),false,194)
			for j in bodies[i].size():m._text(bodies[i][j],card.position+Vector2(10,34+j*16),10,Color("382619"),false,200)
	else:
		for i in 3:
			var tr:=Rect2(25+i*74,y,71,28)
			m._ui_style_box(m.sb_primary if i==0 else m.sb_btn,tr)
			m._text(titles[i],tr.get_center()+Vector2(0,4),10,Color("fff0d1") if i==0 else Color("382619"),true,63)
		y+=41
		m._ui_texture_rect(m.V.tex.museum,Rect2(105,y+3,60,60),false)
		m._text("박물관에 새로운 수집 목표",Vector2(135,y+88),13,Color("382619"),true,210)
		for j in bodies[0].size():m._text(bodies[0][j],Vector2(135,y+115+j*24),11,Color("513b29"),true,210)
		m._text("1 / 3",Vector2(135,y+211),10,Color("68533d"),true,80)
	var back:=Rect2(25,r.end.y-42,220,28)
	m._ui_style_box(m.sb_btn,back);m._text("목록으로",back.get_center()+Vector2(0,4),12,Color("382619"),true,206)
