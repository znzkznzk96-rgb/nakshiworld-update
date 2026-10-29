extends RefCounted
const TABS := ["낚시", "장비", "어장", "마을", "성장", "어혼·연성", "병사", "탐험"]
const TOPICS := [["기본 조작", "별과 등급", "길이 측정", "주인 낚시"], ["파츠 해금", "장착·판매", "강화"], ["어장 상태", "회복과 확장", "낚시터"], ["배와 방문객", "시설 안내", "우편함"], ["혼", "수족관", "쉬는 동안"], ["어혼 주머니", "어혼 연성", "병사 합성"], ["역할과 배치", "강화와 희귀", "조합의 요령"], ["출발과 진행", "전투 표시", "지원 스킬"]]
var opened := false
var tab := 0
var topic := 0
var page := 0
const Reader = preload("res://addons/reservoir/topic_reader.gd")
var button := Rect2()
var rects := {}
var screen := "home"
var scroll := 0.0
var content_height := 0.0
var viewport := Rect2()
var clip_root: Control
var body_layer: Node2D
var body_text: Array=[]
var body_commands: Array=[]
var textures := {}
var pointer := -2
var start := Vector2.ZERO
var last := Vector2.ZERO
var dragged := false
var native_at := -1000
const HOME_ICONS := ["fishing","equipment","pond","village","growth","alchemy","soldier","exploration"]
const SUBTITLES := ["기본 조작","장착·강화","재고·지역","마을 시설","혼·수익","어혼 조합","병사 편성","탐험 보상"]
const INK := Color("513b29")
const PAPER := Color("fff1d5")
const TEAL := Color("08646b")
var text_boxes: Array=[]

func draw_button(m) -> void:
	button = Rect2(96, m.get_viewport_rect().size.y-m.bot_pad-100, 34, 32)
	m._ui_texture_rect(m.e_slots.slot,button)
	m._ui_texture_rect(preload("res://art/guide64/book.png"),Rect2(button.position+Vector2(5,3),Vector2(24,24)))
	m._text("가이드",button.position+Vector2(17,41),8,Color("fff0d1"),true,42,true)
	m._text("?",button.position+Vector2(19,21),10,Color("fff0d1"),true,12,true)

