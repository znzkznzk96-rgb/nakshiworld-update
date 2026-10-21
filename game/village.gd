extends RefCounted

const MAP_W: = 1630
const MAP_H: = 480

const BUILD: = [
	["여객 선착장", "harbor", Rect2(0, -113, 220, 142), Vector2(95, -122)], 
	["어시장", "work", Rect2(370, -128, 128, 128), Vector2(434, -140)], 
	["낚시 상점", "up", Rect2(550, -132, 124, 132), Vector2(612, -144)], 
	["대장간", "forge", Rect2(720, -140, 150, 140), Vector2(795, -152)], 
	["수족관", "aqua", Rect2(920, -148, 208, 148), Vector2(1024, -160)], 
	["마을 회관", "hall", Rect2(1190, -145, 140, 145), Vector2(1260, -157)], 
	["어류 박물관", "museum", Rect2(1410, -128, 128, 128), Vector2(1474, -140)]
]
const CHIEF_POS: = Vector2(1270, 27)
const CHIEF_TALK: = ["배가 주민들을 태워 오고 있다네.", "회관에서 어장을 관리해 보게!", "수족관에 물고기를 전시하면 수입이 늘지."]
const GREET: = {"up": "장비와 미끼를 챙겨요!", "bait": "오늘은 어떤 미끼를 쓸까요?", "aqua": "우리 물고기를 보러 와요!", "museum": "만난 물고기를 기록해요!", "work": "판매와 손질을 맡겨요!", "harbor": "더 큰 배로 손님을 맞아요!", "hall": "어장을 키워 더 오래 낚시해요!", "forge": "낚싯대를 고르고 정비해요!"}
const KEEPER: = {"up": "k_up", "bait": "k_bait", "aqua": "k_aqua", "museum": "k_museum", "work": "k_work", "harbor": "k_work", "hall": "chief", "forge": "k_up"}
const PARTS: = [["float", "찌", "★2 입질 해금", 165], ["hook", "바늘", "★3 입질 해금", 330], ["line", "줄", "★4 입질 해금", 594], ["reel", "릴", "모든 ★ · 주인 자격", 990]]
const SOUL_STAR: = [1, 2, 4, 8, 20]
const SOUL_GRADE: = [1, 2, 4, 8, 16]
const UPGRADE_COST: = [160, 420, 1000, 2400, 6000]
const FORGE_COST: = [120, 360, 900, 2100, 4800]
const POND_CAP_COST: = [300, 800, 1800, 4200, 9000]
const POND_REGEN_COST: = [250, 700, 1600, 3800, 8000]
const ROD_NAME: = ["대나무 낚싯대", "카본 낚싯대", "원투 낚싯대", "선상 낚싯대", "심해 낚싯대", "은하 낚싯대"]
const ROD_COST: = [0, 2000, 35000, 700000, 4500000, 19000000]
var bundle_preview = preload("res://addons/reservoir/bundle_preview.gd").new()
var commerce = preload("res://addons/reservoir/commerce.gd").new()
var enhancement = preload("res://addons/reservoir/enhancement.gd").new()
var art: = {}
var rods: = []
var tex: = {}
var people_frames: = []
var tool_icons: = {}
var shop_styles: = {}
var active_style: = {}
var sb_plaque: StyleBoxTexture
var res: = []
var locals: = []
var foreground: Node2D
var ground: = preload("res://addons/reservoir/town_ground.gd").new()
var visitors: = preload("res://addons/reservoir/visitors.gd").new()
var chief_say: = ""
var chief_t: = -10.0
var enter_t: = 0.0
var shop: = ""
var tab: = "sell"
var forge_tab: = "rods"
var rod_page: = 0
var pick_slot: = -1
var aqua_manage: = false
var aqua_page: = 0
var aqua_pick_page: = 0
var aqua_selected: = -1
var aqua_notice: = ""
var aquarium: = preload("res://addons/reservoir/aquarium_view.gd").new()
var rects: = {}
var map_y: = 0.0
var camera_x: = 0.0
var zoom: = 1.0
var fingers: = {}
var pinching: = false
var pinch_distance: = 1.0
var pinch_zoom: = 1.0
var last_pinch: = -1000
var velocity: = 0.0
var pointer: = false
var dragging: = false
var down: = Vector2.ZERO
var last_pointer: = Vector2.ZERO
var ferry_clock: = 0.0
var arrival_clock: = 0.0
var arrival_count: = 0
var arrived: = false
var town_time: = 0.0

func setup() -> void :
	visitors.setup()
	enhancement.setup()
	for n in ["weight", "stock", "bridge", "smith", "smoke", "mountains", "forest", "water"]:
		art[n] = load("res://art/refresh52/%s.png" % ({"mountains": "ridge_native", "forest": "forest_native", "water": "water_native", "bridge": "bridge_joined"}.get(n, n)))
	art["terminal"] = load("res://art/refresh52/terminal_joined.png")
	art["water_near"] = load("res://art/refresh52/water_near.png")
	for n in ["cloud_wisp", "cloud_cumulus", "cloud_far"]: art[n] = load("res://art/atmosphere/%s.png" % n)
	for n in ["bamboo", "carbon", "surf", "boat", "deep", "galaxy"]:
		rods.append(load("res://art/refresh52/rod_%s.png" % n))
	for n in ["plaque", "chief", "res1", "res2", "k_up", "k_bait", "k_aqua", "k_museum", "k_work", "i_worm", "i_soul", "i_stringer", "i_bucket", "i_net", "i_ice"]:
		tex[n] = load("res://art/village/%s.png" % n)
	for n in ["market", "tackle", "forge", "aquarium", "hall", "museum", "dock", "bridge", "boat", "tree", "lamp", "hedge", "bench", "backdrop"]:
		tex[n] = load("res://art/town/%s.png" % n)
	for person in 6:
		var frames = []
		for frame in 4: frames.append(load("res://art/people/resident_%d_%d.png" % [person, frame]))
		people_frames.append(frames)
	var keeper_ids: = {"chief": 4, "k_up": 1, "k_bait": 0, "k_aqua": 3, "k_museum": 5, "k_work": 1, "res1": 0, "res2": 1}
	for n in keeper_ids: tex[n] = people_frames[keeper_ids[n]][1]
	tex.chief = visitors.textures[6].idle
	for n in ["rod", "float", "hook", "line", "reel", "worm", "soul", "stringer", "bucket", "net", "ice", "hammer", "boat", "hall", "book", "coin"]:
		tool_icons[n] = load("res://art/tools_clean/%s_24.png" % n)
	for n in preload("res://addons/reservoir/equipment_art.gd").NAMES:
		tool_icons[n] = preload("res://addons/reservoir/equipment_art.gd").icon(n, 24)
	tool_icons.ice = tool_icons.ice1
	tool_icons.coin = tool_icons.scale
	for k in GREET: shop_styles[k] = preload("res://addons/reservoir/shop_theme.gd").make(k)
	sb_plaque = StyleBoxTexture.new();sb_plaque.texture = tex.plaque
	sb_plaque.texture_margin_left = 10;sb_plaque.texture_margin_right = 10
	sb_plaque.texture_margin_top = 12;sb_plaque.texture_margin_bottom = 6

