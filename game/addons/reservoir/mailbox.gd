extends RefCounted
const LETTERS: = [
	{"id": "0.57", "title": "우편함과 조작 화면 개선", "summary": "업데이트 우편 · 드랙음 · 주민 표현", "body": ["마을 상단에 업데이트 우편함 추가", "버전별 상세 내용과 NEW 표시", "전체 읽기 및 선택 삭제 지원", "주황색 감기·낚시하러 가기 버튼 제거", "낚시터 이동은 메뉴의 낚시터 이용", "올려준 드랙 녹음으로 감기 소리 교체", "감는 동안 재생하고 손을 떼면 정지", "주민에게 얇은 검은 외곽선 추가", "걷는 동안 얼굴과 눈 모양 일정하게 유지"]}, 
	{"id": "0.56", "title": "배경·주민·강화 밸런스 개선", "summary": "바위 테두리 · 주민 통일 · 강화 비용", "body": ["저수지 바위에 검은 테두리 적용", "타이틀 괴수 머리는 선명하게 표현", "아래로 갈수록 어두워지는 명암 적용", "부채꼴 빛 제거 및 시작 버튼 이동", "모든 연령 주민의 그림체 통일", "걷는 방향과 발 접지 보정", "도로 시작부 및 나무 접지 수정", "강화 비늘 비용 3배, 혼 비용 하향", "단계별 비용 1.2배 증가 유지"]}, 
	{"id": "0.55", "title": "새로운 낚시월드 타이틀", "summary": "폭풍·나룻배·심해 괴수의 등장", "body": ["타이틀 로고 등장과 흔들림 애니메이션", "비·구름·파도·배·물방울 레이어 분리", "작은 번개 두 번, 큰 번개 한 번 연출", "번개에 반응하는 수중 괴수 표현", "게임 시작 시 마을로 진입"]}, 
	{"id": "0.54", "title": "강화 정보와 물고기 표현 개선", "summary": "강화 재료 표시 · 물고기 선명도", "body": ["강화 성공률과 필요·보유 재료 강조", "상점 제목 옆에 서 있던 NPC 제거", "훅 성공 이후 과한 물고기 테두리 정리", "뜰채 진입 시 물고기 크기 변화 보정"]}, 
	{"id": "0.53", "title": "구매 확인과 낚시터 선택", "summary": "구매 확인 · 가방 · 여섯 낚시터 카드", "body": ["아이템 이미지와 구매·취소 확인 창", "구매 완료 알림 애니메이션 추가", "가방 펼침 및 등급별 보유 수량 표시", "고정 범위 줄자로 물고기 길이 표시", "낚시터 선택 화면과 잠금 카드 추가", "마을 이동 버튼을 처음·중간·끝으로 정리"]}
]
var letters: Array = preload("res://addons/reservoir/release_notes.gd").LETTERS + LETTERS
var opened: = false
var read_ids: Array = []
var deleted_ids: Array = []
var checked: Array = []
var deleting: = false
var detail: = ""
var page: = 0
var topic := 0
var detail_page := 0
var full_text := false
const Reader = preload("res://addons/reservoir/topic_reader.gd")
func sections(letter: Dictionary) -> Array:
	# Curated presentation, separate from the complete release archive.
	if letter.id == "0.72":
		return [
			{"name":"강화 오라","icon":"tackle","body":letter.body.slice(0,3),"display":["강화2회마다 낚싯대의 빛이 달라져요.","높은 강화는 입자와 잔광도 화려하게!","최대강화와 성능은 그대로예요."]},
			{"name":"밤의 낚시터","icon":"fish","body":letter.body.slice(3,5),"display":["램프가 캐릭터 주변을 따뜻하게 비춰요.","달빛과 마을 불빛이 더 또렷해졌어요.","굴뚝 연기와 반딧불이를 살펴보세요."]},
			{"name":"조우·포획","icon":"museum","body":letter.body.slice(5),"display":["희귀한 조우는 움직이는 글자로 표시!","물고기는 세로로 흔들리며 올라와요.","물고기와 장비 기록은 그대로 유지돼요."]}]
	if letter.id == "0.71":
		return [
			{"name":"캐릭터","icon":"tackle","body":letter.body.slice(0,3),"display":["표정과 낚시 동작이 새로워졌어요.","장착한 낚싯대의 모습이 달라져요.","의자와 앉은 위치를 정리했어요."]},
			{"name":"고양이·편의","icon":"fish","body":letter.body.slice(3,6),"display":["고양이가 찌를 보고 포획에 반응해요.","어시장의 모든 물고기를 스크롤해요.","긴 한글 설명도 편하게 읽어 보세요."]},
			{"name":"보상·기록","icon":"museum","body":letter.body.slice(6),"display":["저수지 확률과 보상 안내를 개선했어요.","가방과 기증, 장비 기록은 유지돼요."]}]
	if letter.id == "0.70":
		return [
			{"name":"저수지","icon":"fish","body":letter.body.slice(0,1),"display":["큰 달이 뜬 새로운 저수지예요.","낮밤에 따라 물결과 조명이 달라져요."]},
			{"name":"기증·가방","icon":"museum","body":letter.body.slice(1,4),"display":["물고기를 한 마리씩 기증해요.","판매한 물고기는 최근10마리 재구매.","가방은 어종·등급별 목록으로 확인."]},
			{"name":"주인","icon":"tackle","body":letter.body.slice(4),"display":["지역 장비를 모두 장착하면 게이지 표시.","가득 채운 뒤 챔질하면 주인이 등장해요.","계곡 입장은 아직 준비 중이에요."]}]
	if letter.id == "0.69":
		return [
			{"name":"계곡 도감","icon":"fish","body":letter.body.slice(0,2),"display":["계곡 물고기 20종을 등록했어요.","박물관에서 지역별 도감을 확인하세요."]},
			{"name":"기록","icon":"museum","body":letter.body.slice(2,4),"display":["같은 이름도 지역별로 기록해요.","기존 도감과 보관 물고기는 유지돼요."]},
			{"name":"낚시터","icon":"tackle","body":letter.body.slice(4),"display":["메인 번들 자격증을 얻은 뒤 별도 구매.","계곡 입장과 기증은 아직 준비 중이에요."]}]
	if letter.id == "0.68":
		return [
			{"name":"우편","icon":"","body":letter.body.slice(0,3),"display":["목록은 한 줄 설명으로 깔끔하게.","상세는 주제별 그림과 짧은 설명.","새 물고기 인장 봉투를 적용했어요."]},
			{"name":"물고기","icon":"fish","body":letter.body.slice(4,6),"display":["선명함은 유지하고 움직임은 생생하게.","몸 밖으로 퍼지는 오라와 반짝임 강화."]},
			{"name":"소리","icon":"","body":[letter.body[3]],"display":["캐스팅은 짧은 바람 소리로!","드랙과 착수 물소리는 유지했어요."]}]
	if letter.id == "0.67":
		return [
			{"name":"물고기","icon":"fish","body":[letter.body[0],letter.body[1]],"display":["눈과 비늘을 더 선명하게!","몸통은 유지하고 꼬리는 유연하게."]},
			{"name":"우편·가이드","icon":"","body":[letter.body[2]],"display":["필요한 주제를 탭으로 골라요.","그림과 짧은 설명으로 살펴보세요."]},
			{"name":"장비·보상","icon":"tackle","body":letter.body.slice(3),"display":["자격증·미끼 그림 6종씩 추가!","번들에 라이선스와 비늘 보상 표시.","낚싯대 6종을 한 화면에서 확인.","구매가 조정 · 판매가는 구매가 절반.","기증·보상 지급·새 낚시터는 준비 중."]}]
	if letter.id == "0.66":
		return [
			{"name":"박물관","icon":"museum","body":letter.body.slice(0,3),"display":["번들 화면을 둘러볼 수 있어요.","안내 글씨와 창 크기를 정리했어요.","기증은 준비 중 · 기존 도감은 유지."]},
			{"name":"물고기 연출","icon":"fish","body":[letter.body[3],letter.body[6]],"display":["몸통 변형과 오라 겹침을 줄였어요.","챔질 성공은 글자로 가볍게 표시!"]},
			{"name":"소리","icon":"","body":letter.body.slice(4,6),"display":["마을에 갈매기와 뱃고동 추가.","버튼 소리는 낚시 물소리와 분리."]}]
	var groups := [{"name":"콘텐츠","icon":"museum","body":[]},{"name":"연출","icon":"fish","body":[]},{"name":"소리·설정","icon":"","body":[]}]
	for line in letter.body:
		var group := 0
		if ["소리","사운드","음악","클릭음","진동","설정","저장","초기화","드랙","천둥","배경음"].any(func(word): return word in line): group=2
		elif ["연출","물고기","오라","테두리","선명","챔질","몸짓","캐릭터","주민","타이틀","게이지","줄자"].any(func(word): return word in line): group=1
		groups[group].body.append(line)
	return groups.filter(func(group): return not group.body.is_empty())
