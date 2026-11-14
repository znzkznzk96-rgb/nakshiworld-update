extends RefCounted

const LIMIT: = [5, 8, 10, 13, 16, 20]
const SOUL_COEF: = [1, 2, 4, 8, 16, 32]
# Three blows, a 0.15 s held beat, then 0.82 s of non-skippable reveal.
const HIT_AT: = [0.58, 1.40, 2.22]
const WORK_TIME: = 2.70
const HOLD_TIME: = 0.15
const REVEAL_TIME: = 0.82
const SMITH_CYCLE: = 0.82
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
				m.play("hammer", -5.5 + float(i) * 1.5, 0.88 + float(i) * 0.09)
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
	m.play("catch" if bool(record.success) else "snap", -2.0 if bool(record.success) else -5.0)
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
func _pixel(m, p: Vector2, sz: Vector2, col: Color) -> void:
	m._ui_rect(Rect2(p.round(), sz), col)

func _burst(m, origin: Vector2, age: float, duration: float, radius: float, tint: Color, rays: int = 12) -> void:
	if age < 0.0 or age >= duration:
		return
	var progress: float = age / duration
	var light: Color = tint
	light.a = (1.0 - progress) * 0.97
	for i in rays:
		var angle: float = TAU * float(i) / float(rays) + float(i % 3) * 0.14
		var direction: Vector2 = Vector2(cos(angle), sin(angle))
		var distance: float = 3.0 + radius * progress * (0.75 + 0.15 * float(i % 3))
		var p: Vector2 = origin + direction * distance
		_pixel(m, p, Vector2(3 if i % 4 == 0 else 2, 2), light)
		if i % 3 == 0:
			_pixel(m, p - direction * 5.0, Vector2(2, 2), Color(1.0, 0.99, 0.87, light.a * 0.65))

func _charge(m, focus: Vector2, t: float) -> void:
	var hit_count: int = 0
	for at in HIT_AT:
		if t >= float(at): hit_count += 1
	var intensity: float = clampf(0.22 + float(hit_count) * 0.18 + t / WORK_TIME * 0.22, 0.0, 0.98)
	var halo: Color = Color("ffd36b")
	halo.a = intensity * 0.32
	_pixel(m, focus + Vector2(-8, -4), Vector2(16, 8), halo)
	_pixel(m, focus + Vector2(-5, -8), Vector2(10, 16), halo)
	var core: Color = Color("fff8b5")
	core.a = intensity
	_pixel(m, focus + Vector2(-3, -2), Vector2(6, 4), core)
	for i in 16 + hit_count * 6:
		var angle: float = TAU * float(i) / float(16 + hit_count * 6)
		var distance: float = 9.0 + float(hit_count) * 4.0 + sin(t * 10.0 + i * 1.7) * 3.0
		var pos: Vector2 = focus + Vector2(cos(angle), sin(angle)) * distance
		var glint: Color = Color("54f1f2") if i % 4 == 0 else Color("ffe073")
		glint.a = intensity * (0.36 + 0.45 * absf(sin(t * 8.0 + i)))
		_pixel(m, pos, Vector2(2, 2), glint)
	for i in HIT_AT.size():
		_burst(m, focus, t - float(HIT_AT[i]), 0.24, 19.0 + i * 4.0, Color("fff19a") if i == 0 else Color("6bf7ff") if i == 1 else Color("ffdc71"), 10 + i * 2)
	# The last 0.15 seconds deliberately hold without moving particles.
	if t >= WORK_TIME - HOLD_TIME:
		_pixel(m, focus + Vector2(-11, -1), Vector2(22, 2), Color("fff3b3"))
		_pixel(m, focus + Vector2(-1, -11), Vector2(2, 22), Color("fff3b3"))

