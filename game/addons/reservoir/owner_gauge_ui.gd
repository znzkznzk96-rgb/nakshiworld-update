extends RefCounted
# PixelLab frames; names, specimens and proportional fill remain engine-rendered.
const REGIONS = ["동네 저수지","거꾸로 폭포 계곡","타일 바다","균열 해역","심해","우주 바다"]
const ACCENTS = [Color("56c6d1"),Color("d66b82"),Color("62c2e8"),Color("c28bef"),Color("68bec5"),Color("c4a3f5")]
const FRAME_SIZE := Vector2(256,48)
var bounds := Rect2()
var image_bounds := Rect2()
var fill_bounds := Rect2()
var track_bounds := Rect2()
var label_bounds := Rect2()
var warning_bounds := Rect2()
var frames: Array[Texture2D]=[]
var layouts: Array=[]
var display_frames: Array[Texture2D]=[]
var display_backings: Array[Texture2D]=[]
func load_frames() -> void:
	if frames.size()==6: return
	layouts=JSON.parse_string(FileAccess.get_file_as_string("res://data/ui/owner_gauges.json"))
	for area in 6:
		var source: Texture2D=load("res://art/ui/owners/region_%d.png"%area)
		frames.append(source)
		var atlas:=AtlasTexture.new();atlas.atlas=source;atlas.region=local_rect(area,"crop")
		display_frames.append(atlas)
		var backing:=AtlasTexture.new();backing.atlas=make_backing(source);backing.region=atlas.region
		display_backings.append(backing)
func visible(m) -> bool:
	return m.scene == "fish" and not m.title_open and m.TUT.done and m.active_region >= 0 and m.active_region < 6 and m.progression.all_parts(m,m.active_region)
func clear_bounds() -> void:
	bounds=Rect2();image_bounds=Rect2();fill_bounds=Rect2();track_bounds=Rect2();label_bounds=Rect2();warning_bounds=Rect2()
func draw(m) -> void:
	clear_bounds()
	if not visible(m): return
	var area: int=m.active_region
	var value: float=clampf(float(m.progression.owner_gauge[area]),0,100)
	draw_frame(m,area,value,Vector2(7,m.top_y+73))
	if m.S.phase == "pre" and m.S.get("owner",false):
		var owners: Array=m.CATALOG.by_star(area,4)
		warning(m,area,m.FISH_NAME[int(owners[0])] if not owners.is_empty() else "주인",ACCENTS[area])
func local_rect(area: int,key: String) -> Rect2:
	var a: Array=layouts[area][key]
	var rect:=Rect2(a[0],a[1],a[2],a[3])
	if key=="crop":return rect
	var crop: Array=layouts[area].crop
	var scale:=FRAME_SIZE/Vector2(crop[2],crop[3])
	return Rect2((rect.position-Vector2(crop[0],crop[1]))*scale,rect.size*scale)
func draw_frame(m,area: int,value: float,origin: Vector2) -> void:
	load_frames();clear_bounds()
	if area<0 or area>=6: return
	value=clampf(value,0,100)
	bounds=Rect2(origin,FRAME_SIZE)
	m._ui_texture_rect(display_backings[area],bounds)
	m._ui_texture_rect(display_frames[area],bounds)
	var badge: Rect2=local_rect(area,"badge");badge.position+=origin
	label_bounds=local_rect(area,"label");label_bounds.position+=origin
	track_bounds=local_rect(area,"track");track_bounds.position+=origin
	var owners: Array=m.CATALOG.by_star(area,4)
	var name: String="주인의 기척"
	if not owners.is_empty():
		var sp: int=int(owners[0]);name=m.FISH_NAME[sp]
		image_bounds=m._ui_fish(sp,badge.grow(-3))
	var baseline: float=roundf(label_bounds.get_center().y+3)
	var percent: String="%d%%"%int(value)
	var percent_width: float=m._text_w(percent,9)
	var name_x: float=label_bounds.position.x+4
	var percent_x: float=label_bounds.end.x-percent_width-4
	m._text(name,Vector2(name_x,baseline),9,Color("fff0d1"),false,percent_x-name_x-6)
	m._text(percent,Vector2(percent_x,baseline),9,Color("fff0d1"))
	m._ui_rect(track_bounds,Color("0b111a"))
	var inner: Rect2=track_bounds.grow(-1)
	fill_bounds=Rect2(inner.position,Vector2(floorf(inner.size.x*value/100.0),inner.size.y))
	if fill_bounds.size.x>0:
		m._ui_rect(fill_bounds,ACCENTS[area])
		m._ui_rect(Rect2(fill_bounds.position,Vector2(fill_bounds.size.x,1)),ACCENTS[area].lightened(0.3))
func warning(m,area: int,name: String,color: Color) -> void:
	# Retain layout/query bounds for the gauge, but no warning panel is painted.
	warning_bounds=Rect2(12,m.top_y+145,246,62)
	m.encounter.draw_owner(m,name)

func make_backing(source:Texture2D)->Texture2D:
	# Fill only enclosed transparent windows, preserving every approved frame pixel.
	var original:Image=source.get_image()
	var image:=Image.create(256,48,false,Image.FORMAT_RGBA8)
	for seed in [Vector2i(120,12),Vector2i(120,31),Vector2i(42,24)]:
		var pending:Array[Vector2i]=[seed]
		var visited:Dictionary={}
		var points:Array[Vector2i]=[]
		var enclosed:=true
		while not pending.is_empty():
			var point:Vector2i=pending.pop_back()
			if visited.has(point) or point.x<0 or point.x>=256 or point.y<0 or point.y>=48:continue
			visited[point]=true
			if original.get_pixelv(point).a>=.94:continue
			if point.x==0 or point.x==255 or point.y==0 or point.y==47:enclosed=false
			points.append(point)
			for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:pending.append(point+delta)
		if enclosed:
			for point in points:image.set_pixelv(point,Color("0b111a") if seed.y==31 else Color("0f1b29"))
	return ImageTexture.create_from_image(image)
