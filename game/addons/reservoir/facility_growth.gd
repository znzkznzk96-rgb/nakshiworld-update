extends RefCounted
# Regional facility progression; price 0 means prepared, never a free purchase.
const REV := 1
const MAX_LEVEL := 12
const BASE_STOCK := 30.0
const AQUA_CAP := [3,4,6,8,10,15,20,22,24,26,28,30,32]
const STOCK_ADD := [0,10,20,40,60,80,100,115,130,145,160,175,190]
const RECOVERY := [30,35,40,50,60,70,80,90,100,110,120,130,140]
const PASSENGERS := [4,5,6,8,10,12,14,15,16,17,18,19,20]
const INTERVAL := [60,58,56,52,48,44,40,40,40,40,40,40,40]
const AQUA_COST := [7500,22500,40000,110000,400000,1200000,0,0,0,0,0,0]
const BOAT_COST := [6000,18000,30000,90000,300000,1000000,0,0,0,0,0,0]
const CAP_COST := [4000,12000,20000,60000,250000,750000,0,0,0,0,0,0]
const REGEN_COST := AQUA_COST
const FIELDS := {"aexpand":"aqua_lv","boat":"boat_lv","pondcap":"pond_cap_lv","pondregen":"pond_regen_lv"}
const PRICES := {"aexpand":AQUA_COST,"boat":BOAT_COST,"pondcap":CAP_COST,"pondregen":REGEN_COST}
const OLD_AQUA := [0,2,4,5,6]
const OLD_OTHER := [0,2,3,4,5,6]

static func level(m, action: String) -> int:
	return clampi(int(m.get(FIELDS[action])),0,MAX_LEVEL) if FIELDS.has(action) else MAX_LEVEL

static func cost(m, action: String) -> int:
	var lv := level(m,action)
	return int(PRICES[action][lv]) if FIELDS.has(action) and lv<MAX_LEVEL else 0

static func unlocked(m, action: String) -> bool:
	var lv := level(m,action)
	if lv>=MAX_LEVEL or cost(m,action)<=0: return false
	var area := int(lv/2)
	return area in m.progression.available_regions and m.region_shop.is_unlocked(area)

static func lock_label(m, action: String) -> String:
	var lv := level(m,action)
	if lv>=MAX_LEVEL: return "최대 단계"
	var area := int(lv/2)
	if cost(m,action)<=0 or area not in m.progression.available_regions: return "다음 낚시터 · 준비 중"
	return m.region_shop.TITLES[area]+" 해금 필요"

static func purchase(m, action: String) -> bool:
	if not unlocked(m,action) or m.gold<cost(m,action): return false
	var field: String=FIELDS[action]
	var old_level := level(m,action)
	var old_gold: int=m.gold
	var old_stock: float=m.pond_stock
	var old_aqua: Array=m.aqua.duplicate(true)
	var ratio: float=clampf(m.pond_stock/m.pond_max(),0,1)
	m.gold-=cost(m,action)
	m.set(field,old_level+1)
	if action=="aexpand": m.aqua.resize(m.aqua_capacity())
	if action=="pondcap": m.pond_stock=ratio*m.pond_max()
	if not m._save_game():
		m.gold=old_gold;m.set(field,old_level);m.pond_stock=old_stock;m.aqua=old_aqua
		return false
	return true

static func migrate(source: Dictionary) -> Dictionary:
	var d: Dictionary=source.duplicate(true)
	if int(d.get("facility_rev",0))>=REV: return d
	var old_cap := clampi(int(d.get("pond_cap_lv",0)),0,5)
	var old_base := 40.0 if d.has("pond_base") and float(d.pond_base)<=40 else 80.0
	var stock := clampf(float(d.get("pond_stock",80.0)),0,old_base+old_cap*20.0)
	d.aqua_lv=OLD_AQUA[clampi(int(d.get("aqua_lv",0)),0,4)]
	# Old saves may infer their tank rank from its serialized slot count.
	var aq: Array=d.get("aqua",[])
	while int(d.aqua_lv)<6 and AQUA_CAP[int(d.aqua_lv)]<mini(aq.size(),20): d.aqua_lv+=1
	for field in ["boat_lv","pond_cap_lv","pond_regen_lv"]:
		d[field]=OLD_OTHER[clampi(int(d.get(field,0)),0,5)]
	d.pond_base=BASE_STOCK
	var maximum: float=BASE_STOCK+STOCK_ADD[int(d.pond_cap_lv)]
	d.pond_stock=minf(stock,maximum)
	d.pond_overflow=maxf(0,stock-maximum)+maxf(0,float(d.get("pond_overflow",0)))
	d.facility_rev=REV
	return d

static func refill_reserve(m) -> void:
	var amount: float=minf(maxf(0,m.pond_max()-m.pond_stock),m.pond_overflow)
	m.pond_stock+=amount;m.pond_overflow-=amount