func content(m) -> Array:
	match "%d:%d" % [tab, topic]:
		"0:0": return ["찌가 완전히 잠길 때 탭해요.", "훅 게이지의 별이 중앙에 오면 탭!", "싸울 때 누르면 감고, 떼면 풀어요.", "돌진 전 웅크리면 미리 손을 떼요.", "점프 중에는 떼고 착수할 때 탭!", "자세한 동작: 설정 → 몸짓 도감"]
		"0:1": return ["별은 어종군, 등급은 희귀도예요.", "등급: 노멀 → 레어 → 유니크", "→ 전설 → 신화", "파츠를 순서대로 장착하면", "더 높은 별의 입질이 열려요.", "미끼와 어장 재고도 영향을 줘요.", "낚시터 왼쪽 메뉴 옆 미끼 버튼에서 보유 미끼를 골라요.", "캐스팅 전에 변경할 수 있고, 소진 시 다른 미끼를 자동 사용하지 않아요.", "빈 바늘도 직접 선택할 수 있어요.", "PERFECT는 등급 상승 기회가 있어요."]
		"0:2": return ["줄자는 어종마다 같은 눈금을 써요.", "같은 어종의 크기를 비교해 보세요.", "동네저수지 최대 길이: %dcm" % m.RESERVOIR_MAX_CM, "어종별 한도는 이보다 작을 수 있어요.", "기존 물고기와 기록은 유지돼요."]
		"1:0": return ["찌 장착: ★2 어종군 입질 해금", "찌 + 바늘: ★3 해금", "찌 + 바늘 + 줄: ★4 해금", "앞 단계 파츠도 장착해야 해요.", "릴은 주인 낚시를 위한 마지막 파츠예요.", "모든 지역 파츠 장착 후 주인 게이지를 채워요.", "별 해금과 희귀 등급은 별개예요."]
		"1:1": return ["가방에서 장착·해제할 수 있어요.", "장착한 장비는 먼저 해제해야 팔려요.", "물고기가 든 보관함은 비워 주세요.", "판매한 낚싯대의 강화는 초기화돼요.", "다시 구매할 수 있지만 강화는 복구 안 돼요."]
		"1:2":
			var e = m.V.enhancement
			return ["대장간에서 비늘과 혼으로 강화해요.", "현재 낚싯대 강화: +%d" % m.forge_lv, "다음 비용: %d 비늘 / %d 혼" % [e.cost(m.forge_lv, m.rod_lv), e.soul_cost(m.rod_lv, m.forge_lv)], "성공률: %.0f%%" % (e.chance(m.rod_lv, m.forge_lv)*100), "낚싯대별 강화 한도가 있어요.", "높은 단계는 실패 시 하락할 수 있어요.", "보호권 사용 여부를 확인하세요."]
		"2:0": return ["현재 재고: %.0f / %d마리" % [m.pond_stock, m.pond_max()], "시간당 회복: %d마리" % m.pond_recovery(), "낚시를 던질 때 재고를 사용해요.", "재고가 적으면 높은 별 입질이 줄어요.", "저수지·계곡은 재고가 비어도", "장착 파츠에 맞는 모든 별이 나와요.", "입질이 느려지므로 회복도 챙겨요."]
		"2:1": return ["어장 확장: 최대 재고가 늘어요.", "회복 강화: 시간당 회복이 늘어요.", "현재 최대: %d마리" % m.pond_max(), "현재 회복: 시간당 %d마리" % m.pond_recovery(), "쉬는 동안에도 재고가 회복돼요.", "회복 계산은 최대 8시간이에요."]
		"2:2": return ["동네저수지와 거꾸로 폭포 계곡을 탐험해요.", "메뉴 → 낚시터에서 이동해요.", "지역 메인 번들을 완료하면 자격증과 다음 지역의 구매 자격을 얻어요.", "새 지역은 상점에서 비늘로 해금해요.", "준비 중인 지역은 입장할 수 없어요.", "지역별 장비와 번들 조건을 확인하세요."]
		"3:0": return ["배 Lv.%d" % (m.boat_lv+1), "한 번에 %d명 / %.0f초마다 입항" % [m.V.capacity(m), m.V.interval(m)], "수족관 수익 배수: ×%.2f" % m.V.multiplier(m), "선착장에서 배를 업그레이드해요.", "방문객 수와 입항 간격이 개선돼요."]
		"3:1": return ["낚시점: 장비·미끼 구매", "대장간: 낚싯대 강화", "어시장: 물고기 판매와 혼 획득", "수족관: 물고기를 넣고 수익 얻기", "어류박물관: 어종·등급 수집 확인", "마을을 좌우로 밀어 둘러보세요."]
		"3:2": return ["마을 아래 메뉴 옆 봉투가 우편함이에요.", "카드 요약을 보고 상세 보기로 원문을 읽어요.", "읽지 않은 우편이 있으면 빨간 점이 보여요.", "읽음·삭제 상태는 저장돼요.", "삭제한 우편이 다시 생기지 않아요."]
		"4:0": return ["어시장에서 손질하면 혼을 얻어요.", "혼은 낚싯대 강화에 사용해요.", "병사 연성용 속성 어혼과는 다른 재료예요.", "물고기의 별과 희귀 등급에 따라", "얻는 혼의 수가 달라져요.", "손질할 물고기와 수족관에 둘 물고기를", "나눠서 선택해 보세요."]
		"4:1": return ["현재 수족관: %d / %d마리" % [m.aqua_count(), m.aqua_capacity()], "예상 수익: 시간당 %.1f 비늘" % (m.aqua_rate()*60), "물고기의 판매가와 마을 배수가", "수익에 반영돼요.", "수족관을 확장하면 더 넣을 수 있어요.", "박물관 기록과 수족관 수익은 별개예요."]
		"4:2": return ["수족관에 물고기를 넣어 두세요.", "다시 접속하면 쉬는 동안의 수익을", "자동으로 받고 안내를 볼 수 있어요.", "오프라인 계산은 최대 8시간이에요.", "현재 예상: 시간당 %.1f 비늘" % (m.aqua_rate()*60), "적은 금액은 정수로 계산돼요."]
		"0:3": return ["해당 지역의 찌·바늘·줄·릴을 모두 장착해야 주인 게이지가 쌓여요.", "포획 성공: 노멀·레어 +1%, 유니크 +2%, 전설 +3%, 신화 +5%예요.", "100%가 되면 다음 GREAT 이상 챔질에서 주인이 등장해요.", "캐스팅이나 입질을 놓친 것으로 게이지가 줄지는 않아요.", "주인을 잡으면 0%, 전투에서 놓치면 70%가 돼요.", "게이지는 지역마다 따로 저장돼요."]
		"5:0": return ["물·전기·독·빛·어둠, 다섯 속성 어혼으로 병사를 만들어요.", "낚시 포획 성공 시 어혼 주머니를 얻을 수 있어요.", "낚시 상점에서 주머니를 구매할 수도 있어요.", "가방 → 인벤토리 → 어혼 주머니 → 열기를 눌러요.", "1개 열기 또는 모두 열기를 선택해요.", "주머니 1개는 무작위 어혼 1개예요. 각 속성 확률은 20%예요.", "탐험의 첫 완료 보상과 일부 보스 보상에서도 주머니를 얻어요."]
		"5:1": return ["메뉴 → 연성 → 어혼 연성에서 만들어요.", "위쪽 어혼 칸을 고르고 아래 보유 어혼을 눌러 두 재료를 정해요.", "같은 속성 두 개도 사용할 수 있어요.", "두 어혼의 조합으로 병사 종류가 정해져요. 재료 순서는 상관없어요.", "처음 만드는 병사는 물음표로 보여요. 발견한 병사는 미리 볼 수 있어요.", "연성 한 번에 어혼 2개를 사용하고 1성 병사 한 마리를 얻어요.", "병사는 최대 60마리까지 보유해요."]
		"5:2": return ["연성 → 병사 합성에서 병사 두 마리를 선택해요.", "같은 별이며 둘 다 +3인 병사끼리 합성할 수 있어요.", "1성 둘은 2성으로, 2성 둘은 3성으로 합성돼요.", "재료 병사는 소모돼요. 확인창에서 후보 병사와 어혼·비늘 비용을 먼저 확인하세요.", "부모의 개체값 두 가지와 새 개체값 중 하나를 선택해요.", "아끼는 병사는 잠가 두면 합성에서 보호돼요.", "탐험 중에는 병사 합성을 할 수 없어요."]
		"6:0": return ["탐험 → 병사 배치에서 3마리를 편성해요.", "위쪽 카드는 왼쪽부터 뒤·중간·앞이에요.", "공격·방어·지원은 역할이고, 앞·중간·뒤는 자리예요.", "살아 있는 병사는 각자 공격해요. 지원 병사도 공격해요.", "앞 병사는 먼저 공격받으므로 생존력이 중요해요.", "위쪽 카드의 해제로 바로 뺄 수 있어요. 병사 카드를 끌어 순서도 바꿀 수 있어요."]
		"6:1": return ["병사 강화는 비늘과 해당 속성 어혼을 사용해요.", "강화는 +3까지예요. 현재·다음 능력치와 비용을 확인하세요.", "별, 강화 단계, 개체값, 3성 희귀도가 능력치에 영향을 줘요.", "3성 합성 결과는 레어 75%·유니크 20%·전설 5%예요.", "유니크는 능력치 +4%, 전설은 +8% 보너스예요.", "탐험 중에는 병사 강화를 할 수 없어요."]
		"6:2": return ["처음에는 앞 방어·중간 공격·뒤 지원처럼 역할을 나눠 보세요.", "공격 둘은 빠른 처치에, 지원은 회복·보호·적 약화에 도움이 돼요.", "앞 병사가 빨리 쓰러지면 방어와 육성을, 처치가 느리면 공격을 살펴보세요.", "낮게 육성한 지원은 회복·보호 효과도 작아요.", "같은 지원 효과는 중복되지 않으니 서로 다른 효과를 조합해 보세요.", "모든 구간에서 정답인 편성은 없어요. 병사의 능력과 적에 맞춰 바꿔요."]
		"7:0": return ["메뉴 → 탐험에서 노선을 고르고 병사 3마리를 보내요.", "탐험 중 낚시를 계속할 수 있어요.", "낚시터에서는 한 줄로 단계와 진행률을 보고, 누르면 탐험 화면을 열어요.", "성공·실패 결과 카드에서 보상과 처치 기록을 확인해요.", "보상 수령 또는 실패 확인 뒤 병사 배치로 돌아가요.", "실패 시 결과 카드에 표시된 실제 보상을 확인하세요."]
		"7:1": return ["세 병사 각각의 체력 막대를 확인할 수 있어요.", "피해 숫자는 빨간색이에요. 함께 뜨는 역할 아이콘으로 공격 주체를 구분해요.", "회복은 초록색, 보호막과 방어 효과는 파란색이에요.", "숫자는 해당 병사의 행동에 맞춰 따로 표시돼요."]
		"7:2": return ["지원 병사도 기본 공격을 계속해요.", "등불 아귀: 아군 일반 공격 피해 +15%.", "메기 약사: 적 공격력 20% 감소.", "의무병: 3초마다 지속 회복.", "치유사: 위험한 피격 직전 긴급 회복.", "약초지기: 피격 전에 보호막 제공.", "같은 효과는 중복 발동하지 않아요.", "적 한 마리당 병사별 회복과 추가 보호막 합계는 최대 체력의 35%까지예요."]
	return []