func capacity(m) -> int: return passengers(m)
func passengers(m) -> int: return 4 + 2 * m.boat_lv
func interval(m) -> float: return 60.0 - 4.0 * m.boat_lv
func multiplier(m) -> float: return float(mini(capacity(m), passengers(m))) / 4.0 * 60.0 / interval(m)
func enter(m) -> void :
	enter_t = m.ui_clock;shop = "";pick_slot = -1;pointer = false;velocity = 0;fingers.clear();pinching = false
	if locals.is_empty():
		for i in 3:
			var local: Dictionary = visitors.create(m, i)
			local.state = 3;local.wait = randf_range(0.1, 2.0);local.x = [470.0, 820.0, 1360.0][i]
			local.local_min = maxf(350.0, local.x - 100.0);local.local_max = minf(1510.0, local.x + 100.0);local.local_dir = -1 if i == 1 else 1
			locals.append(local)
	clamp_camera(m)
	if res.is_empty(): ferry_clock = 0;arrived = false

func clamp_camera(m) -> void :
	camera_x = clampf(camera_x, 135.0 / zoom - 135.0, MAP_W - 135.0 - 135.0 / zoom)
func set_zoom(m, value: float, focus_x: float = 135.0) -> void :
	var world_focus: = camera_x + 135 + (focus_x - 135) / zoom
	zoom = clampf(value, 0.65, 1.6)
	camera_x = world_focus - 135 - (focus_x - 135) / zoom
	clamp_camera(m);velocity = 0
func screen_to_map(m, p: Vector2) -> Vector2:
	var o = map_origin(m, m.get_viewport_rect().size.y)
	var anchor: = Vector2(135, map_y)
	return (p - anchor) / zoom + anchor - o
func _visible(x: float, margin: float = 80.0) -> bool:
	return absf(x - camera_x - 135) < 135.0 / zoom + margin

func input_event(m, e: InputEvent) -> bool:
	if shop != "" or m.market_open or m.settings_open or m.lesson_open or m.title_open or not m.trans.is_empty(): return false
	if e is InputEventScreenTouch:
		if e.pressed: fingers[e.index] = e.position - Vector2(m.ox, 0)
		else: fingers.erase(e.index)
		if fingers.size() >= 2 and not m.menu_open:
			var values = fingers.values()
			pinch_distance = maxf(1, values[0].distance_to(values[1]));pinch_zoom = zoom
			pinching = true;pointer = false;dragging = true;velocity = 0
		if pinching:
			last_pinch = Time.get_ticks_msec()
			if fingers.is_empty(): pinching = false;m._save_game()
			return true
	if e is InputEventScreenDrag and fingers.has(e.index):
		fingers[e.index] = e.position - Vector2(m.ox, 0)
		if fingers.size() >= 2 and pinching:
			var values = fingers.values()
			set_zoom(m, pinch_zoom * values[0].distance_to(values[1]) / pinch_distance, (values[0].x + values[1].x) / 2)
			return true
	if e is InputEventMouseButton or e is InputEventMouseMotion:
		if pinching or Time.get_ticks_msec() - last_pinch < 200: return true
	if e is InputEventMouseButton and e.pressed and e.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		set_zoom(m, zoom + (0.1 if e.button_index == MOUSE_BUTTON_WHEEL_UP else -0.1), e.position.x - m.ox);return true
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = e.position - Vector2(m.ox, 0)
		if e.pressed:
			pointer = true;dragging = false;down = p;last_pointer = p;velocity = 0
		elif pointer:
			pointer = false
			if not dragging: m.press(p)
		return true
	if e is InputEventMouseMotion and pointer:
		var p: Vector2 = e.position - Vector2(m.ox, 0)
		if absf(p.x - down.x) > 5 and not m.menu_open: dragging = true
		if dragging:
			camera_x -= (p.x - last_pointer.x) / zoom;clamp_camera(m)
			velocity = - (p.x - last_pointer.x) * 18.0 / zoom
		last_pointer = p
		return true
	return false

func _walk_y(x: float) -> float:
	return ground.deck_y(x)

func process(m, dt: float) -> void :
	town_time += dt
	enhancement.process(m, dt)
	if not pointer and shop == "" and not m.menu_open:
		camera_x += velocity * dt;clamp_camera(m)
		velocity = move_toward(velocity, 0, 350 * dt)
	ferry_clock += dt
	if ferry_clock >= 7.0 and not arrived:
		arrived = true;arrival_count = mini(capacity(m), passengers(m));arrival_clock = town_time
		var free: = maxi(0, capacity(m) - res.size())
		for i in mini(arrival_count, free):
			res.append(visitors.create(m, i))
	if ferry_clock > interval(m): ferry_clock = 0;arrived = false
	var keep = []
	for r in res:
		var previous_state: int = r.state
		visitors.update(r, dt)
		if previous_state == 0 and r.state == 1 and m.aqua_rate() > 0.0:
			m.aqua_acc += m.aqua_rate() * interval(m) / 60.0 / maxf(1.0, float(arrival_count))
			var reward: int = int(m.aqua_acc)
			if reward > 0:
				r.reward = reward;r.reward_t = 2.2;m.gold += reward;m.aqua_acc -= reward;m._save_game()
		if r.state != 2 or r.x > 70: keep.append(r)
		else: visitors.remove(r)
	res = keep
	for local in locals: visitors.update(local, dt)

