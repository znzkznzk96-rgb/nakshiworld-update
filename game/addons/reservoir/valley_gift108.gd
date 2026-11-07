extends RefCounted
const ID = "valley-once-20261107-108"
const GOLD_AMOUNT = 1000000
const Catalog = preload("res://addons/reservoir/regional_catalog.gd")
static func claim(m) -> bool:
	if ID in m.testing_grants or m.development_preview or m.resetting: return false
	var old_gold: int=m.gold
	var old_size: int=m.bag.size()
	for sp in range(20,40):
		var star: int=0
		for i in 5:
			if sp in Catalog.by_star(1,i): star=i;break
		m.bag.append({"sp":sp,"star":star,"grade":0,"len":float(m.FISH_LEN[sp]),"w":float(m.W_BASE[star]),"price":m.fish_price(sp,star,0,1.0),"shoulder":false})
	m.gold+=GOLD_AMOUNT
	m.testing_grants.append(ID)
	if m._save_game(): return true
	m.gold=old_gold
	m.bag.resize(old_size);m.testing_grants.erase(ID)
	return false