func open_home() -> void:
	opened=true;screen="home";scroll=0;page=0;pointer=-2
func sync_layer() -> void:
	if is_instance_valid(clip_root): clip_root.visible=opened and screen!="home"
func icon(m,name: String,r: Rect2) -> void:
	var path: String="res://art/ui/guide_ac/"+name+".png"
	if not textures.has(name): textures[name]=load(path)
	var tex: Texture2D=textures[name]
	if tex==null: return
	var size: Vector2=tex.get_size()
	size*=minf(r.size.x/size.x,r.size.y/size.y)
	m._ui_texture_rect(tex,Rect2(r.get_center()-size/2,size))
func paragraph(m,value: String,pos: Vector2,width: float,size: int=10,col: Color=INK) -> float:
	var lines: Array[String]=preload("res://addons/reservoir/text_layout.gd").wrap(m,value,size,width)
	for i in lines.size():
		m._text(lines[i],pos+Vector2(0,i*(size+5)),size,col,false,width)
		text_boxes.append([Rect2(pos+Vector2(0,i*(size+5)-size),Vector2(width,size+5)),lines[i]])
	return float(lines.size()*(size+5))
func card(m,r: Rect2) -> void:
	m._ui_style_box(m.sb_btn,r)
func row(m,r: Rect2,title: String,kind: String="") -> void:
	card(m,r)
	if kind!="": icon(m,kind,Rect2(r.position+Vector2(7,7),Vector2(r.size.y-14,r.size.y-14)))
	var inset: float=r.size.y+2 if kind!="" else 12
	paragraph(m,title,r.position+Vector2(inset,r.size.y/2+4),r.size.x-inset-24,10)
	m._ui_line(r.position+Vector2(r.size.x-17,r.size.y/2-4),r.position+Vector2(r.size.x-13,r.size.y/2),INK,2)
	m._ui_line(r.position+Vector2(r.size.x-13,r.size.y/2),r.position+Vector2(r.size.x-17,r.size.y/2+4),INK,2)
