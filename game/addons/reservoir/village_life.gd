extends RefCounted

# Decorative motion only. No global random calls or persistent/gameplay state.
static func water_back(m, v, forest: Texture2D, shore: float, t: float) -> void:
	var left := -fposmod(v.camera_x * 0.32, 400.0)
	# Broken, vertically reflected forest strips; the open water remains readable.
	for row in 14:
		var sway := roundf(sin(t * 0.55 + row * 0.7) * (1.0 + row * 0.09))
		for copy in range(-1, 3):
			m.draw_texture_rect_region(forest, Rect2(left + copy * 400 + sway, shore + row * 2, 400, 2),
				Rect2(0, forest.get_height() - 1 - row, 400, 1), Color(0.20, 0.48, 0.47, 0.16 * (1.0 - row / 14.0)))
	for i in 16:
		var x := fposmod(i * 53.0 - v.camera_x * 0.22 + t * 1.4, 370.0) - 50
		var y := shore + 7 + (i % 5) * 7
		m.draw_rect(Rect2(Vector2(x, y).round(), Vector2(8 + i % 8, 1)), Color(0.61, 0.87, 0.86, 0.09))

static func water_front(m, v, o: Vector2, h: float, t: float) -> void:
	for i in 22:
		var x := fposmod(i * 61.0 - v.camera_x * 0.44 + t * (2.3 + i % 3), 430.0) - 80
		var y := o.y + 83 + (i % 7) * maxf(12, (h - o.y - 150) / 7)
		var pulse := pow(maxf(0, sin(t * 0.65 + i * 2.1)), 10)
		m.draw_rect(Rect2(Vector2(x, y).round(), Vector2(9 + i % 11, 1)), Color(0.68, 0.91, 0.88, 0.05 + pulse * 0.17))
		if pulse > 0.7:
			m.draw_rect(Rect2(Vector2(x + 4, y - 1).round(), Vector2(1, 3)), Color(0.90, 1.0, 0.91, (pulse - 0.7) * 0.65))

static func shore_contact(m, v, o: Vector2, t: float) -> void:
	for i in 65:
		var x := i * 25.0 + 8
		if not v._visible(x, 30): continue
		var phase := t * 0.9 + i * 1.73
		var y := 53.0 + sin(i * 1.2) * 3 + sin(phase) * 1.4
		var amount := 0.10 + maxf(0, sin(phase)) * 0.12
		m.draw_rect(Rect2((o + Vector2(x, y)).round(), Vector2(9 + i % 9, 1)), Color(0.66, 0.88, 0.82, amount))
		m.draw_rect(Rect2((o + Vector2(x + 2, y + 2)).round(), Vector2(5 + i % 6, 1)), Color(0.17, 0.52, 0.57, amount * 0.7))
	# Ripples follow the actual dock piles rather than a full-width foam border.
	for x in [54.0, 153.0, 252.0]:
		if not v._visible(x, 30): continue
		for band in 2:
			var age := fposmod(t * 0.24 + x * 0.01 + band * 0.5, 1.0)
			var width := 6.0 + age * 13.0
			m.draw_line((o + Vector2(x - width, 62 + band * 2)).round(), (o + Vector2(x + width, 62 + band * 2)).round(), Color(0.67, 0.91, 0.87, (1.0 - age) * 0.17), 1)

static func hull(m, origin: Vector2, width: float, keel: float, t: float) -> void:
	for row in 5:
		var half := width * (0.40 - absf(row - 2) * 0.045)
		m.draw_rect(Rect2((origin + Vector2(width * 0.5 - half, keel + 16 + row)).round(), Vector2(half * 2, 1)), Color(0.04, 0.24, 0.30, 0.12 - absf(row - 2) * 0.025))
	# Visible deep hull: broad upper body, bevelled keel, then submerged dissolve.
	for row in 24:
		var depth := row / 23.0
		var inset := 8.0 + pow(depth, 1.5) * 18.0
		var color := Color("285c66").lerp(Color("143b49"), smoothstep(0, 0.65, depth))
		if row in [3, 8, 13]: color = color.lightened(0.08)
		color = color.lerp(Color("258e9f"), smoothstep(0.55, 1, depth) * 0.8)
		color.a = 1.0 - smoothstep(0.64, 1.0, depth)
		m.draw_rect(Rect2((origin + Vector2(inset, keel - 7 + row)).round(), Vector2(width - inset * 2, 1)), color)

static func hull_water(m, origin: Vector2, width: float, keel: float, t: float) -> void:
	for i in 11:
		var x := 17.0 + i * (width - 34.0) / 11.0
		var y := keel + 6.0 + roundf(sin(t * 1.1 + i * 0.8))
		var alpha := 0.16 + maxf(0, sin(t * 0.8 + i)) * 0.18
		m.draw_rect(Rect2((origin + Vector2(x, y)).round(), Vector2(8 + i % 4, 1)), Color(0.75, 0.94, 0.86, alpha))
	for end in [13.0, width - 21.0]:
		var age := fposmod(t * 0.23 + end * 0.03, 1.0)
		m.draw_rect(Rect2((origin + Vector2(end - age * 8, keel + 10 + age * 3)).round(), Vector2(9 + age * 8, 1)), Color(0.69, 0.92, 0.85, (1.0 - age) * 0.23))

static func foliage(m, texture: Texture2D, target: Rect2, t: float, phase: float) -> void:
	var canopy := floorf(target.size.y * 0.75)
	var source_cut := floorf(texture.get_height() * 0.75)
	var sway := roundf(sin(t * 0.62 + phase) * 0.85 + sin(t * 0.29 + phase) * 0.35)
	m.draw_texture_rect_region(texture, Rect2(target.position + Vector2(sway, 0), Vector2(target.size.x, canopy)), Rect2(0, 0, texture.get_width(), source_cut))
	m.draw_texture_rect_region(texture, Rect2(target.position + Vector2(0, canopy), Vector2(target.size.x, target.size.y - canopy)), Rect2(0, source_cut, texture.get_width(), texture.get_height() - source_cut))

static func building_life(m, kind: String, base: Vector2, t: float) -> void:
	# Tiny window/doorway activity, deliberately below sign/text areas.
	var phase := t * 0.5 + base.x * 0.017
	if kind == "market" or kind == "tackle":
		var glow := 0.045 + maxf(0, sin(phase)) * 0.055
		m.draw_rect(Rect2((base + Vector2(-24, -27)).round(), Vector2(4, 5)), Color(1.0, 0.77, 0.38, glow))
	if kind == "aquarium":
		for i in 2:
			var x := sin(t * 0.22 + i * PI) * 10.0
			m.draw_rect(Rect2((base + Vector2(-41 + x, -40 - i * 13)).round(), Vector2(3, 1)), Color(0.18, 0.60, 0.66, 0.23))

static func foreground(m, v, o: Vector2, t: float) -> void:
	# Sparse reeds rooted at the shore's margins; never across the walking path.
	for x in [357.0, 907.0, 1552.0, 1606.0]:
		if not v._visible(x, 28): continue
		var p := (o + Vector2(x, 56)).round()
		for blade in 4:
			var sway := roundf(sin(t * 0.85 + x + blade) * 1.2)
			var height := 6.0 + blade % 3 * 2.0
			m.draw_line(p + Vector2(blade * 2 - 3, 0), p + Vector2(blade * 2 - 4 + sway, -height), Color("426a4b"), 1)
			m.draw_rect(Rect2(p + Vector2(blade * 2 - 4 + sway, -height), Vector2(1, 2)), Color("77956a"))
