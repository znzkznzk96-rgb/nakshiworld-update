extends RefCounted
# Shared reader: no ellipsis or content truncation; six lines per page.
static func pages(m, paragraphs: Array) -> Array:
	var result: Array = []
	var current: Array = []
	for paragraph in paragraphs:
		var wrapped: Array = []
		var line := ""
		for ch in str(paragraph):
			if ch == "\n": wrapped.append(line);line="";continue
			if m._text_w(line+ch,11)>208 and not line.is_empty(): wrapped.append(line);line=""
			line+=ch
		if not line.is_empty(): wrapped.append(line)
		# Keep a complete tip on one page whenever it fits.
		if current.size()+wrapped.size()>6 and not current.is_empty(): result.append(current);current=[]
		for text in wrapped:
			if current.size()==6: result.append(current);current=[]
			current.append(text)
	if not current.is_empty(): result.append(current)
	return [[]] if result.is_empty() else result
static func draw(m, paragraphs: Array, page: int, y: float, nav_y: float, centered: bool=false) -> Dictionary:
	var all_pages := pages(m,paragraphs)
	page=clampi(page,0,all_pages.size()-1)
	for i in all_pages[page].size():
		m._text(all_pages[page][i],Vector2(135 if centered else 31,y+i*21),11,Color("513b29"),centered,208)
	var controls := {"count":all_pages.size()}
	m._text("%d / %d" % [page+1,all_pages.size()],Vector2(135,nav_y+17),10,Color("68533d"),true,80)
	for key in ["previous","following"]:
		var enabled: bool=page>0 if key=="previous" else page<all_pages.size()-1
		var r:=Rect2(32 if key=="previous" else 206,nav_y,32,27)
		if enabled:
			controls[key]=r;m._ui_style_box(m.sb_btn,r)
			m._text("<" if key=="previous" else ">",r.get_center()+Vector2(0,4),12,Color("513b29"),true,26)
	return controls
static func illustration(m, key: String, y: float) -> void:
	var texture = m.fish_tex[1] if key == "fish" else m.V.tex.get(key, preload("res://art/guide64/book.png"))
	var size: Vector2 = texture.get_size()
	size *= minf(54.0/size.x,54.0/size.y)
	m._ui_texture_rect(texture,Rect2(Vector2(135,y+27)-size/2,size),false)