func map_origin(m, h: float) -> Vector2:
	map_y = roundf(clampf(h * 0.64, m.top_y + 230.0, h - m.bot_pad - 155.0))
	return Vector2( - roundf(camera_x), map_y)

func _sprite(m, n: String, p: Vector2, w: float = -1.0) -> void :
	var t: Texture2D = tex[n]
	if n == "chief": p.y += t.get_height() - float(visitors.textures[6].frames[0].foot)
	var sz: Vector2 = t.get_size() if w < 0 else t.get_size() * (w / t.get_width())
	var rect: = Rect2((p - Vector2(sz.x / 2, sz.y)).round(), sz.round())
	if n == "chief":
		for delta in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]: m.draw_texture_rect(t, Rect2(rect.position + delta, rect.size), false, Color("080706"))
	m.draw_texture_rect(t, rect, false)

func draw(m, h: float) -> void :
	var o = map_origin(m, h)
	var t: float = town_time
	if not is_instance_valid(foreground):
		foreground = Node2D.new();foreground.set_script(preload("res://addons/reservoir/village_foreground.gd"));foreground.z_index = 2;m.add_child(foreground)
	foreground.visible = m.scene == "village"
	foreground.position = Vector2(135, map_y) + (o - Vector2(135, map_y)) * zoom
	foreground.scale = Vector2.ONE * zoom
	foreground.queue_redraw()


	m.draw_rect(Rect2( - m.ox, 0, m.VW + 2 * m.ox, h), Color("7eb9cb"))
	for band in 24:
		m.draw_rect(Rect2( - m.ox, band * 18, m.VW + 2 * m.ox, 18), Color("59a5cf").lerp(Color("8bbec9"), band / 23.0))
	var shore: float = o.y - 22
	var ridge: Texture2D = art.mountains
	m.draw_texture(ridge, Vector2(roundf( - camera_x * 0.18 - 100), roundf(shore - 80)), Color(0.87, 0.95, 0.98, 1))
	var forest: Texture2D = art.forest
	var forest_x: float = - fposmod(camera_x * 0.32, 400)
	for copy in range(-1, 3):
		m.draw_texture(forest, Vector2(roundf(forest_x + copy * 400), roundf(shore - 79)), Color(0.79, 0.91, 0.89, 0.38))
	var water: Texture2D = art.water
	m.draw_rect(Rect2( - m.ox, shore, m.VW + 2 * m.ox, h - shore), Color("228fac"))
	var drift: float = sin(t * 0.36) * 1.7
	m.draw_texture(water, Vector2(roundf( - camera_x * 0.22 - 90 + drift), roundf(shore)), Color(0.85, 0.95, 0.98, 1))
	for row in ceili((h - shore - 110) / 46.0) + 1:
		var near_drift: float = sin(t * (0.42 + row * 0.02) + row) * 1.4
		m.draw_texture(art.water_near, Vector2(roundf( - camera_x * 0.22 - 90 + near_drift), roundf(shore) + 110 + row * 46), Color(0.7, 0.9, 0.96, 0.48))

	for i in 3:
		var tx: Texture2D = art[["cloud_wisp", "cloud_cumulus", "cloud_far"][i]]
		var xx: float = fposmod(i * 173 + t * (1.2 + i * 0.45) - camera_x * 0.07, 550) - 180
		m.draw_texture(tx, Vector2(roundf(xx), roundf(70 + i * 49)), Color(0.95, 0.98, 0.96, 0.5 - i * 0.08))
	var world_text_start: int = m.text_items.size()
	var zoom_anchor: = Vector2(135, o.y)
	m.draw_set_transform(zoom_anchor * (1.0 - zoom), 0, Vector2(zoom, zoom))


	for i in 3:
		var bx: float = fposmod(190.0 + i * 530.0 + t * 13.0, MAP_W + 40.0) - 20.0
		var by: float = 113.0 + i * 14.0 + sin(t * 1.4 + i) * 3.0
		m.draw_line(Vector2(bx - 4, by), Vector2(bx, by + 2), Color("344b50"), 1)
		m.draw_line(Vector2(bx, by + 2), Vector2(bx + 4, by), Color("344b50"), 1)

	ground.draw(m, self, o)
	m.draw_texture(art.terminal, (o + Vector2(0, -113)).round())
	m.draw_texture(art.bridge, (o + Vector2(220, -6)).round())
	var ferry_x: = lerpf(-110, 95, clampf(ferry_clock / 6.0, 0, 1))
	if ferry_clock > 15: ferry_x = 95 - (ferry_clock - 15) * 24
	_sprite(m, "boat", o + Vector2(ferry_x, 78 + roundf(sin(t * 1.8) * 1.2)), 122 + m.boat_lv * 4)
	for i in 3:
		var radius: float = 9 + fposmod(t * 6 + i * 9, 24)
		m.draw_arc(o + Vector2(ferry_x, 78), radius, 0, PI, 12, Color(0.72, 0.93, 0.89, 0.18), 1)
	for i in 5:
		var x: float = o.x + 18 + i * 43
		m.draw_line(Vector2(x - 5, o.y + 42 + sin(t * 1.5 + i)), Vector2(x + 7, o.y + 42 + sin(t * 1.5 + i)), Color(0.72, 0.92, 0.86, 0.3), 1)
	for x in [370.0, 885.0, 1370.0, 1575.0]:
		if _visible(x, 65):
			m.draw_rect(Rect2(o + Vector2(x - 9, 1), Vector2(18, 3)), Color(0.1, 0.16, 0.12, 0.3))
			_sprite(m, "tree", o + Vector2(x, 3))
	for x in [515.0, 1155.0]:
		if _visible(x, 65): _sprite(m, "hedge", o + Vector2(x, 0))
	var arts: = ["market", "tackle", "forge", "aquarium", "hall", "museum"]
	for i in 6:
		var b = BUILD[i + 1]
		if not _visible(b[2].get_center().x, b[2].size.x / 2 + 30): continue
		_sprite(m, arts[i], o + Vector2(b[2].get_center().x, 0))
		var c: Vector2 = o + b[3]
		var w: float = maxf(54, m._text_w(b[0], 10) + 16)
		if o.y + (c.y - o.y) * zoom > m.top_y + 146:
			m.draw_style_box(m.hud_reference_style, Rect2(c.x - w / 2, c.y - 10, w, 23))
			m._text(b[0], c + Vector2(0, 3), 10, Color("fff0d1"), true, w - 8)

		if i == 2:
			for n in 2:
				var age: float = fposmod(t * 0.16 + n * 0.5, 1.0)
				var pos: Vector2 = o + Vector2(b[2].get_center().x + sin(t * 0.4 + n) * 5, - b[2].size.y - 25 - age * 24)
				m.draw_texture(art.smoke, pos.round(), Color(0.85, 0.89, 0.88, (1 - age) * 0.28))
		if i == 3: _aquarium_life(m, o + Vector2(1024, 0), t)
	for x in [520.0, 1148.0, 1370.0]:
		if _visible(x, 40):
			_sprite(m, "lamp", o + Vector2(x, 48))
	for x in [695.0, 1355.0]:
		if _visible(x, 50): _sprite(m, "bench", o + Vector2(x, 52))
	for n in m.pond_cap_lv:
		var x: float = 400 + n * 245
		if _visible(x, 35): _sprite(m, "hedge", o + Vector2(x, 64), 38)

	for r in res + locals:
		visitors.sync(self, m, r, o)
		if r.state != 1 and _visible(r.x, 24):
			var p: Vector2 = o + Vector2(r.x, _walk_y(r.x) + r.lane)
			m.draw_rect(Rect2(p + Vector2(-7, -1), Vector2(14, 2)), Color(0.1, 0.15, 0.1, 0.22))
		if r.reward_t > 0.0 and _visible(r.x, 36):
			var reward_pos: Vector2 = o + Vector2(r.x, _walk_y(r.x) - float(r.height) - 8)
			m._text("+%d 비늘" % r.reward, reward_pos, 9, Color("ffe07a"), true, 82, true)
	if _visible(CHIEF_POS.x, 24):
		_sprite(m, "chief", o + CHIEF_POS)

	if _visible(100, 120):
		var c: Vector2 = o + Vector2(95, -122)
		if o.y + (c.y - o.y) * zoom > m.top_y + 146:
			m.draw_style_box(m.hud_reference_style, Rect2(c.x - 46, c.y - 10, 92, 23))
		m._text("여객 선착장", c + Vector2(0, 3), 10, Color("fff0d1"), true)
	m.draw_set_transform(Vector2.ZERO)
	for i in range(world_text_start, m.text_items.size()):
		m.text_items[i][1] = zoom_anchor + (m.text_items[i][1] - zoom_anchor) * zoom
		m.text_items[i][7] *= zoom

	if shop == "":
		m._ui_style_box(m.sb_chip, Rect2(8, m.top_y + 69, 254, 30))
		var status: = "방문객 %d/%d · 수익 ×%.2f" % [res.size(), capacity(m), multiplier(m)]
		m._text(status, Vector2(135, m.top_y + 88), 12, Color("513b29"), true, 236)
		if town_time - arrival_clock < 3 and arrival_count > 0:
			m._text("배 도착! 주민 %d명 하선" % arrival_count, Vector2(135, m.top_y + 150), 10, Color("fff0d1"), true, 240, true)

		var zy: float = m.top_y + 105
		m._text("두 손가락 확대·축소", Vector2(12, zy + 16), 9, Color("fff0d1"), false, 152, true)
		rects.zoom = []
		for i in 3:
			var zr: = Rect2(168 + i * 32, zy, 30, 24)
			m._ui_style_box(m.sb_btn, zr)
			m._text(["-", "%d" % roundi(zoom * 100), "+"][i], zr.position + Vector2(15, 16), 10, Color("382619"), true, 27)
			rects.zoom.append(zr)