func setup_layer(m) -> void:
	if not is_instance_valid(m.text_layer): return
	if not is_instance_valid(clip_root):
		clip_root=Control.new();clip_root.name="GuideScrollClip";clip_root.clip_contents=true;clip_root.mouse_filter=Control.MOUSE_FILTER_IGNORE
		m.text_layer.add_child(clip_root)
		body_layer=Node2D.new();body_layer.set_script(load("res://text_layer.gd"));clip_root.add_child(body_layer)
	clip_root.position=viewport.position;clip_root.size=viewport.size;clip_root.visible=true
	body_layer.position=-viewport.position;body_layer.items=body_text;body_layer.commands=body_commands;body_layer.queue_redraw()
func draw(m,h: float) -> void:
	sync_layer();m.text_items.clear();text_boxes.clear()
	m._ui_rect(Rect2(-m.ox,0,m.VW+2*m.ox,h),Color(.02,.04,.06,.86))
	var height: float=minf(500,h-88)
	var r:=Rect2(12,floorf((h-height)/2),246,height)
	m._ui_style_box(m.sb_panel,r)
	preload("res://addons/reservoir/ui_theme.gd").title(m,r,"낚시월드 길잡이" if screen=="home" else TABS[tab])
	var close:=Rect2(r.end.x-32,r.position.y+9,22,23);m._ui_texture(m.icons.close,close.position)
	rects={"close":close.grow(2),"tabs":[],"topics":[],"links":[]}
	if screen!="home":
		var back:=Rect2(r.position+Vector2(9,9),Vector2(24,23));card(m,back);m._ui_line(back.get_center()+Vector2(2,-4),back.get_center()+Vector2(-2,0),INK,2);m._ui_line(back.get_center()+Vector2(-2,0),back.get_center()+Vector2(2,4),INK,2);rects.back=back
	viewport=Rect2(r.position+Vector2(10,48),Vector2(r.size.x-20,r.size.y-60))
	if screen=="home":
		if is_instance_valid(clip_root):clip_root.hide()
		paragraph(m,"무엇이 궁금한가요?",r.position+Vector2(49,63),176,12)
		icon(m,"lantern",Rect2(r.position+Vector2(15,49),Vector2(26,31)))
		paragraph(m,"그림을 눌러 설명을 확인하세요",r.position+Vector2(49,79),176,8,Color("877055"))
		var rh: float=floorf((r.size.y-140)/4)
		for i in 8:
			var b:=Rect2(r.position+Vector2(12+(i%2)*113,91+(i/2)*rh),Vector2(109,rh-6));card(m,b)
			icon(m,HOME_ICONS[i],Rect2(b.position+Vector2(5,(b.size.y-44)/2),Vector2(44,44)))
			paragraph(m,TABS[i],b.position+Vector2(51,b.size.y/2-1),54,10)
			paragraph(m,SUBTITLES[i],b.position+Vector2(51,b.size.y/2+13),54,7,Color("7d654d"))
			rects.tabs.append(b)
		var quick:=Rect2(24,r.end.y-43,222,30)
		row(m,quick,"처음이라면? 기본 조작부터","book");rects.quick=quick
		return
	var old_text: Array=m.text_items;var old_commands: Array=m.ui_commands;m.text_items=[];m.ui_commands=[]
	var y: float=viewport.position.y+8-scroll
	if screen=="topics":y=draw_topics(m,y)
	elif tab==0 and topic==0:y=draw_basics(m,y)
	elif tab==0 and topic==1:y=draw_stars(m,y)
	else:y=draw_article(m,y)
	content_height=y+scroll-viewport.position.y+8
	scroll=clampf(scroll,0,maximum())
	body_text=m.text_items;body_commands=m.ui_commands;m.text_items=old_text;m.ui_commands=old_commands
	setup_layer(m)
	if maximum()>0:
		var track:=Rect2(r.end.x-8,viewport.position.y,2,viewport.size.y);m._ui_rect(track,Color("d5c5a1"))
		var thumb: float=maxf(18,viewport.size.y*viewport.size.y/content_height)
		m._ui_rect(Rect2(track.position+Vector2(0,(track.size.y-thumb)*scroll/maximum()),Vector2(2,thumb)),Color("98714a"))
