extends RefCounted
const TABS := ["낚시", "장비", "어장", "마을", "성장"]
const TOPICS := [["기본 조작", "별과 등급", "길이 측정"], ["파츠 해금", "장착·판매", "강화"], ["어장 상태", "회복과 확장", "낚시터"], ["배와 방문객", "시설 안내", "우편함"], ["혼", "수족관", "쉬는 동안"]]
var opened := false
var tab := 0
var topic := 0
var button := Rect2()
var rects := {}
func draw_button(m) -> void:
	button = Rect2(140, m.top_y + 2, 28, 27)
	m._ui_texture_rect(preload("res://art/guide64/book.png"),Rect2(button.position+Vector2(3,2),Vector2(24,24)))

func content(m) -> Array:
	match "%d:%d" % [tab, topic]:
		"0:0": return ["찌가 완전히 잠길 때 탭해요.", "훅 게이지의 별이 중앙에 오면 탭!", "싸울 때 누르면 감고, 떼면 풀어요.", "돌진 전 웅크리면 미리 손을 떼요.", "점프 중에는 떼고 착수할 때 탭!", "자세한 동작: 설정 → 몸짓 도감"]
		"0:1": return ["별은 어종군, 등급은 희귀도예요.", "등급: 노멀 → 레어 → 유니크", "→ 전설 → 신화", "파츠를 순서대로 장착하면", "더 높은 별의 입질이 열려요.", "미끼와 어장 재고도 영향을 줘요.", "PERFECT는 등급 상승 기회가 있어요."]
		"0:2": return ["줄자는 어종마다 같은 눈금을 써요.", "같은 어종의 크기를 비교해 보세요.", "동네저수지 최대 길이: %dcm" % m.RESERVOIR_MAX_CM, "어종별 한도는 이보다 작을 수 있어요.", "기존 물고기와 기록은 유지돼요."]
		"1:0": return ["찌 장착: ★2 어종군 입질 해금", "찌 + 바늘: ★3 해금", "찌 + 바늘 + 줄: ★4 해금", "앞 단계 파츠도 장착해야 해요.", "릴은 주인 낚시를 위한 마지막 파츠예요.", "★5 주인 낚시는 아직 준비 중이에요.", "별 해금과 희귀 등급은 별개예요."]
		"1:1": return ["가방에서 장착·해제할 수 있어요.", "장착한 장비는 먼저 해제해야 팔려요.", "물고기가 든 보관함은 비워 주세요.", "판매한 낚싯대의 강화는 초기화돼요.", "다시 구매할 수 있지만 강화는 복구 안 돼요."]
		"1:2":
			var e = m.V.enhancement
			return ["대장간에서 비늘과 혼으로 강화해요.", "현재 낚싯대 강화: +%d" % m.forge_lv, "다음 비용: %d 비늘 / %d 혼" % [e.cost(m.forge_lv, m.rod_lv), e.soul_cost(m.rod_lv, m.forge_lv)], "성공률: %.0f%%" % (e.chance(m.rod_lv, m.forge_lv)*100), "낚싯대별 강화 한도가 있어요.", "높은 단계는 실패 시 하락할 수 있어요.", "보호권 사용 여부를 확인하세요."]
		"2:0": return ["현재 재고: %.0f / %d마리" % [m.pond_stock, m.pond_max()], "시간당 회복: %d마리" % m.pond_recovery(), "낚시를 던질 때 재고를 사용해요.", "재고가 적으면 높은 별 입질이 줄어요.", "재고가 비면 ★1 어종군만 나와요."]
		"2:1": return ["어장 확장: 최대 재고가 늘어요.", "회복 강화: 시간당 회복이 늘어요.", "현재 최대: %d마리" % m.pond_max(), "현재 회복: 시간당 %d마리" % m.pond_recovery(), "쉬는 동안에도 재고가 회복돼요.", "회복 계산은 최대 8시간이에요."]
		"2:2": return ["현재 낚시 가능: 동네저수지", "메뉴 → 낚시터에서 이동해요.", "다른 낚시터는 아직 잠겨 있어요.", "새 지역의 어종과 길이 한도는", "지역이 열릴 때 안내할게요."]
		"3:0": return ["배 Lv.%d" % (m.boat_lv+1), "한 번에 %d명 / %.0f초마다 입항" % [m.V.capacity(m), m.V.interval(m)], "수족관 수익 배수: ×%.2f" % m.V.multiplier(m), "선착장에서 배를 업그레이드해요.", "방문객 수와 입항 간격이 개선돼요."]
		"3:1": return ["낚시점: 장비·미끼 구매", "대장간: 낚싯대 강화", "어시장: 물고기 판매와 혼 획득", "수족관: 물고기를 넣고 수익 얻기", "어류박물관: 어종·등급 수집 확인", "마을을 좌우로 밀어 둘러보세요."]
		"3:2": return ["상단 봉투를 누르면 업데이트 우편!", "새 버전의 변경점을 확인하세요.", "읽지 않은 우편에는 NEW가 표시돼요.", "읽음·삭제 상태는 저장돼요.", "삭제한 우편이 다시 생기지 않아요."]
		"4:0": return ["어시장에서 손질하면 혼을 얻어요.", "혼은 낚싯대 강화에 사용해요.", "물고기의 별과 희귀 등급에 따라", "얻는 혼의 수가 달라져요.", "손질할 물고기와 수족관에 둘 물고기를", "나눠서 선택해 보세요."]
		"4:1": return ["현재 수족관: %d / %d마리" % [m.aqua_count(), m.aqua_capacity()], "예상 수익: 시간당 %.1f 비늘" % (m.aqua_rate()*60), "물고기의 판매가와 마을 배수가", "수익에 반영돼요.", "수족관을 확장하면 더 넣을 수 있어요.", "박물관 기록과 수족관 수익은 별개예요."]
		"4:2": return ["수족관에 물고기를 넣어 두세요.", "다시 접속하면 쉬는 동안의 수익을", "자동으로 받고 안내를 볼 수 있어요.", "오프라인 계산은 최대 8시간이에요.", "현재 예상: 시간당 %.1f 비늘" % (m.aqua_rate()*60), "적은 금액은 정수로 계산돼요."]
	return []