func _aquarium_life(m, c: Vector2, t: float) -> void :
	if m.aqua_lv > 0:
		var w: float = m.aqua_lv * 8
		for side in [-1, 1]:
			var x: float = c.x - 104 - w if side < 0 else c.x + 104
			m.draw_rect(Rect2(x, c.y - 66, w, 66), Color("625039"))
			m.draw_rect(Rect2(x + 2, c.y - 61, w - 4, 52), Color("387b85"))
			m.draw_line(Vector2(x + w / 2, c.y - 60), Vector2(x + w / 2, c.y - 9), Color("c5bb8b"), 2)
	var centers: = [Vector2(-64, -37), Vector2(3, -77), Vector2(66, -37)]
	for i in 3:
		var center: Vector2 = c + centers[i]
		var origin: = c - Vector2(104, tex.aquarium.get_height())
		var shape: PackedVector2Array
		if i == 1:
			shape = PackedVector2Array([Vector2(79, 83), Vector2(82, 72), Vector2(91, 64), Vector2(106, 60), Vector2(122, 64), Vector2(132, 72), Vector2(136, 83)])
		else:
			var sx: = 0.0 if i == 0 else 130.0
			shape = PackedVector2Array([Vector2(25 + sx, 137), Vector2(25 + sx, 104), Vector2(28 + sx, 97), Vector2(34 + sx, 92), Vector2(40 + sx, 91), Vector2(48 + sx, 94), Vector2(54 + sx, 101), Vector2(54 + sx, 137)])
		for k in shape.size(): shape[k] += origin
		m.draw_colored_polygon(shape, Color("218eae"))
		for bubble in 2:
			var bp: Vector2 = center + Vector2(-5 + bubble * 9, 8 - fposmod(t * 3 + bubble * 6 + i * 3, 15))
			m.draw_rect(Rect2(bp.round(), Vector2(1, 2)), Color(0.7, 0.95, 0.95, 0.45))
		var fish = m.aqua[(i + floori(t / 5) * 3) % m.aqua.size()]
		if fish == null: continue
		var tx: Texture2D = m.fish_tex[int(fish.sp)]
		var region: Rect2i = m.fish_used[int(fish.sp)]
		var size: = Vector2(region.size) * minf(20.0 / region.size.x, 9.0 / region.size.y)
		var p: = center + Vector2(roundf(sin(t * 0.6 + i) * 3), sin(t + i) * 3)
		m.draw_texture_rect_region(tx, Rect2((p - size / 2).round(), size.round()), Rect2(region))

