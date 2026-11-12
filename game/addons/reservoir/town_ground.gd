extends RefCounted

const BOARDING_OFFSET := 55.0
const LAND_START := 288
const LAND_TILE_WIDTH := 360
const TIMBER := preload("res://art/town/timber_quay.png")
const LAND := preload("res://art/town/village_shore.png")
const LAND_EDGE := preload("res://art/town/village_shore_edge.png")

static func deck_y(_x: float) -> float:
	return 22.0

static func draw(m, v, origin: Vector2) -> void:
	var top := origin.round() + Vector2(0, -3)
	if v._visible(150, 150):
		m.draw_texture_rect(TIMBER, Rect2(top, Vector2(300, 66)), false)
	for x in range(LAND_START, v.MAP_W, LAND_TILE_WIDTH):
		var width := mini(LAND_TILE_WIDTH, v.MAP_W - x)
		if not v._visible(x + width * 0.5, width * 0.5 + 1):
			continue
		var terrain := LAND_EDGE if x == LAND_START else LAND
		var size := Vector2(width, 65)
		m.draw_texture_rect_region(terrain, Rect2(top + Vector2(x, 0), size),
			Rect2(Vector2.ZERO, Vector2(terrain.get_width() * width / float(LAND_TILE_WIDTH), terrain.get_height())))

static func front(_n: Node2D) -> void:
	pass
