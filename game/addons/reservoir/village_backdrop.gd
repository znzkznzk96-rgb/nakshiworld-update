extends Node2D
## 마을 뒤 배경(하늘·산·물·구름)을 건물·배보다 뒤에 그리는 층. 물 부분에는 도트 반짝임 셰이더를 얹는다.
## 부모(main) 그리기보다 먼저 그려져서, 땅·건물·배·UI가 이 위를 그대로 덮는다.
var v                      # village
var s := {}                # 매 프레임 village.draw가 넘겨 주는 값: ox, vw, h, o, t, cam
var shimmer: ColorRect

func _init() -> void:
	show_behind_parent = true

func _ready() -> void:
	shimmer = ColorRect.new()
	shimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shimmer.color = Color.WHITE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://addons/reservoir/water_reflect.gdshader")
	shimmer.material = mat
	add_child(shimmer)

func _draw() -> void:
	if v == null or s.is_empty(): return
	var ox: float = s.ox;var vw: float = s.vw;var h: float = s.h;var o: Vector2 = s.o;var t: float = s.t;var cam: float = s.cam
	var art: Dictionary = v.art
	draw_rect(Rect2(-ox, 0, vw + 2 * ox, h), Color("7eb9cb"))
	for band in 24:
		draw_rect(Rect2(-ox, band * 18, vw + 2 * ox, 18), Color("59a5cf").lerp(Color("8bbec9"), band / 23.0))
	var shore: float = o.y - 22
	draw_texture(art.mountains, Vector2(roundf(-cam * 0.18 - 100), roundf(shore - 80)), Color(0.87, 0.95, 0.98, 1))
	draw_rect(Rect2(-ox, shore, vw + 2 * ox, h - shore), Color("228fac"))
	var drift: float = sin(t * 0.36) * 1.7
	v.life.water_texture(self, art.water, Vector2(roundf(-cam * 0.22 - 90 + drift), roundf(shore)), Color(0.85, 0.95, 0.98, 1), t, false)
	for row in ceili((h - shore - 110) / 46.0) + 1:
		var near_drift: float = sin(t * (0.42 + row * 0.02) + row) * 1.4
		v.life.water_texture(self, art.water_near, Vector2(roundf(-cam * 0.22 - 90 + near_drift), roundf(shore) + 110 + row * 46), Color(0.7, 0.9, 0.96, 0.18), t, true, row * 0.6)
	v.life.water_back(self, v, art.forest, shore, t)
	v.life.water_front(self, v, o, h, t)
	if shimmer != null:
		shimmer.position = Vector2(-ox, roundf(shore))
		shimmer.size = Vector2(vw + 2 * ox, maxf(0.0, h - roundf(shore)))
		var mat := shimmer.material as ShaderMaterial
		var vp: Vector2 = get_viewport_rect().size
		mat.set_shader_parameter("scroll", roundf(cam * 0.22))
		mat.set_shader_parameter("shore_v", (get_global_transform_with_canvas() * Vector2(0, roundf(shore))).y / vp.y)
		mat.set_shader_parameter("v_per_px", Vector2(1.0 / vp.x, 1.0 / vp.y))
		mat.set_shader_parameter("depth_px", maxf(60.0, h - shore))
	for i in 3:
		var tx: Texture2D = art[["cloud_wisp", "cloud_cumulus", "cloud_far"][i]]
		var xx: float = fposmod(i * 173 + t * (1.2 + i * 0.45) - cam * 0.07, 550) - 180
		draw_texture(tx, Vector2(roundf(xx), roundf(70 + i * 49)), Color(0.95, 0.98, 0.96, 0.5 - i * 0.08))