func _bubble(m, c: Vector2, s: String) -> void :
	var w = minf(m._text_w(s, 9) * 1.15 + 24, 250.0)
	var x = clampf(c.x - w / 2, 4, m.VW - 4 - w)
	m.draw_style_box(m.sb_chip, Rect2(roundf(x), roundf(c.y - 22), roundf(w), 22))
	m._text(s, Vector2(x + w / 2, c.y - 7), 9, Color("382619"), true, w - 8)


func draw_bottom(m, h: float) -> void :
	if shop != "": return
	var y: float = h - m.bot_pad - 99
	var br: = Rect2(52, y, 210, 34)
	rects.go = Rect2()
	m._draw_menu(y)
	var names: = ["처음", "중간", "끝"]
	var aims: = [0.0, MAP_W * 0.5 - 135.0 / zoom, float(MAP_W)]
	rects.nav = []
	for i in 3:
		var nr: = Rect2(8 + i * 85, y + 42, 79, 25)
		m._ui_style_box(m.sb_btn, nr)
		m._text(names[i], nr.position + Vector2(39, 17), 10, Color("382619"), true, 73)
		rects.nav.append([nr, aims[i]])
	m._text("좌우로 밀어 마을 둘러보기", Vector2(135, y - 9), 9, Color("fff0d1"), true, 248, true)
	var track: = Rect2(12, y - 4, 246, 2)
	m.draw_rect(track, Color("476363"))
	m.draw_rect(Rect2(track.position + Vector2(camera_x / MAP_W * 246, 0), Vector2(270.0 / MAP_W * 246, 2)), Color("e0c58a"))

func press(m, pos: Vector2) -> void :
	if shop != "": _shop_press(m, pos);return
	if rects.get("go", Rect2()).has_point(pos): m.start_trans("spots");return
	if m._menu_press(pos): return
	var zrects: Array = rects.get("zoom", [])
	for i in zrects.size():
		if zrects[i].has_point(pos):
			set_zoom(m, 1.0 if i == 1 else zoom + (-0.15 if i == 0 else 0.15));m._save_game();return
	for n in rects.get("nav", []):
		if n[0].has_point(pos): camera_x = n[1];clamp_camera(m);velocity = 0;return
	var lp: Vector2 = screen_to_map(m, pos)
	for b in BUILD:
		if b[2].has_point(lp) or Rect2(b[3] - Vector2(50, 12), Vector2(100, 25)).has_point(lp):
			open_shop(m, b[1]);return

func open_shop(m, k: String) -> void :
	aqua_manage = false;aqua_page = 0;aqua_pick_page = 0;aqua_selected = -1;aqua_notice = ""
	bundle_preview.legacy_dex=false;bundle_preview.selected=-1
	shop = k;tab = "sell";forge_tab = "rods";rod_page = 0;pick_slot = -1;m.play("ui", -8.0)


func draw_shop(m, h: float) -> void :
	if shop == "": return
	if shop=="museum" and not bundle_preview.legacy_dex:
		bundle_preview.draw(m,h);return
	var top: float = m.top_y + 78
	m.text_items = m.text_items.filter( func(it): return it[1].y < top)


	m._ui_rect(Rect2( - m.ox, 0, m.VW + 2 * m.ox, h), Color(0.04, 0.06, 0.1, 0.84))
	var panel_y: = maxf(top + 32.0, roundf(h * 0.5) - 190)
	var r = Rect2(8, panel_y, 254, minf(380, h - panel_y - 8))
	active_style = shop_styles[shop]
	m._ui_style_box(active_style.panel, r)
	var header: = Rect2(r.position + Vector2(5, 5), Vector2(r.size.x - 10, 39))
	m._ui_style_box(active_style.header, header)
	var badge: Texture2D = tool_icons[active_style.icon]
	m._ui_texture(badge, header.position + Vector2(7, 7))
	var title: String = ""
	for b in BUILD:
		if b[1] == shop: title = b[0]
	if shop == "bait": title = "미끼 상점"
	m._text(title, Vector2(header.get_center().x, header.position.y + 23), 14, Color("fff0d1"), true, header.size.x - 82)
	var cr: = Rect2(header.end.x - 28, header.position.y + 7, 22, 23)
	if shop != "forge" or not enhancement.busy(): m._ui_texture(m.icons.close, cr.position)
	rects = {"close": cr.grow(3), "panel": r, "rows": []}
	if shop=="museum":
		var back:=Rect2(82,r.position.y+46,106,24)
		m._ui_style_box(m.sb_btn,back);m._text("번들 보기",back.get_center()+Vector2(0,4),10,active_style.ink,true,92)
		rects.rows.append([back,"bundles"])
	else: m._text(GREET[shop], Vector2(135, r.position.y + 59), 9, active_style.ink, true, 232)
	var y: float = r.position.y + 78
	match shop:
		"up":
			for i in 3:
				var key: String = ["sell", "bait", "gear_sell"][i]
				var tr := Rect2(r.position.x + 12 + i * 78, r.position.y + 69, 74, 24)
				m._ui_style_box(active_style.header if tab == key else m.sb_btn, tr)
				m._text(["장비·보관통", "미끼", "팔기"][i], tr.get_center() + Vector2(0, 4), 9, Color("fff0d1") if tab == key else active_style.ink, true, 70)
				rects.rows.append([tr, "tab:" + key])
			y = r.position.y + 105
			if tab == "bait": _draw_bait(m, r, y)
			elif tab == "gear_sell": m.equipment.draw_shop(self, m, r, y)
			else: _draw_up(m, r, y)
		"bait": _draw_bait(m, r, y)
		"aqua": _draw_aqua(m, r, y)
		"museum": _draw_museum(m, r, y)
		"work": _draw_work(m, r, y)
		"harbor": _draw_growth(m, r, y, true)
		"hall": _draw_hall(m, r, y)
		"forge": _draw_forge(m, r, y)


