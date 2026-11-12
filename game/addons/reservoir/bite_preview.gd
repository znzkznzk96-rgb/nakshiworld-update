extends RefCounted
# This adapter is used only before fighting. Source pixels and fight geometry are untouched.
var collecting := false
var quads: Array = []
var anchor_cache: Dictionary = {}
var anchor_opaque: Dictionary = {}
var mapping_valid := false
var image_sp := -1
var image: Image
var last_mouth := Vector2.ZERO
var last_target := Vector2.ZERO
var last_bounds := Rect2()
var last_length := 0.0

func mouth_uv(m, sp: int, seconds: float) -> Vector2:
	var rift: bool = m.rift_art.has_species(sp)
	var frame: int = m.rift_art.frame_index(sp, seconds) if rift else 0
	var key := "%d:%d" % [sp, frame]
	if anchor_cache.has(key): return anchor_cache[key]
	var texture: Texture2D = m.rift_art.texture(sp) if rift else m.fish_sil[sp]
	if image_sp != sp:
		image = texture.get_image();image_sp = sp
	var source: Rect2i = Rect2i(m.rift_art.source_rect(sp, seconds)) if rift else m.fish_used[sp]
	var left: bool = rift or m._fish_texture_u(sp, 0.0) < m._fish_texture_u(sp, 1.0)
	var start: int = source.position.x if left else source.end.x - 1
	var direction := 1 if left else -1
	var middle := source.position.y + source.size.y * 0.5
	var found := false
	var pixel := Vector2(source.get_center())
	# Search the forward body band, excluding the upper/lower fin tips.
	for broad in [false, true]:
		var y0 := source.position.y + (0 if broad else floori(source.size.y * 0.25))
		var y1 := source.end.y if broad else source.position.y + ceili(source.size.y * 0.75)
		for column in maxi(1, ceili(source.size.x * 0.28)):
			var x := start + column * direction
			var nearest := INF
			for y in range(y0, y1):
				if image.get_pixel(x, y).a > 0.65 and absf(y - middle) < nearest:
					nearest = absf(y - middle);pixel = Vector2(x + 0.5, y + 0.5);found = true
			if found: break
		if found: break
	var uv := pixel / texture.get_size()
	anchor_cache[key] = uv
	anchor_opaque[key] = found
	return uv

func projected_mouth(uv: Vector2) -> Vector2:
	mapping_valid = false
	for quad in quads:
		for ids in [[0, 1, 2], [0, 2, 3]]:
			var a: Vector2 = quad[1][ids[0]]
			var b: Vector2 = quad[1][ids[1]]
			var c: Vector2 = quad[1][ids[2]]
			var determinant := (b - a).cross(c - a)
			if absf(determinant) < 0.00000001: continue
			var wb := (uv - a).cross(c - a) / determinant
			var wc := (b - a).cross(uv - a) / determinant
			var wa := 1.0 - wb - wc
			if minf(wa, minf(wb, wc)) >= -0.0001:
				mapping_valid = true
				return quad[0][ids[0]] * wa + quad[0][ids[1]] * wb + quad[0][ids[2]] * wc
	return Vector2.ZERO

func draw(m, center: Vector2, t: float, face: float, alpha: float, pose: Dictionary, phase: float, target: Vector2, contact: float) -> void:
	var sp: int = m.S.sp
	var rift: bool = m.rift_art.has_species(sp)
	var source: Vector2 = m.rift_art.source_rect(sp, 0).size if rift else Vector2(m.fish_used[sp].size)
	var ratio := source.y / maxf(1, source.x)
	# One fixed scale per species/class across every frame and rotation. This bounds
	# tall bodies/fins as well as length; never fit each animation frame separately.
	last_length = m._bite_preview_length(m.S.size) / Vector2(1.0 + ratio * 0.3, ratio + 0.28).length()
	var actual_pose := pose.duplicate()
	if rift: actual_pose["tilt"] = float(actual_pose.get("tilt", 0.0)) * face
	quads.clear();collecting = true
	m._shadow_fish(center, m.S.star, 0, t, "swim", false, 1.0, actual_pose, phase, sp, face, alpha, last_length)
	collecting = false
	var mouth := projected_mouth(mouth_uv(m, sp, t / 1000.0))
	var shift := (target - mouth) * clampf(contact, 0, 1)
	last_mouth = mouth + shift;last_target = target
	var first := true
	for quad in quads:
		var points := PackedVector2Array()
		for point in quad[0]:
			var p: Vector2 = point + shift
			points.append(p)
			if first: last_bounds = Rect2(p, Vector2.ZERO);first = false
			else: last_bounds = last_bounds.expand(p)
		m._fish_quad([points, quad[1]], quad[2], quad[3])
