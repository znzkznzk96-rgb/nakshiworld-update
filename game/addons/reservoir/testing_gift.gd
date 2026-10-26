extends RefCounted
const ID = "testing-20261026-078"
static func claim(m) -> bool:
	if ID in m.testing_grants or m.development_preview or m.resetting: return false
	var old_gold: int=m.gold
	var old_souls: int=m.souls
	var old_elements: Array=m.expedition.data.souls.duplicate()
	var old_size: int=m.bag.size()
	for sp in 20:
		var star: int=0
		for i in m.BY_STAR.size():
			if sp in m.BY_STAR[i]: star=i;break
		m.bag.append({"sp":sp,"star":star,"grade":3,"len":float(m.FISH_LEN[sp]),"w":float(m.W_BASE[star])*float(m.W_GRADE[3]),"price":m.fish_price(sp,star,3,1.0),"shoulder":false})
	m.gold+=1000000;m.souls+=1000
	for i in 5: m.expedition.data.souls[i]+=50
	m.testing_grants.append(ID)
	if m._save_game(): return true
	# Do not display success or keep a partial in-memory grant after failed persistence.
	m.gold=old_gold;m.souls=old_souls;m.expedition.data.souls=old_elements
	m.bag.resize(old_size);m.testing_grants.erase(ID)
	return false