var button: = Rect2()
var rects: = {}
func visible_letters() -> Array:
	return letters.filter( func(l): return l.id not in deleted_ids)
func unread() -> int:
	return visible_letters().filter( func(l): return l.id not in read_ids).size()
func mark(m, id: String) -> void :
	if id not in read_ids: read_ids.append(id);m._save_game()
func envelope(m, r: Rect2, col: Color) -> void :
	m._ui_texture_rect(preload("res://art/guide64/mail.png"),Rect2(r.get_center()-Vector2(12,12),Vector2(24,24)))
func draw_button(m) -> void :
	button = Rect2(51, m.get_viewport_rect().size.y-m.bot_pad-99, 38, 38)
	m._ui_style_box(m.sb_btn,button)
	m._ui_texture_rect(preload("res://art/guide64/mail.png"),Rect2(button.position+Vector2(6,3),Vector2(26,26)))
	m._text("우편",button.position+Vector2(19,32),7,Color("513b29"),true,32)
	if unread() > 0:
		m._ui_rect(Rect2(button.position+Vector2(29,3),Vector2(6,6)),Color("a43b30"))
		m._ui_rect(Rect2(button.position+Vector2(30,4),Vector2(2,2)),Color("ffb999"))
func draw(m, h: float) -> void :
	var height := minf(440.0 if detail != "" else 364.0,h-88)
	var r := Rect2(13,maxf(8,(h-height)/2),244,height)
	m.text_items = m.text_items.filter( func(it): return it[1].y < m.top_y + 35)
	m._ui_rect(Rect2( - m.ox, 0, m.VW + 2 * m.ox, h), Color(0.015, 0.025, 0.04, 0.86))
	m.expedition.panel(m,r)
	if detail == "": preload("res://addons/reservoir/ui_theme.gd").title(m, r, "업데이트 우편함")
	var close: = Rect2(r.end.x - 31, r.position.y + 9, 22, 23)
	m._ui_texture(m.icons.close, close.position)
	rects = {"close": close.grow(3), "rows": []}
	if detail != "":
		preload("res://addons/reservoir/mail_cards.gd").draw(self,m,r)
		return
	var letters: = visible_letters()
	var pages: = maxi(1, ceili(letters.size() / 4.0));page = clampi(page, 0, pages - 1)
	m._text("삭제할 우편을 선택하세요" if deleting else "안 읽은 우편 %d개" % unread(), Vector2(135, r.position.y + 56), 10, Color("513b29"), true, 218)
	for i in 4:
		var index: = page * 4 + i
		if index >= letters.size(): break
		var letter: Dictionary = letters[index]
		var row: = Rect2(r.position.x + 10, r.position.y + 67 + i * 55, 224, 50)
		m._ui_style_box(m.sb_chip, row)
		if deleting:
			var check: = Rect2(row.position + Vector2(6, 8), Vector2(13, 13));m._ui_rect(check, Color("6e6048"));m._ui_rect(check.grow(-2), Color("faf0d8"))
			if letter.id in checked: m._text("✓", check.get_center() + Vector2(0, 4), 10, Color("3c654a"), true, 13)
		else: envelope(m, Rect2(row.position + Vector2(6, 9), Vector2(22, 16)), Color("e7d29c"))
		var x: float = row.position.x + 35
		m._text("v" + letter.id, Vector2(x, row.position.y + 15), 10, Color("513b29"), false, 60)
		if letter.id not in read_ids:
			m._text("NEW", Vector2(row.end.x - 28, row.position.y + 15), 9, Color(0.85, 0.32, 0.12, 0.7 + 0.3 * sin(m.ui_clock * 5)), true, 46)
		m._text(m._ui_wrap(letter.title,9,174,1),Vector2(x,row.position.y+35),9,Color("513b29"),false,174)
		rects.rows.append([row, letter.id])
	if letters.is_empty(): m._text("우편함이 비었어요", Vector2(135, r.position.y + 150), 12, Color("796b58"), true, 218)
	m._text("%d / %d" % [page + 1, pages], Vector2(135, r.end.y - 64), 9, Color("513b29"), true, 80)
	rects.prev = Rect2(35, r.end.y - 80, 28, 25);rects.next = Rect2(207, r.end.y - 80, 28, 25)
	for key in ["prev", "next"]:
		m._ui_style_box(m.sb_chip, rects[key]);m._text("<" if key == "prev" else ">", rects[key].get_center() + Vector2(0, 4), 10, Color("513b29"), true, 24)
	rects.read = Rect2(25, r.end.y - 42, 105, 28);rects.delete = Rect2(140, r.end.y - 42, 105, 28)
	for key in ["read", "delete"]:
		m._ui_style_box(m.sb_btn, rects[key])
		var text: String = ("취소" if deleting else "전체 읽기") if key == "read" else ("선택 삭제 %d" % checked.size() if deleting else "삭제")
		m._text(text, rects[key].get_center() + Vector2(0, 4), 10, Color("513b29"), true, 99)
