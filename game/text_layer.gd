extends Node2D
var items: = []
var commands:Array=[]:
	set(value):
		commands=value
		_sync_clips()
var clipped_layers:Array=[]

func _sync_clips()->void:
	var count:int=0
	for command in commands:
		if command[0]!="clip_group":continue
		if count==clipped_layers.size():
			var clip:=Control.new()
			clip.clip_contents=true;clip.mouse_filter=Control.MOUSE_FILTER_IGNORE
			var painter:Node2D=get_script().new()
			clip.add_child(painter);add_child(clip)
			clipped_layers.append(clip)
		var clip:Control=clipped_layers[count]
		var area:Rect2=command[1]
		clip.position=area.position;clip.size=area.size;clip.show()
		var painter:Node2D=clip.get_child(0)
		painter.position=-area.position
		painter.items=command[3];painter.commands=command[2];painter.queue_redraw()
		count+=1
	for index in range(count,clipped_layers.size()):clipped_layers[index].hide()

func _draw() -> void :
	preload("res://addons/reservoir/ui_surface.gd").paint(self, commands)
	var raster: = maxf(1.0, get_viewport_transform().get_scale().x)
	for it in items:
		var scale: float = it[7]
		var pos: Vector2 = (it[1] * raster).round() / raster
		var px: = maxi(1, roundi(it[5] * scale * raster))
		draw_set_transform(pos, it[8] if it.size() > 8 else 0.0, Vector2.ONE / raster)
		draw_multiline_string(it[0], Vector2.ZERO, it[2], it[3], it[4] * scale * raster, px, -1, it[6])
	draw_set_transform(Vector2.ZERO)
