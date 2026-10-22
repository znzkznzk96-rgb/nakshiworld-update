extends RefCounted
# Global indices 0..19 stay reservoir; valley is appended at 20..39.
const NAMES = ["피라미", "붕어", "송사리", "미꾸라지", "블루길", "버들치", "납작붕어", "소금쟁이 피라미", "잉어", "메기", "빠가사리", "향어", "배스", "장어 새끼", "쏘가리", "가물치", "뱀장어", "황금잉어", "달빛붕어", "청룡잉어", "버들치", "쉬리", "조약돌고기", "나뭇잎꼬리", "오름피라미", "물방울송사리", "거꾸로미꾸리", "이끼붕어", "산천어", "송어", "열목어", "폭포오름잉어", "구름피라미", "돌등고기", "무지개송어", "황쏘가리", "하늘연어", "거꾸로잉어", "구름메기", "배후의 산천어"]
const MEANS = [12, 25, 5, 12, 18, 10, 15, 8, 60, 50, 25, 50, 40, 35, 45, 70, 80, 90, 60, 200, 10, 12, 20, 20, 11, 6, 12, 18, 35, 50, 55, 60, 15, 30, 60, 50, 80, 100, 140, 180]
const VALLEY_MAX = [18, 22, 35, 35, 20, 10, 22, 32, 60, 85, 95, 105, 28, 55, 100, 85, 140, 180, 240, 300]
const BY_STAR = [[0,1,2,3,4,5,6,7],[8,9,10,11,12,13],[14,15,16],[17,18],[19]]
static func key(sp: int) -> String:
	return "r%d:s%02d" % [sp / 20, sp % 20]
static func region(sp: int) -> int: return sp / 20
static func by_star(area: int, star: int) -> Array:
	var out: Array = []
	if area < 0 or area > 1 or star < 0 or star > 4: return out
	for local in BY_STAR[star]: out.append(area * 20 + local)
	return out
static func migrate(records: Dictionary, counts: bool = false) -> bool:
	var changed := false
	for sp in 20:
		var old: String = NAMES[sp]
		if not records.has(old): continue
		var stable := key(sp)
		if not records.has(stable): records[stable] = records[old]
		elif records[stable] is Array and records[old] is Array:
			if counts:
				for g in mini(records[stable].size(),records[old].size()): records[stable][g] = maxi(int(records[stable][g]),int(records[old][g]))
			else:
				for g in records[old]:
					if g not in records[stable]: records[stable].append(g)
		elif records[stable] is float or records[stable] is int: records[stable] = maxf(float(records[stable]),float(records[old]))
		records.erase(old);changed = true
	return changed