func draw_topics(m,y: float) -> float:
	icon(m,HOME_ICONS[tab],Rect2(108,y,54,54));y+=75
	m._text(TABS[tab]+" 도움말",Vector2(135,y),14,INK,true,210);y+=26
	for i in TOPICS[tab].size():
		var r:=Rect2(24,y,222,43);row(m,r,TOPICS[tab][i]);rects.topics.append(r);y+=51
	return y
func article_footer(m,y: float) -> float:
	if tab==0 and topic!=0:
		var b:=Rect2(24,y,222,34);row(m,b,"기본 조작 보기","fishing");rects.links.append([b,"basics"]);y+=42
	var b:=Rect2(24,y,222,34);row(m,b,TABS[tab]+" 도움말 목록");rects.links.append([b,"topics"]);return y+42
func draw_stars(m,y: float) -> float:
	m._text("별과 등급",Vector2(135,y+12),17,INK,true,210);y+=33
	y+=paragraph(m,"서로 다른 두 가지 기준이에요",Vector2(28,y),210,10)+12
	var r:=Rect2(24,y,222,180);card(m,r)
	m._text("★ 별 = 어종군",Vector2(37,y+24),14,INK,false,192)
	m._ui_fish(1,Rect2(94,y+38,78,41))
	m._text("★1 ~ ★5 어종군",Vector2(135,y+96),11,Color("977036"),true,190)
	paragraph(m,"어떤 어종이 입질할지 정해요",Vector2(35,y+117),200,10)
	m._ui_rect(Rect2(32,y+128,206,43),Color("d9eee0"))
	m._ui_texture_rect(m.icons["float"],Rect2(36,y+136,24,24));m._ui_texture_rect(m.icons["hook"],Rect2(58,y+136,24,24));m._ui_texture_rect(m.icons["line"],Rect2(80,y+136,24,24))
	paragraph(m,"지역 파츠를 차례로 장착",Vector2(109,y+143),122,8,TEAL)
	paragraph(m,"높은 별 입질이 열려요",Vector2(109,y+158),122,8,TEAL)
	y+=190
	r=Rect2(24,y,222,230);card(m,r)
	m._text("등급 = 희귀도",Vector2(37,y+25),14,INK,false,192)
	for i in 5:
		var x: float=34+(i%3)*67 if i<3 else 67+(i-3)*67
		var cy: float=y+39+(0 if i<3 else 71)
		var cell:=Rect2(x,cy,62,65);card(m,cell);icon(m,"gem%d"%i,Rect2(x+11,cy+4,40,40))
		m._text(m.GRADE_N[i],Vector2(x+31,cy+57),9,INK,true,52)
	paragraph(m,"같은 어종도 등급이 달라요",Vector2(35,y+195),200,10)
	m._ui_rect(Rect2(32,y+205,206,17),Color("d9eee0"));m._text("미끼와 어장 재고도 영향을 줘요",Vector2(135,y+217),8,TEAL,true,196)
	y+=240
	y=draw_sections(m,y)
	return article_footer(m,y+8)