func press(m, p: Vector2) -> void :
	m.play("ui")
	if rects.get("close", Rect2()).has_point(p): opened = false;detail = "";full_text=false;deleting = false;checked.clear();return
	if detail != "":
		if detail=="0.78" and rects.get("gift",Rect2()).has_point(p):
			if preload("res://addons/reservoir/testing_gift.gd").claim(m): m.show_toast("테스트 선물을 받았어요!",Color("91e8dc"))
			return
		if rects.get("back", Rect2()).has_point(p): detail = "";topic=0;detail_page=0;full_text=false;return
		if rects.get("toggle",Rect2()).has_point(p): full_text=not full_text;detail_page=0;return
		var reader: Dictionary = rects.get("reader",{})
		if reader.get("previous",Rect2()).has_point(p): detail_page=maxi(0,detail_page-1)
		if reader.get("following",Rect2()).has_point(p): detail_page=mini(reader.count-1,detail_page+1)
		return
	for row in rects.get("rows", []):
		if not row[0].has_point(p): continue
		if deleting:
			if row[1] in checked: checked.erase(row[1])
			else: checked.append(row[1])
		else: detail = row[1];topic=0;detail_page=0;full_text=false;mark(m, detail)
		return
	if rects.get("prev", Rect2()).has_point(p): page = maxi(0, page - 1)
	if rects.get("next", Rect2()).has_point(p): page += 1
	if rects.get("read", Rect2()).has_point(p):
		if deleting: deleting = false;checked.clear()
		else:
			for letter in visible_letters():
				if letter.id not in read_ids: read_ids.append(letter.id)
			m._save_game()
	if rects.get("delete", Rect2()).has_point(p):
		if not deleting: deleting = true;checked.clear()
		elif not checked.is_empty():
			for id in checked:
				if id not in deleted_ids: deleted_ids.append(id)
			checked.clear();deleting = false;m._save_game()
