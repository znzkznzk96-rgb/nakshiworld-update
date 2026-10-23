extends "res://main.gd"
func _draw_pixel_halo(quads: Array, tex: Texture2D, grade: int, t: float) -> void:
	if grade <= 0: return
	for layer in range(3, 0, -1):
		var pulse: float = fposmod(t / 1500.0, 1.0)
		var radius: float = roundf(1.0 + (layer - 1 + pulse) * (1.0 + grade * 0.45))
		var opacity: float = (0.27 if layer == 1 else 0.11 if layer == 2 else 0.035) * (1.0 - pulse * 0.35)
		for i in 8:
			var offset := Vector2(cos(i * TAU / 8), sin(i * TAU / 8)).round() * radius
			var color := _aura_col(grade, t, opacity, i)
			for qd in quads:
				var vertices := PackedVector2Array()
				for point in qd[0]: vertices.append(point + offset)
				_fish_quad([vertices, qd[1]], color, tex)
	# Bright sparse pixel sparks outside the outline; body is drawn afterwards.
	var count: int = 3+grade*2
	var center:=Vector2.ZERO
	for point in quads[0][0]: center+=point/4.0
	var tail: Vector2=(quads[-1][0][1]+quads[-1][0][2])/2.0
	var mid: Vector2=(center+tail)/2.0
	var length: float=center.distance_to(tail)
	for i in count:
		var angle: float=i*TAU/count+t/2400.0
		var point: Vector2=mid+Vector2(cos(angle)*(length*0.58+6),sin(angle)*(length*0.34+5))
		if not ui_demo: point.y+=oy
		var color:=_aura_col(grade,t,0.65+0.25*sin(t/220.0+i),i)
		_ui_rect(Rect2(point,Vector2(1.5,1.5)),color)
		if grade>=3 and i%3==0:
			_ui_rect(Rect2(point+Vector2(-1,0.5),Vector2(3.5,0.5)),color)
			_ui_rect(Rect2(point+Vector2(0.5,-1),Vector2(0.5,3.5)),color)


func _draw_action_wake(_c: Vector2, _l: float, _h: float, _f: float, _b: String, _t: float) -> void: pass
