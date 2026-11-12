extends RefCounted

const BOARDING_OFFSET := 55.0
const TIMBER := preload("res://art/town/timber_quay.png")

static func deck_y(_x: float) -> float:
	return 22.0

static func draw(m, v, o: Vector2) -> void:
	var tile_width := TIMBER.get_width()
	for x in range(0, v.MAP_W, tile_width):
		var width := mini(tile_width, v.MAP_W - x)
		if not v._visible(x + width * 0.5, width * 0.5 + 1): continue
		var size := Vector2(width, TIMBER.get_height())
		m.draw_texture_rect_region(TIMBER, Rect2(o.round() + Vector2(x, -3), size), Rect2(Vector2.ZERO, size))

static func front(_n: Node2D) -> void:
	pass