func draw(m, h: float) -> void:
	m.text_items.clear()
	m._ui_rect(Rect2(-m.ox, 0, m.VW+2*m.ox, h), Color(0.02,0.04,0.06,0.86))
	var r := Rect2(12, maxf(m.top_y+43, (h-350)/2), 246, 350)
	m._ui_style_box(m.sb_panel, r)
	preload("res://addons/reservoir/ui_theme.gd").title(m, r, "낚시월드 길잡이")
	var close := Rect2(r.end.x-32,r.position.y+9,22,23)
	m._ui_texture(m.icons.close,close.position)
	rects = {"close":close.grow(3), "tabs":[], "topics":[]}
	for i in TABS.size():
		var b := Rect2(22+i*46,r.position.y+49,43,25)
		m._ui_style_box(m.sb_chip,b)
		if tab == i: m._ui_rect(Rect2(b.position+Vector2(5,22),Vector2(33,2)),Color("418b78"))
		m._text(TABS[i],b.get_center()+Vector2(0,3),9,Color("382619"),true,40)
		rects.tabs.append(b)
	for i in TOPICS[tab].size():
		var b := Rect2(22+i*76,r.position.y+83,72,24)
		m._ui_style_box(m.sb_btn,b)
		m._text(TOPICS[tab][i],b.get_center()+Vector2(0,3),8,Color("27674e") if topic == i else Color("68533d"),true,68)
		rects.topics.append(b)
	m._text(TOPICS[tab][topic], Vector2(135,r.position.y+132),12,Color("382619"),true,220)
	var y: float = r.position.y+159
	for line in content(m):
		m._text(line,Vector2(25,y),9,Color("513b29"),false,219);y += 21
	m._text("탭을 눌러 필요한 설명만 읽어 보세요",Vector2(135,r.end.y-19),8,Color("796b58"),true,220)
func press(_m, pos: Vector2) -> void:
	_m.play("ui")
	if rects.get("close",Rect2()).has_point(pos): opened=false;return
	for i in rects.get("tabs",[]).size():
		if rects.tabs[i].has_point(pos): tab=i;topic=0;return
	for i in rects.get("topics",[]).size():
		if rects.topics[i].has_point(pos): topic=i;return
