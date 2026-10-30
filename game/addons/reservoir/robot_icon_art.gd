extends RefCounted
# Approved artwork extracted at original resolution, with only edge-connected
# background removed. Never resample these masters into tiny intermediate icons.
const ICONS = {
 "sleep":preload("res://art/ui/capture_robot_b/sleep_master.png"),
 "capture":preload("res://art/ui/capture_robot_b/capture_master.png"),
 "success":preload("res://art/ui/capture_robot_b/success_master.png"),
 "full":preload("res://art/ui/capture_robot_b/full_master.png"),
 "speed":preload("res://art/ui/capture_robot_b/speed_master.png"),
 "storage":preload("res://art/ui/capture_robot_b/storage_master.png"),
 "precision":preload("res://art/ui/capture_robot_b/precision_master.png"),
}
func icon(key: String) -> Texture2D:
 return ICONS[key]
func draw(m,key: String,box: Rect2,modulate: Color=Color.WHITE) -> Rect2:
 var t:=icon(key)
 var size:=t.get_size()*minf(box.size.x/t.get_width(),box.size.y/t.get_height())
 var rect:=Rect2((box.get_center()-size/2).round(),size.round())
 m._ui_texture_rect(t,rect,false,modulate)
 return rect