func _short(m, s: String, size: int, width: float) -> String:
	if m._text_w(s, size) <= width: return s
	while s.length() > 1 and m._text_w(s + "..", size) > width: s = s.left(s.length() - 1)
	return s + ".."

func _row(m, r: Rect2, y: float, icon: Texture2D, name: String, desc: String, btn: String, price: int, enabled: bool, act: String) -> void :
	var cell: = Rect2(r.position.x + 11, y, r.size.x - 22, 36)
	m._ui_style_box(active_style.card, cell)
	if icon:
		var fi: int = m.fish_tex.find(icon)
		var box: = Rect2(cell.position + Vector2(4, 3), Vector2(30, 30))
		if fi >= 0:
			var src: Rect2 = Rect2(m.fish_used[fi])
			var sz: Vector2 = src.size * minf(30 / src.size.x, 26 / src.size.y)
			m._ui_texture_rect_region(icon, Rect2(box.get_center() - sz / 2, sz), src)
		else:
			if icon in rods: m._ui_texture(icon, cell.position + Vector2(3, 2))
			else: m._ui_texture_rect(icon, box)
	m._text(_short(m, name, 12, 121), cell.position + Vector2(37, 15), 12, active_style.ink, false, 121)
	m._text(_short(m, desc, 10, 121), cell.position + Vector2(37, 29), 10, Color("675c4b"), false, 121)
	var button: = Rect2(cell.end.x - 67, y + 4, 62, 28)
	m._ui_style_box(active_style.header if enabled else active_style.card, button)
	var color: = Color("fff0d1") if enabled else Color("817767")
	if price > 0:
		m._ui_texture_rect(m.icons.scale, Rect2(button.position + Vector2(4, 5), Vector2(18, 18)))
		m._text(m.spots.price_text(price), button.position + Vector2(41, 18), 10, color, true, 38)
	else: m._text(_short(m, btn, 10, 58), button.position + Vector2(31, 18), 10, color, true, 58)
	if enabled or (price > 0 and not commerce.quote(self, m, act).is_empty()): rects.rows.append([button, act])


func _draw_up(m, r: Rect2, y: float) -> void :
	y = m.region_shop.draw_parts(m, self, r, y)
	y += 2
	m._text("보관통", Vector2(r.position.x + 18, y + 6), 9, Color("6a4a2a"))
	y += 12
	var nx: int = m.equipment.bag_progress + 1
	if nx < m.BAG_CAP.size():
		var ic: Texture2D = tool_icons[preload("res://addons/reservoir/equipment_art.gd").container_name(nx)]
		_row(m, r, y, ic, m.BAG_NAME[nx], "%s → %s" % [m._wtxt(m.bag_cap()), m._wtxt(m.BAG_CAP[nx])], "", m.BAG_PRICE[nx], m.gold >= m.BAG_PRICE[nx], "bag")
	else:
		_row(m, r, y, tool_icons.ice5, m.BAG_NAME[m.bag_lv], "지금은 이게 최고예요", "최고", 0, false, "")

func _draw_bait(m, r: Rect2, y: float) -> void :
	m.region_shop.draw_bait(m, self, r, y)

func _draw_aqua(m, r: Rect2, y: float) -> void :
	aquarium.draw(self, m, r, y)


func _draw_museum(m, r: Rect2, y: float) -> void :
	var got: int = m.DEX.size()
	m._text("어종 %d/20 · 등급 %d/100" % [got, m.DEX.values().reduce(func(total, grades): return total+grades.size(),0)], Vector2(135, y + 6), 10, Color("382619"), true)
	m._text("목표: 전 어종 발견 · 어종을 눌러 최대어 보기",Vector2(135,y+19),8,Color("68533d"),true,230)
	y += 27
	var pitch: float = minf(60, floorf((r.end.y - y - 7) / 5.0))
	for i in 20:
		var cell: = Rect2(r.position.x + 14 + i % 4 * 57, y + floori(i / 4.0) * pitch, 54, pitch - 2)
		m._ui_style_box(m.sb_chip, cell)
		var name: String = m.FISH_NAME[i]; var known: bool = m.DEX.has(name)
		var image: = Rect2(cell.position + Vector2(5, 3), Vector2(44, 21))
		if known: m._ui_fish(i, image)
		else:
			var used: Rect2i = m.fish_used[i]
			var size: Vector2 = Vector2(used.size) * minf(44.0 / used.size.x, 21.0 / used.size.y)
			m._ui_texture_rect_region(m.fish_sil[i], Rect2(image.get_center() - size / 2, size), Rect2(used), Color("3a4946"))
		m.inventory.label(m, name if known else "???", Vector2(cell.get_center().x, cell.position.y + 33), 42, 8)
		var seen: Array = m.DEX.get(name, [])
		for g in 5: m._ui_rect(Rect2(cell.position + Vector2(8 + g * 8, pitch - 7), Vector2(6, 3)), m._aura_col(g, m.ui_clock * 1000, 1) if g in seen else Color(0.3, 0.25, 0.2, 0.25))
		if known: rects.rows.append([cell, "species:%d" % i])

