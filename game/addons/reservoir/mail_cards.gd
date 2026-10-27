extends RefCounted
const Layout=preload("res://addons/reservoir/text_layout.gd")
const Reader=preload("res://addons/reservoir/topic_reader.gd")
static func cards(mail,letter: Dictionary) -> Array:
	if letter.id=="0.87":
		return [
			{"name":"탐험 결과","icon":"explore","body":["성공·실패를 작은 결과 카드로 표시해요.","보상과 처치 기록을 바로 확인해요."]},
			{"name":"낚시터 진행 표시","icon":"tackle","body":["탐험 단계와 진행률을 한 줄로 표시해요.","낚시하면서 탐험 상황을 확인해요."]},
			{"name":"병사 배치","icon":"soldier","body":["위쪽 병사 카드에서 바로 해제해요.","결과 확인 후 병사 배치로 이동해요."]},
			{"name":"전투 피해 표시","icon":"attack","body":["역할 아이콘과 색으로 피해를 구분해요.","회복·보호막은 별도로 표시해요."]}]
	return mail.sections(letter)
static func icon(m,key: String,box: Rect2) -> void:
	if key=="explore": m._ui_texture_rect(m.expedition.textures.explore,box)
	elif key=="soldier": m.expedition.sprite(m,0,box)
	elif key=="attack": m.expedition.symbol(m,"attack",box)
	else:
		var texture: Texture2D=m.icons.rod if key=="tackle" else (m.fish_tex[1] if key=="fish" else m.V.tex.get(key,preload("res://art/guide64/mail.png")))
		var size: Vector2=texture.get_size();size*=minf(box.size.x/size.x,box.size.y/size.y)
		m._ui_texture_rect(texture,Rect2(box.get_center()-size/2,size))
static func draw(mail,m,r: Rect2) -> void:
	var letter: Dictionary={}
	for item in mail.letters:
		if item.id==mail.detail: letter=item;break
	if letter.is_empty(): return
	m._ui_style_box(m.hud_reference_style,Rect2(18,r.position.y+5,234,31))
	m._ui_texture_rect(preload("res://art/guide64/mail.png"),Rect2(27,r.position.y+10,22,22))
	m._text("업데이트 우편",Vector2(56,r.position.y+27),12,Color("fff0d1"),false,159)
	m._ui_texture(m.icons.close,Vector2(225,r.position.y+10));mail.rects.close=Rect2(222,r.position.y+7,28,29)
	m._text("v"+letter.id,Vector2(27,r.position.y+56),11,Color("247e80"),false,130)
	m._text("읽음",Vector2(237,r.position.y+55),8,Color("847052"),true,29)
	var title: Array=Layout.wrap(m,letter.title,11,216)
	for i in mini(2,title.size()): m._text(title[i],Vector2(27,r.position.y+78+i*15),11,Color("382619"),false,216)
	var gift: bool=letter.id=="0.78"
	var footer: float=r.end.y-(85 if gift else 47)
	if mail.full_text:
		m._text("전체 업데이트 내용",Vector2(27,r.position.y+115),9,Color("247e80"),false,216)
		mail.rects.reader=Reader.draw(m,letter.body,mail.detail_page,r.position.y+145,footer-38)
	else:
		if title.size()==1: m._text("이번 업데이트의 주요 변경 사항",Vector2(27,r.position.y+95),8,Color("847052"),false,216)
		var items: Array=cards(mail,letter)
		var count: int=3 if gift or items.size()>4 else 4
		var pages: int=maxi(1,ceili(items.size()/float(count)))
		mail.detail_page=clampi(mail.detail_page,0,pages-1)
		for i in count:
			var index: int=mail.detail_page*count+i
			if index>=items.size(): break
			var item: Dictionary=items[index];var y: float=r.position.y+107+i*65
			m._ui_rect(Rect2(26,y,218,59),Color("e8d7b3"));m._ui_rect(Rect2(26,y,3,59),Color("247e80"))
			icon(m,item.icon,Rect2(34,y+5,22,22))
			m._text(item.name,Vector2(62,y+19),10,Color("382619"),false,174)
			var lines: Array=[]
			for paragraph in item.get("display",item.body): lines.append_array(Layout.wrap(m,str(paragraph),8,198))
			for j in mini(2,lines.size()):
				m._text(lines[j],Vector2(36,y+35+j*14),8,Color("513b29"),false,198)
		if pages==1: m._text("전체 내용은 상세 보기에서 확인해요.",Vector2(27,footer-10),8,Color("847052"),false,216)
		if pages>1:
			# Card navigation uses the same hit targets as the full-text reader.
			mail.rects.reader={"count":pages}
			for direction in ["previous","following"]:
				if (direction=="previous" and mail.detail_page==0) or (direction=="following" and mail.detail_page==pages-1): continue
				var b:=Rect2(32 if direction=="previous" else 206,footer-37,32,27)
				m._ui_style_box(m.sb_btn,b);m._text("<" if direction=="previous" else ">",b.get_center()+Vector2(0,4),10,Color("513b29"),true,26);mail.rects.reader[direction]=b
			m._text("%d / %d"%[mail.detail_page+1,pages],Vector2(135,footer-20),9,Color("847052"),true,80)
	if gift:
		var gift_rect:=Rect2(27,r.end.y-45,216,28)
		m._ui_style_box(m.sb_primary,gift_rect)
		var claimed: bool=preload("res://addons/reservoir/testing_gift.gd").ID in m.testing_grants
		m._text("테스트 선물 수령 완료" if claimed else "테스트 선물 받기",gift_rect.get_center()+Vector2(0,4),10,Color("fff0d1"),true,206);mail.rects.gift=gift_rect
	var back:=Rect2(27,footer,87,30);var toggle:=Rect2(156,footer,87,30)
	for b in [back,toggle]: m._ui_style_box(m.sb_btn,b)
	m._text("목록으로",back.get_center()+Vector2(0,4),10,Color("513b29"),true,77)
	m._text("< 요약 보기" if mail.full_text else "상세 보기 >",toggle.get_center()+Vector2(0,4),9,Color("513b29"),true,77)
	m._text("상세" if mail.full_text else "요약",Vector2(135,footer+20),8,Color("847052"),true,36)
	mail.rects.back=back;mail.rects.toggle=toggle
