extends RefCounted

const BOARDING_OFFSET := 55.0
const LAND_START := 288
const LAND_TILE_WIDTH := 360
const TIMBER := preload("res://art/town/timber_quay.png")
const LAND := preload("res://art/town/village_shore.png")
const LANDING := preload("res://art/town/pier_landing.png")

static func deck_y(_x: float) -> float:
	return 22.0

static func draw(m, v, origin: Vector2) -> void:
	var top := origin.round() + Vector2(0, -3)
	if v._visible(150, 150):
		m.draw_texture_rect_region(TIMBER, Rect2(top, Vector2(264, 66)), Rect2(0, 0, 792, 198))
	if v._visible(306, 43):
		m.draw_texture_rect(LANDING, Rect2(top + Vector2(264, 0), Vector2(84, 66)), false)
	for x in range(LAND_START, v.MAP_W, LAND_TILE_WIDTH):
		var width := mini(LAND_TILE_WIDTH, v.MAP_W - x)
		if not v._visible(x + width * 0.5, width * 0.5 + 1):
			continue
		var terrain := LAND
		var offset := 60 if x == LAND_START else 0
		var size := Vector2(width - offset, 65)
		m.draw_texture_rect_region(terrain, Rect2(top + Vector2(x + offset, 0), size),
			Rect2(Vector2(offset * 3, 0), Vector2(size.x * 3, terrain.get_height())))

static func front(_n: Node2D) -> void:
	pass
