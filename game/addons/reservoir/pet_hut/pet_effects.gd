class_name PetEffects
extends RefCounted
# 대표 펫의 능력(GAME_BIBLE 2026-11-23 초안 수치). 대표 1마리의 능력만 적용한다.
# 모든 능력 연결됨: bite_wait·miss_sec·miss_pct 입질, tension·first_shock 파이팅, bait_save, scale·extra 비늘조각,
#        income_* 전시 수입, atk·boss·cut 용병, amp2·amp3 로봇 포획 증폭, upgrade·hypnosis 별의 사도.
const FX := {
	"d_chick": {"income1": 0.02}, "d_frog": {"miss_sec": 0.2}, "d_mouse": {"cut": 1},
	"c_mushroom": {"bait_save": 0.05}, "c_puffbird": {"bite_wait": 0.05}, "c_slime": {"tension": 0.05},
	"b_hamster": {"scale": 0.05}, "b_hedgehog": {"tension": 0.04}, "b_sparrow": {"bite_wait": 0.04},
	"a_fennec": {"bite_wait": 0.08}, "a_otter": {"bait_save": 0.10}, "a_owl": {"first_shock": 0.40},
	"s_fairy": {"income12": 0.08}, "s_tome": {"scale": 0.15, "extra": 0.10}, "s_wisp": {"amp2": 0.08},
	"ss_golem": {"amp2": 0.10, "amp3": 0.03}, "ss_knight": {"atk": 0.10, "cut": 2}, "ss_storm": {"bite_wait": 0.12, "miss_pct": 0.30},
	"sss_apostle": {"upgrade": 0.40, "hypnosis": 0.25}, "sss_demon": {"atk": 0.15, "boss": 0.10},
	"sss_lunar": {"income_all": 0.10}, "sss_seraph": {"amp2": 0.15, "amp3": 0.05},
}

# 저장 데이터(pet_hut)에서 대표 펫. 대표가 장착 목록에 없으면 첫 장착 펫, 없으면 "".
static func leader(d: Dictionary) -> String:
	var e = d.get("e", [])
	var l := str(d.get("l", ""))
	if e is Array and e.has(l): return l
	return str(e[0]) if e is Array and e.size() > 0 else ""

static func value(d: Dictionary, name: String) -> float:
	var k := leader(d)
	return float(FX.get(k, {}).get(name, 0.0)) if k != "" else 0.0

# 전시 물고기 1마리의 수입 배율(별 0=★1)
static func income_mul(d: Dictionary, star: int) -> float:
	var m := 1.0 + value(d, "income_all")
	if star <= 1: m += value(d, "income12")
	if star == 0: m += value(d, "income1")
	return m

# 정수 보상을 확률 반올림으로 늘린다(작은 값도 기대값이 맞도록)
static func boost_int(base: int, bonus: float, roll: float) -> int:
	var x := float(base) * bonus
	var whole := int(floor(x))
	return base + whole + (1 if roll < x - whole else 0)

# 포획 증폭: 로봇이 만든 물고기 1마리의 배수(1~3). roll은 0~1 난수
static func amp_count(d: Dictionary, roll: float) -> int:
	var a3 := value(d, "amp3")
	if roll < a3: return 3
	if roll < a3 + value(d, "amp2"): return 2
	return 1
