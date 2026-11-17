extends RefCounted

const LIMIT: = [5, 8, 10, 13, 16, 20]
const SOUL_COEF: = [1, 2, 4, 8, 16, 32]
const HIT_AT := [0.60, 1.42, 2.48]
const HIT_SOUNDS := ["forge_light", "forge_medium", "forge_heavy"]
const WORK_TIME := 2.56
const REVEAL_TIME := 1.04
const TOTAL_FRAMES := 216
const FAILURE_START := 148
const FRAME_SIZE := 128
var sheets: Array[Texture2D] = []
var phase: = ""
var elapsed: = 0.0
var strikes: = 0
var use_protection: = false
var record: = {}
func setup() -> void:
	for i in 9:
		sheets.append(load("res://art/forge138/strike_%02d.webp" % i))
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
func process(m, dt: float) -> void:
	if phase == "":
		return
	elapsed += maxf(0.0, dt)
	if phase == "working":
		var count: int = 0
		for i in HIT_AT.size():
			if elapsed >= float(HIT_AT[i]):
				count += 1
		if count > strikes:
			for i in range(strikes, count):
				m.play(HIT_SOUNDS[i])
				m.buzz([25 + 20 * i])
			strikes = count
		if elapsed >= WORK_TIME:
			_reveal(m)

func _reveal(m) -> void:
	if phase != "working":
		return
	phase = "result"
	elapsed = 0.0
	m.forge_seen = true
	m._save_game()
	m.play("forge_success" if bool(record.success) else "forge_failure")
	m.buzz([40, 20, 75] if bool(record.success) else [80, 25, 55])
func dismiss(m) -> void :
	phase = "";record = {};m.forge_pending = {};m._save_game()
func act(v, m, a: String) -> bool:
	match a:
		"forge": start(m);return true
		"forge_skip":
			if phase == "working" and m.forge_seen: _reveal(m)
			return true
		"forge_done":
			if phase == "result" and elapsed >= REVEAL_TIME: dismiss(m)
			return true
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
	preload("res://addons/reservoir/forge_layout.gd").new().draw_upgrade(v,m,r,y+3)
func _cinematic(v, m, _r: Rect2, y: float) -> void:
	var t: float = elapsed if phase == "working" else WORK_TIME + elapsed
	var frame := clampi(floori(t * 60.0), 0, TOTAL_FRAMES - 1)
	if not bool(record.success) and frame >= FAILURE_START:
		frame += TOTAL_FRAMES - FAILURE_START
	var cell := Vector2i(frame % 8, (frame % 32) / 8)
	var scene := Rect2(71, y + 1, FRAME_SIZE, FRAME_SIZE)
	m._ui_texture_rect_region(sheets[frame / 32], scene, Rect2(Vector2(cell * FRAME_SIZE), Vector2(FRAME_SIZE, FRAME_SIZE)))
	if phase == "working":
		m._text("망치 3타격 · 빛 응축", Vector2(135, y + 140), 12, Color("f4d48a"), true, 230)
		m._ui_rect(Rect2(39, y + 154, 192, 9), Color("382c2c"))
		m._ui_rect(Rect2(40, y + 155, 190 * minf(1.0, elapsed / WORK_TIME), 7), Color("ffd36b"))
		m._text("+%d → +%d" % [int(record.old), int(record.old) + 1], Vector2(135, y + 191), 16, v.active_style.ink, true, 220)
		if m.forge_seen:
			_button(v, m, Rect2(91, y + 213, 88, 25), "빠르게 보기", "forge_skip")
	else:
		var ok: bool = bool(record.success)
		if ok and t >= 3.01:
			m._text("+%d" % int(record.next), scene.position + Vector2(64, 76), 16, Color("fff3aa"), true, 58)
		var title: String = "강화 성공!" if ok else ("강화 실패 · 단계 하락" if int(record.next) < int(record.old) else "강화 실패 · 단계 유지")
		m._text(title, Vector2(135, y + 141), 14, Color("edba4b") if ok else Color("b17b81"), true, 230)
		m._text("+%d → +%d" % [int(record.old), int(record.next)], Vector2(135, y + 174), 20, v.active_style.ink, true, 220)
		var desc: String = "감기·제어 성능↑ · 판매가 +5%" if ok else ("보호권이 하락을 막았어요" if bool(record.protected) else "낚싯대는 파괴되지 않아요")
		m._text(desc, Vector2(135, y + 199), 9, v.active_style.ink, true, 232)
		if elapsed >= REVEAL_TIME:
			_button(v, m, Rect2(64, y + 216, 142, 28), "확인", "forge_done")
