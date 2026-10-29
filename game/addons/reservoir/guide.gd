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
func draw(m, h: float) -> void:
	m.text_items.clear()
	m._ui_rect(Rect2(-m.ox, 0, m.VW+2*m.ox, h), Color(0.02,0.04,0.06,0.86))
	var panel_height: float=minf(440,h-88)
	var r := Rect2(12, floorf((h-panel_height)/2), 246, panel_height)
	m._ui_style_box(m.sb_panel, r)
	preload("res://addons/reservoir/ui_theme.gd").title(m, r, "낚시월드 길잡이")
	var close := Rect2(r.end.x-32,r.position.y+9,22,23)
	m._ui_texture(m.icons.close,close.position)
	rects = {"close":close.grow(3), "tabs":[], "topics":[]}
	for i in TABS.size():
		var b := Rect2(22+(i%4)*57,r.position.y+47+(i/4)*29,54,25)
		m._ui_style_box(m.sb_primary if tab==i else m.sb_btn,b)
		m._text(TABS[i],b.get_center()+Vector2(0,3),9,Color("fff0d1") if tab==i else Color("382619"),true,50)
		rects.tabs.append(b)
	var width: float=228.0/TOPICS[tab].size()
	for i in TOPICS[tab].size():
		var b := Rect2(22+i*width,r.position.y+112,width-4,24)
		m._ui_style_box(m.sb_btn,b)
		m._text(TOPICS[tab][i],b.get_center()+Vector2(0,3),8,Color("27674e") if topic == i else Color("68533d"),true,width-8)
		rects.topics.append(b)
	if tab==5 and topic==0:
		m._ui_texture_rect(preload("res://addons/reservoir/soul_pouch_shop.gd").icon(),Rect2(108,r.position.y+148,54,54))
	elif tab in [5,6]:
		m.expedition.sprite(m,0,Rect2(108,r.position.y+148,54,54))
	elif tab==7:
		m._ui_texture_rect(m.expedition.textures.explore,Rect2(108,r.position.y+148,54,54))
	else: Reader.illustration(m,["fish","tackle","hall","boat","aquarium"][tab],r.position.y+148)
	m._text(TOPICS[tab][topic],Vector2(135,r.position.y+220),13,Color("382619"),true,220)
	rects.reader=Reader.draw(m,content(m),page,r.position.y+242,r.end.y-64)
	m._text("탭을 눌러 필요한 설명을 확인하세요",Vector2(135,r.end.y-17),9,Color("796b58"),true,220)
func press(_m, pos: Vector2) -> void:
	_m.play("ui")
	if rects.get("close",Rect2()).has_point(pos): opened=false;return
	for i in rects.get("tabs",[]).size():
		if rects.tabs[i].has_point(pos): tab=i;topic=0;page=0;return
	for i in rects.get("topics",[]).size():
		if rects.topics[i].has_point(pos): topic=i;page=0;return
	var reader: Dictionary = rects.get("reader",{})
	if reader.get("previous",Rect2()).has_point(pos): page=maxi(0,page-1)
	if reader.get("following",Rect2()).has_point(pos): page=mini(reader.count-1,page+1)