func _draw_work(m, r: Rect2, y: float) -> void :
	var tabs = [["sell", "팔기"], ["clean", "손질"]]
	for i in 2:
		var tb = Rect2(r.position.x + 16 + i * 76, y, 72, 26)
		m.sb_btn.modulate_color = Color.WHITE if tab == tabs[i][0] else Color(0.7, 0.62, 0.55)
		m._ui_style_box(m.sb_btn, tb)
		m.sb_btn.modulate_color = Color.WHITE
		m._text(tabs[i][1], Vector2(tb.get_center().x, y + 17), 10, Color("513b29"), true, 70)
		rects.rows.append([tb, "tab:" + tabs[i][0]])
	y += 32
	m._ui_texture_rect(tool_icons.scale if tab == "sell" else tool_icons.soul, Rect2(r.position.x + 16, y - 3, 16, 16), false)
	m._text(("보유 비늘 %d" % m.gold) if tab == "sell" else ("물고기의 혼 %d" % m.souls), Vector2(r.position.x + 35, y + 9), 9, Color("382619"))
	y += 16
	var items: Array = m.bag_items()
	if items.is_empty(): m._text("보관통이 비었어요", Vector2(m.VW / 2.0, y + 40), 10, Color("6a4a2a"), true);return
	var total = 0
	var visible_rows: = mini(items.size(), maxi(1, floori((r.end.y - 58 - y) / 40)))
	for i in visible_rows:
		var f: Dictionary = items[i]
		var nm: String = m.FISH_NAME[int(f.sp)] + (" (어깨)" if f.get("shoulder", false) else "")
		var desc = "%s · %.1fcm" % [m.GRADE_N[int(f.grade)], float(f.len)]
		if tab == "sell":
			_row(m, r, y, m.fish_tex[int(f.sp)], nm, desc, "", int(f.price), true, "sell:%d" % i)
		else:
			_row(m, r, y, m.fish_tex[int(f.sp)], nm, desc, "혼 +%d" % soul_of(f), 0, true, "clean:%d" % i)
		y += 44
	for f in items: total += int(f.price)
	if items.size() > visible_rows: m._text("외 %d마리" % (items.size() - visible_rows), Vector2(m.VW / 2.0, y + 4), 9, Color("6a4a2a"), true)
	if tab == "sell":
		var b = Rect2(r.position.x + 30, r.end.y - 50, r.size.x - 60, 32)
		m._ui_style_box(m.sb_btn, b)
		m._text("모두 팔기  %d 비늘" % total, Vector2(b.get_center().x, b.position.y + 20), 11, Color("513b29"), true)
		rects.rows.append([b, "sellall"])

func soul_of(f: Dictionary) -> int:
	return SOUL_STAR[int(f.star)] * SOUL_GRADE[int(f.grade)]

func _draw_growth(m, r: Rect2, y: float, harbor: bool) -> void :
	var lv: int = m.boat_lv
	m._text("배 Lv.%d" % (lv + 1), Vector2(135, y + 8), 14, Color("382619"), true)
	y += 30
	m._text("한 번에 %d명 · %.0f초마다 입항" % [passengers(m), interval(m)], Vector2(135, y), 10, Color("382619"), true, 224)
	m._text("수족관 수익 배수 ×%.2f" % multiplier(m), Vector2(135, y + 40), 11, Color("376556"), true)
	y += 53
	if lv < 5:
		var desc: = "승선 +2명 · 간격 -4초"
		_row(m, r, y, tool_icons.boat, "배 확장", desc, "", UPGRADE_COST[lv], m.gold >= UPGRADE_COST[lv], "boat")
	else: _row(m, r, y, null, "최종 단계", "최고 레벨입니다", "완료", 0, false, "")
	m._text("배가 커질수록 더 많은 손님이 방문해요.", Vector2(135, y + 62), 9, Color("6a4a2a"), true, 224)
	m._text("수족관 수익과 마을 방문객에 반영돼요.", Vector2(135, y + 80), 9, Color("6a4a2a"), true, 224)

func _draw_hall(m, r, y: float) -> void :
	m._text("어장 최대량  %d마리" % roundi(m.pond_max()), Vector2(135, y + 8), 12, Color("382619"), true)
	m._text("현재 어장  %d마리" % roundi(m.pond_stock), Vector2(135, y + 26), 10, Color("376556"), true)
	y += 36
	if m.pond_cap_lv < 5:
		_row(m, r, y, m.fish_s2[0], "어장 규모 확장", "%d → %d마리" % [roundi(m.pond_max()), roundi(m.pond_max() + 20)], "", POND_CAP_COST[m.pond_cap_lv], m.gold >= POND_CAP_COST[m.pond_cap_lv], "pondcap")
	else:
		_row(m, r, y, m.fish_s2[0], "어장 규모 확장", "최대 단계입니다", "완료", 0, false, "")
	y += 43
	if m.pond_regen_lv < 5:
		_row(m, r, y, tool_icons.scale, "회복 시설 개선", "시간당 %d → %d마리" % [roundi(m.pond_recovery()), roundi(m.pond_recovery() + 10)], "", POND_REGEN_COST[m.pond_regen_lv], m.gold >= POND_REGEN_COST[m.pond_regen_lv], "pondregen")
	else:
		_row(m, r, y, tool_icons.scale, "회복 시설 개선", "최대 단계입니다", "완료", 0, false, "")
	m._text("낚시할 때마다 1마리 감소 · 쉬는 동안 회복", Vector2(135, y + 54), 9, Color("6a4a2a"), true, 224)
	m._text("어장이 줄면 높은 등급 물고기가 드물어져요.", Vector2(135, y + 71), 9, Color("6a4a2a"), true, 224)

func _draw_forge(m, r: Rect2, y: float) -> void :
	if enhancement.busy():
		enhancement.draw(self, m, r, y);return
	for i in 2:
		var tr: Rect2 = Rect2(r.position.x + 14 + i * 112, y, 108, 25)
		var selected: bool = (i == 0 and forge_tab == "rods") or (i == 1 and forge_tab == "upgrade")
		m._ui_style_box(active_style.header if selected else active_style.card, tr)
		m._text(["낚싯대", "정비 강화"][i], tr.get_center() + Vector2(0, 4), 10, Color("fff0d1") if selected else active_style.ink, true, 102)
		rects.rows.append([tr, "forgetab:" + ["rods", "upgrade"][i]])
	y += 31
	if forge_tab == "rods":
		var card_h: float=floorf((r.end.y-y-12)/3.0)-5
		for i in 6:
			var cell:=Rect2(r.position.x+12+(i%2)*117,y+floori(i/2.0)*(card_h+5),113,card_h)
			m._ui_style_box(active_style.card,cell)
			var owned: bool=i in m.equipment.rods
			var current: bool=i==m.rod_lv and m.equipment.rod_equipped
			m._ui_texture_rect(rods[i],Rect2(cell.position+Vector2(4,4),Vector2(26,26)),false)
			m._text(ROD_NAME[i],cell.position+Vector2(33,14),10,active_style.ink,false,76)
			m._text("+%d · 감기 +%d%%" % [int(m.rod_enh[i]),i*12],cell.position+Vector2(33,27),8,Color("68533d"),false,76)
			var buy:=Rect2(cell.position.x+4,cell.end.y-28,105,24)
			m._ui_style_box(m.sb_btn,buy)
			var caption: String="사용 중" if current else ("장착" if owned else "%s 비늘" % m.spots.price_text(ROD_COST[i]))
			m._text(caption,buy.get_center()+Vector2(0,4),10,active_style.ink,true,96)
			if owned and not current: rects.rows.append([buy,"equip:%d"%i])
			elif not owned and i<=m.rod_owned+1: rects.rows.append([buy,"rod:%d"%i])
			elif not owned: m._text("잠김",Vector2(cell.end.x-17,cell.position.y+40),8,Color("796b58"),true,30)

		return
	enhancement.draw(self, m, r, y)

