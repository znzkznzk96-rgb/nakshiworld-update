extends RefCounted
# Stable global indices: reservoir 0..19, valley 20..39, tile sea 40..59.
const NAMES = ["피라미", "붕어", "송사리", "미꾸라지", "블루길", "버들치", "납작붕어", "소금쟁이 피라미", "잉어", "메기", "빠가사리", "향어", "배스", "장어 새끼", "쏘가리", "가물치", "뱀장어", "황금잉어", "달빛붕어", "청룡잉어", "버들치", "쉬리", "조약돌고기", "나뭇잎꼬리", "오름피라미", "물방울송사리", "거꾸로미꾸리", "이끼붕어", "산천어", "송어", "열목어", "폭포오름잉어", "구름피라미", "돌등고기", "무지개송어", "황쏘가리", "하늘연어", "거꾸로잉어", "구름메기", "배후의 산천어", "망둥어", "줄눈전갱이", "고등어", "학꽁치", "깨진타일놀래미", "복어", "타일망둥", "수영모해파리", "균열도자기우럭", "감성돔", "청소솔쥐치", "모자이크가자미", "튜브복어", "유령락스장어", "참돔", "농어", "바둑판가오리", "유리타일돌돔", "배수구 대왕장어", "심청유리 실러캔스", "쌍혜성 두꼬리꽁치", "균열정어리", "네날개날치", "가시등전어", "균열장막 오징어", "쥐포쥐치", "금간정어리", "빛멸치", "균열갑주 방어", "유영리본 삼치", "균열칼날 갈치", "균열꽃 광어", "틈새결정 복어", "거울날개 날치", "차원결정 참치", "월식 개복치", "뇌광 삼치", "차원창 청새치", "균열유리 상어", "폭풍다랑어"]
const MEANS = [12, 25, 5, 12, 18, 10, 15, 8, 60, 50, 25, 50, 40, 35, 45, 70, 80, 90, 60, 200, 10, 12, 20, 20, 11, 6, 12, 18, 35, 50, 55, 60, 15, 30, 60, 50, 80, 100, 140, 180, 10, 12, 20, 20, 11, 6, 12, 18, 35, 50, 55, 60, 15, 30, 60, 50, 80, 100, 140, 180, 30, 18, 32, 22, 45, 25, 20, 12, 70, 55, 80, 60, 65, 95, 130, 150, 180, 230, 220, 400]
const VALLEY_MAX = [18, 22, 35, 35, 20, 10, 22, 32, 60, 85, 95, 105, 28, 55, 100, 85, 140, 180, 240, 300]
const BY_STAR = [[0,1,2,3,4,5,6,7],[8,9,10,11,12,13],[14,15,16],[17,18],[19]]
static func key(sp: int) -> String:
	return "r%d:s%02d" % [sp / 20, sp % 20]
static func region(sp: int) -> int: return sp / 20
static func by_star(area: int, star: int) -> Array:
	var out: Array = []
	if area < 0 or area > 3 or star < 0 or star > 4: return out
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
