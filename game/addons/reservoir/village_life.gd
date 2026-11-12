extends RefCounted

# Decorative motion only. No global random calls or persistent/gameplay state.
# Pixel stepped wavelets: shadow trough, teal shoulder, broken pale crest.
# Positions use world coordinates so camera movement cannot make ripples swim.
static func crest(m, p: Vector2, width: float, strength: float, phase: float) -> void:
	var count := maxi(3, int(width / 4.0))
	for j in count:
		var u := float(j) / maxf(1, count - 1)
		var y := roundf(sin(u * PI) * 2.0 + sin(phase + u * 3.0) * 0.6)
		var q := (p + Vector2(j * 4, y)).round()
		var fade := strength * (0.35 + 0.65 * sin(u * PI))
		m.draw_rect(Rect2(q + Vector2(0, 2), Vector2(4, 2)), Color(0.03, 0.35, 0.46, fade * 0.38))
		m.draw_rect(Rect2(q + Vector2(0, 1), Vector2(4, 1)), Color(0.27, 0.73, 0.77, fade * 0.70))
		if j % 7 != 4:
			m.draw_rect(Rect2(q, Vector2(4, 1)), Color(0.72, 0.92, 0.85, fade))

static func ripple(m, center: Vector2, radius: float, alpha: float, phase: float) -> void:
	# Sparse elliptical arcs, never a solid outline or a full white ring.
	for side in 2:
		for j in 9:
			var a := PI * (0.08 + j * 0.105) + side * PI
			if (j + int(phase)) % 7 == 0: continue
			var p := (center + Vector2(cos(a) * radius, sin(a) * radius * 0.24)).round()
			m.draw_rect(Rect2(p + Vector2(0, 1), Vector2(3, 1)), Color(0.05, 0.39, 0.48, alpha * 0.45))
			m.draw_rect(Rect2(p, Vector2(2 + j % 2, 1)), Color(0.64, 0.88, 0.81, alpha))

static func water_texture(m, texture: Texture2D, origin: Vector2, tint: Color, t: float, near: bool, phase: float = 0.0) -> void:
	# Advect the existing pixel bands; integer offsets retain their original density.
	# Four-pixel strips bend the water pattern without filtering, stretching or blur.
	var height := texture.get_height()
	for row in range(0, height, 4):
		var amount := 4.0 if near else 1.5
		var speed := 0.9 if near else 0.48
		var offset := roundf(sin(t * speed + row * 0.12 + phase) * amount + sin(t * speed * 0.47 + row * 0.21) * amount * 0.35)
		var hh := mini(4, height - row)
		m.draw_texture_rect_region(texture, Rect2((origin + Vector2(offset, row)).round(), Vector2(texture.get_width(), hh)), Rect2(0, row, texture.get_width(), hh), tint)

static func water_back(m, v, _forest: Texture2D, shore: float, t: float) -> void:
	# Distant glints are smaller, slower and dimmer than the foreground swells.
	for i in 14:
		var x := fposmod(i * 73.0 - v.camera_x * 0.22 + t * 1.8, 430.0) - 65
		var y := shore + 9 + (i % 5) * 8
		var pulse := 0.5 + 0.5 * sin(t * 0.6 + i * 2.3)
		crest(m, Vector2(x, y), 10 + i % 7, 0.12 + pulse * 0.12, t + i)

static func water_front(m, v, o: Vector2, h: float, t: float) -> void:
	var rows := maxi(3, int((h - o.y - 74) / 26))
	for row in rows:
		var depth := float(row + 1) / rows
		for col in 4:
			var i := row * 4 + col
			var speed := 2.6 + depth * 3.4
			var x := fposmod(col * 103.0 + row * 39.0 - v.camera_x * 0.44 + t * speed, 430.0) - 65
			var y := o.y + 79 + row * 26 + sin(t * 0.7 + i * 1.7) * 1.5
			var cycle := 0.5 + 0.5 * sin(t * 0.75 + i * 2.7)
			crest(m, Vector2(x, y), 22 + i % 4 * 6 + depth * 10, (0.30 + depth * 0.18) * (0.55 + cycle * 0.45), t * 0.6 + i)

static func shore_contact(m, v, o: Vector2, t: float) -> void:
	# Broken surge patches track the wet rock foot, leaving dry stone untouched.
	for i in 46:
		var x := 348.0 + i * 28.0
		if not v._visible(x, 38): continue
		var age := fposmod(t * 0.19 + i * 0.381966, 1.0)
		var envelope := sin(age * PI)
		var y := 57.0 + sin(i * 1.73) * 2.0 - envelope * 2.0
		crest(m, o + Vector2(x - age * 3, y), 12 + i % 4 * 4, envelope * 0.62, i + age)
		if i % 3 == 0:
			crest(m, o + Vector2(x + 5, y + 5 + age * 2), 10 + age * 8, envelope * 0.18, i)
	# Two staggered spreading wakes around each pile, anchored to its wet foot.
	for x in [54.0, 153.0, 252.0]:
		if not v._visible(x, 34): continue
		for band in 2:
			var age := fposmod(t * 0.24 + x * 0.01 + band * 0.5, 1.0)
			ripple(m, o + Vector2(x, 59), 5 + age * 21, sin(age * PI) * 0.55, x + band)

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
	# Water hugs the visible hull in short interrupted swells rather than a cut line.
	for i in 7:
		var phase := t * 0.9 + i * 1.8
		var x := 12 + i * (width - 34) / 7
		crest(m, origin + Vector2(x, keel + 5 + sin(phase)), 15 + i % 3 * 4, 0.48 + sin(phase) * 0.14, phase)
	for end in [14.0, width - 16.0]:
		for band in 2:
			var age := fposmod(t * 0.22 + band * 0.5 + end * 0.003, 1.0)
			ripple(m, origin + Vector2(end, keel + 7), 7 + age * 22, sin(age * PI) * 0.35, end)

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