func _shop_press(m, pos: Vector2) -> void :
	if shop=="museum" and not bundle_preview.legacy_dex:
		bundle_preview.press(m,pos);return
	m.play("ui")
	if enhancement.busy():
		for row in rects.get("rows", []):
			if row[0].has_point(pos): _act(m, row[1]);return
		return
	for row in rects.get("rows", []):
		if row[0].has_point(pos):
			if not commerce.request(self, m, row[1]): _act(m, row[1])
			return
	if rects.get("close", Rect2()).has_point(pos) or not rects.get("panel", Rect2()).has_point(pos):
		if pick_slot >= 0: pick_slot = -1
		elif shop == "aqua" and aqua_manage: aqua_manage = false
		else: shop = ""

func _act(m, a: String) -> void :
	if a=="bundles": bundle_preview.legacy_dex=false;return
	if m.equipment.act(m, a): return
	if enhancement.act(self, m, a): return
	if aquarium.act(self, m, a): return
	var k = a.split(":")
	var n = int(k[1]) if k.size() > 1 else 0
	match k[0]:
		"region": m.region_shop.region=clampi(n,0,5);return
		"baitselect":
			if m.region_shop.bait_unlocked(n) and m.region_shop.stock(m,n)>0: m.region_shop.selected_bait=n;m._save_game()
			return
		"rpart":
			var q: Dictionary=commerce.quote(self,m,a)
			if q.is_empty() or m.gold<q.price: return
			var slot: int=int(k[2]);var key: String=m.region_shop.part_key(n,slot)
			m.gold-=int(q.price);m.parts_owned.append(key)
			if key not in m.equipment.unlocked_parts: m.equipment.unlocked_parts.append(key)
			m.equipment.equip(m,"part:"+key,true);m.play("catch")
		"bait":
			var q: Dictionary=commerce.quote(self,m,a)
			if q.is_empty() or m.gold<q.price: return
			var count: int=int(k[2]);m.gold-=int(q.price)
			if n==0: m.bait+=count
			else: m.region_shop.stocks[n]+=count
			m.region_shop.selected_bait=n;m.play("ui")
		"species": m.inventory.open_species(n);return
		"open": open_shop(m, k[1]);return
		"boat":
			var lv: int = m.boat_lv
			if lv >= 5 or m.gold < UPGRADE_COST[lv]: return
			m.gold -= UPGRADE_COST[lv]
			m.boat_lv += 1
			m.play("catch");m.show_toast("배 확장 완료!")
		"pondcap":
			if m.pond_cap_lv >= 5 or m.gold < POND_CAP_COST[m.pond_cap_lv]: return
			m.gold -= POND_CAP_COST[m.pond_cap_lv];m.pond_cap_lv += 1
			m.play("catch");m.show_toast("어장 최대량이 늘었어요!")
		"pondregen":
			if m.pond_regen_lv >= 5 or m.gold < POND_REGEN_COST[m.pond_regen_lv]: return
			m.gold -= POND_REGEN_COST[m.pond_regen_lv];m.pond_regen_lv += 1
			m.play("catch");m.show_toast("어장 회복 시설 개선!")
		"rod":
			if n < 0 or n > m.rod_owned + 1 or n >= ROD_NAME.size() or n in m.equipment.rods or m.gold < ROD_COST[n]: return
			m.gold -= ROD_COST[n];m.equipment.rods.append(n);m.equipment.rod_equipped = true;m.rod_lv = n;m.rod_owned = maxi(m.rod_owned, n);m.play("catch");m.show_toast(ROD_NAME[n] + " 구매 완료!")
		"forgetab": forge_tab = k[1]
		"equip":
			m.equipment.equip(m, "rod:%d" % n, true)
		"part":
			var q: Dictionary = commerce.quote(self, m, a)
			if q.is_empty() or m.gold < q.price: return
			var p: Array = PARTS[n]
			m.gold -= p[3];m.parts_owned.append(p[0]);m.equipment.active_parts.append(p[0]);
			if p[0] not in m.equipment.unlocked_parts: m.equipment.unlocked_parts.append(p[0])
			m.show_toast("%s 장착!" % p[1], Color("ffd24a"));m.play("catch")
		"bag":
			var next: int = m.equipment.bag_progress + 1
			if next >= m.BAG_CAP.size() or m.gold < m.BAG_PRICE[next]: return
			m.gold -= m.BAG_PRICE[next];m.bag_lv = next;m.equipment.bag_progress = next;m.equipment.bags.append(next)
			m.show_toast(m.BAG_NAME[next] + "!", Color("ffd24a"));m.play("catch")
		"worm":
			if n not in [1, 10] or m.gold < n * 10: return
			m.gold -= n * 10;m.bait += n;m.play("ui")
		"tab": tab = k[1]
		"sell":
			var f: Dictionary = m.bag[n]
			m.gold += int(f.price);m.bag.remove_at(n);m.show_toast("+%d 비늘" % int(f.price), Color("ffd24a"));m.play("catch")
		"sellall": m.sell_all()
		"clean":
			var f: Dictionary = m.bag[n]
			m.souls += soul_of(f);m.bag.remove_at(n);m.show_toast("혼 +%d" % soul_of(f), Color("9fd8ff"));m.play("splash_s", -6.0)
	m.buzz(30)
	m._save_game()
