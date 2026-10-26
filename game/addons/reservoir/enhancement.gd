extends RefCounted

const LIMIT: = [5, 8, 10, 13, 16, 20]
const SOUL_COEF: = [1, 2, 4, 8, 16, 32]
var phase: = ""
var elapsed: = 0.0
var strikes: = 0
var use_protection: = false
var record: = {}
var animation: = {}
func setup() -> void :
	animation["rod_sheet"] = load("res://art/effects/upgrade/rod.png")
	for name in ["smith", "success", "failure"]:
		var frames: Array = []
		for i in 8:
			var path: String = "res://art/refresh52/%s_%d.png" % [name, i]
			if ResourceLoader.exists(path): frames.append(load(path))
		animation[name] = frames
func chance(rod: int, level: int) -> float:
	return maxf(0.3, 0.95 - 0.05 * float(level) * 20.0 / LIMIT[rod])
const BASE_COST: = [90, 300, 1080, 3600, 12000, 39000]
func cost(level: int, rod: int = 0) -> int: return roundi(BASE_COST[clampi(rod, 0, 5)] * pow(1.2, level))
func soul_cost(rod: int, level: int) -> int: return ceili(SOUL_COEF[rod] * 3.0 * pow(1.2, level))
func risky(rod: int, level: int) -> bool: return level >= ceili(LIMIT[rod] / 2.0)
func busy() -> bool: return phase != ""
func restore(m) -> void :
	if not m.forge_pending.is_empty():
		record = m.forge_pending.duplicate();phase = "result";elapsed = 3.0;m.scene = "village";m.title_open = false;m.forge_seen = true;m.V.shop = "forge";m.V.forge_tab = "upgrade"
func start(m, roll: float = -1.0) -> bool:
	if busy() or not m.equipment.rod_equipped: return false
	var rod: int = m.rod_lv
	var old: int = m.forge_lv
	if old >= LIMIT[rod] or m.gold < cost(old, rod) or m.souls < soul_cost(rod, old): return false
	var protected: bool = use_protection and risky(rod, old) and m.protection_tickets > 0
	m.gold -= cost(old, rod);m.souls -= soul_cost(rod, old)
	if protected: m.protection_tickets -= 1
	var success: bool = (randf() if roll < 0.0 else roll) < chance(rod, old)
	var next: int = old + 1 if success else (old - 1 if risky(rod, old) and not protected else old)
	m.forge_lv = next
	record = {"rod": rod, "old": old, "next": next, "success": success, "protected": protected}
	m.forge_pending = record.duplicate();m._save_game()
	phase = "working";elapsed = 0.0;strikes = 0
	return true
func process(m, dt: float) -> void :
	if phase == "": return
	elapsed += dt
	if phase == "working":
		var strike: int = clampi(int(floor((elapsed - 0.5) / 1.3)) + 1, 0, 2)
		if strike > strikes:
			strikes = strike;m.play("hammer", -4.0, 0.96 + strikes * 0.03);m.buzz([20])
		if elapsed >= 2.6:
			phase = "result";elapsed = 0.0;m.forge_seen = true;m._save_game()
			m.play("catch" if bool(record.success) else "snap")
			m.buzz([40, 20, 70] if bool(record.success) else [80])
func dismiss(m) -> void :
	phase = "";record = {};m.forge_pending = {};m._save_game()
func act(v, m, a: String) -> bool:
	match a:
		"forge": start(m);return true
		"forge_skip": elapsed = 2.6;process(m, 0.0);return true
		"forge_done": dismiss(m);return true
		"forge_protect": use_protection = not use_protection;return true
		"forge_ticket":
			if m.pearl >= 1: m.pearl -= 1;m.protection_tickets += 1;m._save_game()
			return true
	return false
func _button(v, m, rect: Rect2, text: String, action: String, enabled: bool = true) -> void :
	m._ui_style_box(v.active_style.header if enabled else v.active_style.card, rect)
	m._text(text, rect.get_center() + Vector2(0, 4), 10, Color("fff0d1") if enabled else Color("817767"), true, rect.size.x - 8)
	if enabled or action == "forge_ticket": v.rects.rows.append([rect, action])
func _material(v, m, r: Rect2, icon: Texture2D, name: String, required: int, owned: int) -> void :
	m._ui_style_box(v.active_style.card, r)
	m._ui_texture(icon, r.position + Vector2(6, 6))
	m._text(name, r.position + Vector2(69, 19), 11, v.active_style.ink, true, 61)
	var color: = Color("386749") if owned >= required else Color("ae433b")
	m._text("필요 %d" % required, r.position + Vector2(53, 36), 14, color, true, 97)
	m._text("보유 %d" % owned, r.position + Vector2(53, 51), 10, Color("75614d"), true, 97)