func _result_fx(m, scene: Rect2, focus: Vector2, ok: bool) -> void:
	var t: float = elapsed
	if ok:
		if t < 0.16:
			m._ui_rect(scene.grow(-1), Color(1.0, 0.95, 0.76, 0.64 * (1.0 - t / 0.16)))
		# A stepwise bolt follows the unbroken rod, not the outer UI frame.
		if t < 0.58:
			var alpha: float = 1.0 - t / 0.58
			for i in 30:
				var f: float = float(i) / 29.0
				var p: Vector2 = (focus + Vector2(-44, 27)).lerp(focus + Vector2(39, -24), f)
				p += Vector2([0, 2, -2, 1, -1][i % 5], [1, -1, 2, -2][i % 4])
				_pixel(m, p, Vector2(3, 3 if i % 4 == 0 else 2), Color(0.78, 0.99, 1.0, alpha))
			_burst(m, focus, t, 0.65, 48.0, Color("9ffaff"), 16)
			_burst(m, focus, t - 0.08, 0.62, 39.0, Color("ffe279"), 14)
		if t < REVEAL_TIME:
			m._text("+%d" % int(record.next), focus + Vector2(34, -20 - 4 * sin(t * 5.0)), 16, Color("fff1a0"), true, 53)
	else:
		if t < 0.18:
			m._ui_rect(scene.grow(-1), Color(0.92, 0.55, 0.40, 0.42 * (1.0 - t / 0.18)))
		_burst(m, focus, t, 0.22, 22.0, Color("f6b878"), 13)
		# Smoke curls upward and fades; the rod and anvil stay intact.
		for i in 11:
			var age: float = t - float(i % 4) * 0.048
			if age < 0.0 or age >= 0.83:
				continue
			var drift: float = sin(float(i) * 2.3 + age * 2.8) * (4.0 + age * 7.0)
			var p: Vector2 = focus + Vector2(-16 + float(i % 6) * 6.0 + drift, -2 - age * (23.0 + float(i % 3) * 9.0))
			var smoke: Color = Color("161b26") if i % 2 == 0 else Color("55505d")
			smoke.a = (1.0 - age / 0.83) * 0.86
			_pixel(m, p, Vector2(7 if i % 3 == 0 else 5, 5 if i % 3 == 0 else 4), smoke)
		for i in 5:
			var cinder_age: float = t - float(i) * 0.04
			if cinder_age >= 0.0 and cinder_age < 0.3:
				var p: Vector2 = focus + Vector2(-12 + i * 6, 6 + cinder_age * 15.0)
				_pixel(m, p, Vector2(2, 2), Color(0.98, 0.47, 0.24, 1.0 - cinder_age / 0.3))

func _cinematic(v, m, r: Rect2, y: float) -> void:
	var scene: Rect2 = Rect2(39, y + 5, 192, 112)
	m._ui_rect(scene, Color("211d24"))
	var frame: int = 9
	if phase == "working":
		frame = clampi(int(fposmod(elapsed, SMITH_CYCLE) * 13.0 / SMITH_CYCLE), 0, 12)
		if elapsed >= WORK_TIME - HOLD_TIME: frame = 9
	m._ui_texture_rect_region(animation.rod_sheet, scene, Rect2(frame * 192, 0, 192, 112))
	m.ui_commands.append(["rotated_texture", v.rods[int(record.rod)], scene.position + Vector2(112, 74), PI / 4])
	var focus: Vector2 = scene.position + Vector2(110, 72)
	if phase == "working":
		_charge(m, focus, minf(elapsed, WORK_TIME))
		m._text("망치 3타격 · 빛 응축", Vector2(135, y + 140), 12, Color("f4d48a"), true, 230)
		m._ui_rect(Rect2(39, y + 154, 192, 9), Color("382c2c"))
		m._ui_rect(Rect2(40, y + 155, 190 * minf(1.0, elapsed / WORK_TIME), 7), Color("ffd36b"))
		m._text("+%d → +%d" % [int(record.old), int(record.old) + 1], Vector2(135, y + 191), 16, v.active_style.ink, true, 220)
		if m.forge_seen:
			_button(v, m, Rect2(91, y + 213, 88, 25), "빠르게 보기", "forge_skip")
	else:
		var ok: bool = bool(record.success)
		_result_fx(m, scene, focus, ok)
		var title: String = "강화 성공!" if ok else ("강화 실패 · 단계 하락" if int(record.next) < int(record.old) else "강화 실패 · 단계 유지")
		m._text(title, Vector2(135, y + 141), 14, Color("edba4b") if ok else Color("b17b81"), true, 230)
		m._text("+%d → +%d" % [int(record.old), int(record.next)], Vector2(135, y + 174), 20, v.active_style.ink, true, 220)
		var desc: String = "감기·제어 성능↑ · 판매가 +5%" if ok else ("보호권이 하락을 막았어요" if bool(record.protected) else "낚싯대는 파괴되지 않아요")
		m._text(desc, Vector2(135, y + 199), 9, v.active_style.ink, true, 232)
		if elapsed >= REVEAL_TIME:
			_button(v, m, Rect2(64, y + 216, 142, 28), "확인", "forge_done")
