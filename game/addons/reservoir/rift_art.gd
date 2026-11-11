extends RefCounted
# Approved artwork only. Gameplay means/prices/unlock conditions remain unassigned.
const BACKGROUND := "res://art/rift/base.png"
const SOURCE := Vector2(1080,2640)
const DECK_Y := 1194.0
const WATER_Y := 1314.0
const SAND_Y := 2420.0
var catalog: Array=[]
var atlases: Dictionary={}
func setup() -> void:
	if not catalog.is_empty():return
	catalog=JSON.parse_string(FileAccess.get_file_as_string("res://art/rift/catalog.json")).species
func has_species(sp: int) -> bool:return sp>=60 and sp<80
func entry(sp: int) -> Dictionary:
	setup();return catalog[sp-60]
func texture(sp: int) -> Texture2D:
	if not atlases.has(sp):atlases[sp]=load("res://art/rift/%02d.png"%(sp-59))
	return atlases[sp]
func frame_index(sp: int, seconds: float) -> int:return posmod(floori(seconds*float(entry(sp).fps)),16)
func source_rect(sp: int, seconds: float) -> Rect2:
	var e:=entry(sp);var i:=frame_index(sp,seconds);var size:=Vector2(e.canvas[0],e.canvas[1]);var u:Array=e.used_union
	return Rect2(Vector2(i%4,i/4)*size+Vector2(u[0],u[1]),Vector2(u[2]-u[0],u[3]-u[1]))
func draw(m, sp: int, center: Vector2, length: float, seconds: float, face: float=1.0, revealed: bool=true, alpha: float=1.0, grade: int=0, tilt: float=0.0) -> Vector2:
	var tex:=texture(sp);var src:=source_rect(sp,seconds)
	var size:=src.size*(length/src.size.x)
	# Fixed union crop and scale across all 16 frames; never per-frame auto-fit.
	var points:=PackedVector2Array()
	for v in [Vector2(-.5,-.5),Vector2(.5,-.5),Vector2(.5,.5),Vector2(-.5,.5)]:
		var p:Vector2=v*size;p.x*=-face;points.append(center+p.rotated(tilt))
	var ts:=tex.get_size()
	var uv:=PackedVector2Array([src.position/ts,Vector2(src.end.x,src.position.y)/ts,src.end/ts,Vector2(src.position.x,src.end.y)/ts])
	var quad:Array=[points,uv]
	if revealed:m._draw_pixel_halo([quad],tex,grade,seconds*1000.0)
	m._fish_quad(quad,Color(1,1,1,alpha) if revealed else Color(.025,.02,.07,alpha),tex)
	return center+Vector2(.45*length*face,0).rotated(tilt)
func ui_draw(m,sp: int,box: Rect2) -> Rect2:
	var src:=source_rect(sp,0);var size:=src.size*minf(box.size.x/src.size.x,box.size.y/src.size.y)
	var r:=Rect2(box.get_center()-size/2,size)
	m._ui_texture_rect_region(texture(sp),r,src)
	return r
