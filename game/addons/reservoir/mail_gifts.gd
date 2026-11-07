extends RefCounted
# Stable IDs are save compatibility keys. Historical release letter bodies stay verbatim.
const Catalog = preload("res://addons/reservoir/regional_catalog.gd")
const DATA = {
	"0.78": {"id":"testing-20261026-078","region":0,"grade":3,"gold":1000000,"souls":1000,"elements":50,"button":"테스트 선물 받기","claimed":"테스트 선물 수령 완료","toast":"테스트 선물을 받았어요!","save_error":false},
	"0.93": {"id":"reservoir-legendary-20261029-093","region":0,"grade":3,"gold":100000,"souls":0,"elements":0,"button":"전설 20마리 + 10만 비늘 받기","claimed":"선물 수령 완료","toast":"전설 물고기 20마리 · 100,000비늘 수령","save_error":false},
	"1.08": {"id":"valley-once-20261107-108","region":1,"grade":0,"gold":1000000,"souls":0,"elements":0,"button":"계곡 20종 + 100만 비늘 받기","claimed":"선물 수령 완료","toast":"계곡20종 · 1,000,000비늘 수령","save_error":true}
}
static func info(letter_id: String) -> Dictionary:
	return DATA.get(letter_id,{})
static func claim(m,letter_id: String) -> bool:
	var gift: Dictionary=info(letter_id)
	if gift.is_empty() or gift.id in m.testing_grants or m.development_preview or m.resetting: return false
	var old_gold: int=m.gold
	var old_souls: int=m.souls
	var old_elements: Array=m.expedition.data.souls.duplicate()
	var old_size: int=m.bag.size()
	for sp in range(gift.region*20,gift.region*20+20):
		var star: int=0
		for i in 5:
			var species: Array=m.BY_STAR[i] if gift.region==0 else Catalog.by_star(gift.region,i)
			if sp in species: star=i;break
		m.bag.append({"sp":sp,"star":star,"grade":gift.grade,"len":float(m.FISH_LEN[sp]),"w":float(m.W_BASE[star])*float(m.W_GRADE[gift.grade]),"price":m.fish_price(sp,star,gift.grade,1.0),"shoulder":false})
	m.gold+=gift.gold;m.souls+=gift.souls
	for i in 5: m.expedition.data.souls[i]+=gift.elements
	m.testing_grants.append(gift.id)
	if m._save_game(): return true
	m.gold=old_gold;m.souls=old_souls;m.expedition.data.souls=old_elements
	m.bag.resize(old_size);m.testing_grants.erase(gift.id)
	return false
