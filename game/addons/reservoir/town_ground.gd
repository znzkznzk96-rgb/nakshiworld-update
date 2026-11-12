extends RefCounted

const BOARDING_OFFSET := 55.0
const LAND_START := 288
const LAND_TILE_WIDTH := 360
const TIMBER := preload("res://art/town/timber_quay.png")
const LAND := preload("res://art/town/village_shore.png")
const LANDING := preload("res://art/town/pier_landing.png")

static func deck_y(_x: float) -> float:
	return 22.0

# Integer-height strips retain the original pixels; only submerged color/alpha changes.
static func wet_texture(m, texture: Texture2D, target: Rect2, source: Rect2, depth: int = 22, opacity: float = 1.0) -> void:
	var start := maxi(0, int(target.size.y) - depth)
	var ratio := source.size / target.size
	m.draw_texture_rect_region(texture, Rect2(target.position, Vector2(target.size.x, start)),
		Rect2(source.position, Vector2(source.size.x, start * ratio.y)), Color(1, 1, 1, opacity))
	for row in range(start, int(target.size.y)):
		var t := float(row - start) / maxf(1, depth - 1)
		var dark := sin(t * PI) * 0.24
		var tint := Color.WHITE.darkened(dark).lerp(Color("59afb8"), smoothstep(0.2, 1.0, t) * 0.48)
		tint.a = opacity * (1.0 - smoothstep(0.30, 1.0, t))
		m.draw_texture_rect_region(texture, Rect2(target.position + Vector2(0, row), Vector2(target.size.x, 1)),
			Rect2(source.position + Vector2(0, row * ratio.y), Vector2(source.size.x, ratio.y)), tint)

static func building_contact(m, texture: Texture2D, center: Vector2) -> void:
	# A shallow plinth, with its shadow on the path rather than a floating oval.
	var half := floorf(texture.get_width() * 0.36)
	for row in 4:
		m.draw_rect(Rect2(center + Vector2(-half - 3 + row, 7 + row), Vector2((half + 3 - row) * 2, 1)), Color(0.19, 0.14, 0.08, 0.20 - row * 0.035))
	m.draw_rect(Rect2(center + Vector2(-half, 2), Vector2(half * 2, 5)), Color("655447"))
	m.draw_rect(Rect2(center + Vector2(-half, 2), Vector2(half * 2, 1)), Color("ab9473"))
	m.draw_rect(Rect2(center + Vector2(-half + 1, 6), Vector2(half * 2 - 2, 1)), Color("493e33"))
	for x in range(int(-half + 12), int(half - 3), 17):
		m.draw_rect(Rect2(center + Vector2(x, 3), Vector2(1, 3)), Color("493e33"))

static func draw(m, v, origin: Vector2) -> void:
	var top := origin.round() + Vector2(0, -3)
	# Continuous land behind the irregular junction fills its transparent gaps.
	for x in range(LAND_START, v.MAP_W, LAND_TILE_WIDTH):
		var width := mini(LAND_TILE_WIDTH, v.MAP_W - x)
		if not v._visible(x + width * 0.5, width * 0.5 + 1):
			continue
		var terrain := LAND
		var offset := 0
		var size := Vector2(width - offset, 65)
		wet_texture(m, terrain, Rect2(top + Vector2(x + offset, 0), size),
			Rect2(Vector2(offset * 3, 0), Vector2(size.x * 3, terrain.get_height())))
	if v._visible(150, 150):
		wet_texture(m, TIMBER, Rect2(top, Vector2(264, 66)), Rect2(0, 0, 792, 198))
	if v._visible(306, 43):
		wet_texture(m, LANDING, Rect2(top + Vector2(264, 0), Vector2(72, 66)), Rect2(0, 0, 216, 198))
		for column in 6:
			wet_texture(m, LANDING, Rect2(top + Vector2(336 + column * 2, 0), Vector2(2, 66)),
				Rect2(216 + column * 6, 0, 6, 198), 22, 1.0 - smoothstep(0.0, 6.0, column + 1))

static func front(_n: Node2D) -> void:
	pass