func draw(v, m, r: Rect2, y: float) -> void :
	if busy(): _cinematic(v, m, r, y);return
	var rod: int = m.rod_lv; var level: int = m.forge_lv
	m._ui_style_box(v.active_style.card, Rect2(26, y, 218, 49))
	m._ui_texture(v.rods[rod], Vector2(33, y + 8))
	m._text(v.ROD_NAME[rod], Vector2(154, y + 19), 12, v.active_style.ink, true, 162)
	m._text("현재 +%d  /  최대 +%d" % [level, LIMIT[rod]], Vector2(154, y + 38), 11, v.active_style.ink, true, 162)
	if r.end.y - y < 270:
		m._text("감기 +%d%% · 장력 -%d%% · 판매 +%d%%" % [level * 3, level * 2, level * 5], Vector2(135, y + 65), 10, v.active_style.ink, true, 232)
		y -= 14
	else:
		m._text("감기 +%d%% · 장력 증가 -%d%%" % [level * 3, level * 2], Vector2(135, y + 64), 10, v.active_style.ink, true, 232)
		m._text("판매가 +%d%%" % (level * 5), Vector2(135, y + 78), 10, v.active_style.ink, true, 232)
	if level >= LIMIT[rod]:
		m._text("이 낚싯대의 최고 강화 단계입니다", Vector2(135, y + 128), 12, v.active_style.ink, true, 230);return
	var chance_box: = Rect2(26, y + 85, 218, 36)
	m._ui_style_box(v.active_style.header, chance_box)
	m._text("강화 성공률", Vector2(85, y + 109), 12, Color("fff0d1"), true, 100)
	m._text("%d%%" % roundi(chance(rod, level) * 100), Vector2(195, y + 111), 20, Color("ffdf89"), true, 78)
	_material(v, m, Rect2(26, y + 127, 105, 58), v.tool_icons.soul, "혼", soul_cost(rod, level), m.souls)
	_material(v, m, Rect2(139, y + 127, 105, 58), m.icons.scale, "비늘", cost(level, rod), m.gold)
	var danger: String = "실패 시 1단계 하락 · 보호권으로 방지" if risky(rod, level) else "실패해도 강화 단계가 유지돼요"
	m._text(danger, Vector2(135, y + 199), 10, Color("a34a40") if risky(rod, level) else Color("456a50"), true, 228)
	_button(v, m, Rect2(26, y + 207, 218, 23), "하락 보호권 %s · 보유 %d장" % ["사용" if use_protection else "미사용", m.protection_tickets], "forge_protect", risky(rod, level) and m.protection_tickets > 0)
	_button(v, m, Rect2(26, y + 236, 105, 26), "보호권 1진주", "forge_ticket", m.pearl >= 1)
	_button(v, m, Rect2(139, y + 236, 105, 26), "강화 시작", "forge", m.equipment.rod_equipped and m.gold >= cost(level, rod) and m.souls >= soul_cost(rod, level))
func _cinematic(v, m, r: Rect2, y: float) -> void :
	var scene: = Rect2(39, y + 5, 192, 112)
	m._ui_rect(scene, Color("211d24"))
	# The approved 13-frame PixelLab cycle replaces the old eight-frame smith.
	var fi: int = mini(12,int(fposmod(elapsed,1.3)/0.1)) if phase=="working" else 0
	m._ui_texture_rect_region(animation.rod_sheet,scene,Rect2(fi*192,0,192,112))
	m.ui_commands.append(["rotated_texture", v.rods[int(record.rod)], scene.position + Vector2(112, 74), PI / 4])
	if phase == "working":
		m._text("강화 중…", Vector2(135, y + 140), 14, v.active_style.ink, true, 230)
		m._ui_rect(Rect2(39, y + 154, 192, 9), Color("382c2c"))
		m._ui_rect(Rect2(40, y + 155, 190 * minf(1, elapsed / 2.6), 7), Color("e7ad56"))
		m._text("+%d → +%d" % [int(record.old), int(record.old) + 1], Vector2(135, y + 191), 16, v.active_style.ink, true, 220)
		if m.forge_seen: _button(v, m, Rect2(91, y + 213, 88, 25), "빠르게 보기", "forge_skip")
	else:
		var ok: bool = record.success
		var frames: Array = animation.get("success" if ok else "failure", [])
		if ok and elapsed < 1.1:
			for spark in 8:
				var p := scene.get_center() + Vector2(cos(spark * TAU / 8) * (10 + elapsed * 25), sin(spark * TAU / 8) * (10 + elapsed * 25))
				m._ui_rect(Rect2(p.round(), Vector2(2, 2)), Color(1.0, 0.8, 0.3, 1.0 - elapsed / 1.1))
		var title: String = "강화 성공!" if ok else ("강화 실패 · 단계 하락" if int(record.next) < int(record.old) else "강화 실패 · 단계 유지")
		m._text(title, Vector2(135, y + 141), 14, Color("b77c24") if ok else Color("81546e"), true, 230)
		m._text("+%d → +%d" % [int(record.old), int(record.next)], Vector2(135, y + 174), 20, v.active_style.ink, true, 220)
		var desc: String = "감기 +3% · 장력 증가 -2% · 판매가 +5%" if ok else ("보호권이 하락을 막았어요" if bool(record.protected) else "낚싯대는 파괴되지 않아요")
		m._text(desc, Vector2(135, y + 199), 9, v.active_style.ink, true, 232)
		_button(v, m, Rect2(64, y + 216, 142, 28), "확인", "forge_done")