func draw_basics(m,y: float) -> float:
	m._text("이렇게 낚아요",Vector2(135,y+15),17,INK,true,210);y+=38
	y+=paragraph(m,"그림으로 배우는 기본 조작",Vector2(54,y),174,10)+14
	var art := ["bite","hook","reel","dash","land"]
	var titles := ["찌가 잠기면 탭!","별이 중앙에 오면 탭!","누르면 감고, 떼면 풀어요","돌진 전에는 손 떼기","착수하는 순간 탭!"]
	for i in 5:
		var r:=Rect2(24,y,222,126)
		m._ui_style_box(m.sb_primary,Rect2(32,y+8,22,22))
		m._text(str(i+1),Vector2(43,y+24),12,Color("fff1d5"),true,18)
		paragraph(m,titles[i],Vector2(61,y+23),174,10)
		icon(m,"lesson_"+art[i],Rect2(33,y+38,89,78))
		paragraph(m,str(content(m)[i]),Vector2(132,y+57),100,10)
		y+=134
	y+=paragraph(m,str(content(m)[5]),Vector2(34,y+12),200,10)+20
	return article_footer(m,y)
func draw_article(m,y: float) -> float:
	icon(m,HOME_ICONS[tab],Rect2(105,y,60,60));y+=78
	m._text(TOPICS[tab][topic],Vector2(135,y),15,INK,true,210);y+=22
	y=draw_sections(m,y)
	return article_footer(m,y+8)
# Each range groups related original explanations; joining keeps old line breaks
# from splitting a sentence into separate UI boxes. No gameplay values are copied.
func section_specs() -> Array:
	match "%d:%d" % [tab,topic]:
		"0:1":return [["별과 희귀도",0,3],["높은 별을 만나려면",3,6],["미끼 고르기",6,9],["PERFECT 챔질",9,10]]
		"0:2":return [["크기 비교",0,2],["최대 길이와 기록",2,5]]
		"0:3":return [["주인 게이지 쌓기",0,2],["주인 등장 조건",2,4],["도전 후 게이지",4,6]]
		"1:0":return [["별 해금 순서",0,3,true],["파츠 장착 조건",3,7]]
		"1:1":return [["장착과 판매",0,3],["낚싯대 판매 시 주의",3,5]]
		"1:2":return [["강화 방법",0,1],["현재 강화 정보",1,4,true],["강화 전 확인",4,7]]
		"2:0":return [["현재 어장",0,2,true],["재고와 입질",2,4],["저수지·계곡의 예외",4,7]]
		"2:1":return [["어장 키우기",0,2],["현재 회복 능력",2,4,true],["쉬는 동안 회복",4,6]]
		"2:2":return [["낚시터 이동",0,2],["다음 지역 해금",2,6]]
		"3:0":return [["현재 운항 정보",0,3,true],["배 업그레이드",3,5]]
		"3:1":return [["시설별 할 일",0,5,true],["마을 둘러보기",5,6]]
		"3:2":return [["우편 읽기",0,3],["읽음과 삭제",3,5]]
		"4:0":return [["혼 얻기와 사용",0,3],["손질할 물고기 고르기",3,7]]
		"4:1":return [["현재 수족관",0,2,true],["수익과 확장",2,6]]
		"4:2":return [["쉬는 동안 수익 받기",0,4],["예상 수익",4,6]]
		"5:0":return [["어혼과 주머니 얻기",0,3],["주머니 열기",3,6],["탐험 보상",6,7]]
		"5:1":return [["재료 선택",0,3],["조합과 미리보기",3,5],["소모 재료와 보유 한도",5,7]]
		"5:2":return [["합성 조건",0,3],["비용과 개체값",3,5],["병사 보호와 제한",5,7]]
		"6:0":return [["역할과 자리",0,3],["공격과 생존",3,5],["배치 바꾸기",5,6]]
		"6:1":return [["병사 강화",0,3],["3성 희귀도",3,5],["탐험 중 제한",5,6]]
		"6:2":return [["처음 편성할 때",0,2],["전투가 어렵다면",2,4],["상황에 맞는 조합",4,6]]
		"7:0":return [["출발과 진행 확인",0,3],["결과와 보상",3,6]]
		"7:1":return [["체력과 피해 확인",0,2],["회복과 보호 효과",2,4]]
		"7:2":return [["지원도 공격해요",0,1],["병사별 지원 효과",1,6,true],["중복과 회복 한도",6,8]]
	return []
