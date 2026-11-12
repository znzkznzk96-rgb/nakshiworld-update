extends RefCounted
static func paint(n: Node2D, commands: Array) -> void :
	for c in commands:
		match c[0]:
			"inline_text":
				var it:Array=c[1]
				var raster:=maxf(1.0,n.get_viewport_transform().get_scale().x)
				var pos:Vector2=(it[1]*raster).round()/raster
				var scale:float=it[7]
				var px:=maxi(1,roundi(it[5]*scale*raster))
				n.draw_set_transform(pos,0,Vector2.ONE/raster)
				n.draw_multiline_string(it[0],Vector2.ZERO,it[2],it[3],it[4]*scale*raster,px,-1,it[6])
				n.draw_set_transform(Vector2.ZERO)
			"transform": n.draw_set_transform(c[1], 0, c[2])
			"reset_transform": n.draw_set_transform(Vector2.ZERO)
			"rotated_texture":
				n.draw_set_transform(c[2], c[3]);n.draw_texture(c[1], - c[1].get_size() / 2);n.draw_set_transform(Vector2.ZERO)
			"texture": n.draw_texture_rect(c[1], c[2], c[3], c[4], c[5])
			"region": n.draw_texture_rect_region(c[1], c[2], c[3], c[4], c[5])
			"style": n.draw_style_box(c[1], c[2])
			"rect": n.draw_rect(c[1], c[2], c[3], c[4])
			"circle": n.draw_circle(c[1], c[2], c[3], c[4], c[5])
			"line": n.draw_line(c[1], c[2], c[3], c[4])
			"triangles": RenderingServer.canvas_item_add_triangle_array(n.get_canvas_item(), c[1], c[2], c[3], c[4], PackedInt32Array(), PackedFloat32Array(), c[5].get_rid())
			"polygon": n.draw_polygon(c[1], c[2], c[3], c[4])
			"arc": n.draw_arc(c[1], c[2], c[3], c[4], c[5], c[6], c[7])