func draw_sections(m,y: float) -> float:
	var source: Array=content(m)
	for spec in section_specs():
		y+=paragraph(m,str(spec[0]),Vector2(34,y+12),202,12,TEAL)+12
		var parts: PackedStringArray=[]
		for i in range(spec[1],spec[2]):parts.append(str(source[i]))
		var value: String=("\n" if spec.size()>3 and spec[3] else " ").join(parts)
		y+=paragraph(m,value,Vector2(34,y+11),202,11)+22
	return y

func maximum() -> float:return maxf(0,content_height-viewport.size.y)
func change_screen(value: String) -> void:
	screen=value;scroll=0;page=0;pointer=-2;dragged=false
func press(m,pos: Vector2) -> void:
	if rects.get("close",Rect2()).has_point(pos):opened=false;sync_layer();return
	if rects.get("back",Rect2()).has_point(pos):change_screen("home" if screen=="topics" else "topics");sync_layer();return
	if screen=="home":
		if rects.get("quick",Rect2()).has_point(pos):tab=0;topic=0;change_screen("article");return
		for i in rects.get("tabs",[]).size():
			if rects.tabs[i].has_point(pos):tab=i;topic=0;change_screen("topics");m.play("ui");return
	elif viewport.has_point(pos):
		for i in rects.get("topics",[]).size():
			if rects.topics[i].has_point(pos):topic=i;change_screen("article");m.play("ui");return
		for link in rects.get("links",[]):
			if link[0].has_point(pos):
				if link[1]=="basics":topic=0;change_screen("article")
				else:change_screen("topics")
				return
func input_event(m,e: InputEvent) -> bool:
	if not opened:return false
	if (e is InputEventMouseButton or e is InputEventMouseMotion) and e.device==-1:return true
	if e is InputEventScreenTouch:
		native_at=Time.get_ticks_msec();var p: Vector2=e.position-Vector2(m.ox,0)
		if e.pressed:
			if pointer==-2:pointer=e.index;start=p;last=p;dragged=false
		elif pointer==e.index:
			pointer=-2
			if not e.canceled and not dragged:press(m,p)
		return true
	if e is InputEventScreenDrag:
		if pointer==e.index:
			var p: Vector2=e.position-Vector2(m.ox,0)
			if start.distance_to(p)>5:dragged=true
			if dragged and viewport.has_point(start) and screen!="home":scroll=clampf(scroll+last.y-p.y,0,maximum())
			last=p
		return true
	if e is InputEventMouseButton:
		var p: Vector2=e.position-Vector2(m.ox,0)
		if e.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			if e.pressed and viewport.has_point(p):scroll=clampf(scroll+(42 if e.button_index==MOUSE_BUTTON_WHEEL_DOWN else -42),0,maximum())
		elif e.button_index==MOUSE_BUTTON_LEFT:
			if e.pressed:pointer=-1;start=p;last=p;dragged=false
			elif pointer==-1:
				pointer=-2
				if not dragged:press(m,p)
		return true
	if e is InputEventMouseMotion and pointer==-1:
		var p: Vector2=e.position-Vector2(m.ox,0)
		if start.distance_to(p)>5:dragged=true
		if dragged and viewport.has_point(start) and screen!="home":scroll=clampf(scroll+last.y-p.y,0,maximum())
		last=p
	return true
