extends RefCounted
static func button(m,r: Rect2,label: String) -> void:
	m._ui_style_box(m.sb_btn,r);m._text(label,r.get_center()+Vector2(0,4),10,Color("382619"),true,r.size.x-8)
static func draw(m) -> void:
	var h: float=m.get_viewport_rect().size.y
	var r:=Rect2(20,maxf(95,h*0.5-165),230,330)
	m._ui_rect(Rect2(-m.ox,0,m.VW+2*m.ox,h),Color(0.04,0.06,0.1,0.84));m._ui_style_box(m.sb_panel,r)
	m._text("정말 초기화하시겠습니까?" if m.reset_confirm else "설정",Vector2(135,r.position.y+30),12,Color("382619"),true,210)
	m.set_rects={"panel":r,"close":Rect2(r.end.x-34,r.position.y+8,25,25)}
	if m.reset_confirm:
		m._text("보유 물고기·재화·장비·도감과\n모든 진행도가 삭제됩니다.\n삭제 후에는 복구할 수 없습니다.\n음량·진동 설정은 유지됩니다.",Vector2(135,r.position.y+88),11,Color("803b32"),true,210)
		var no:=Rect2(37,r.end.y-68,92,35);var yes:=Rect2(141,r.end.y-68,92,35)
		button(m,no,"아니오");button(m,yes,"예 · 초기화")
		m.set_rects.no=no;m.set_rects.yes=yes;return
	m._ui_texture(m.icons.close,m.set_rects.close.position)
	var y: float=r.position.y+65
	m._text("효과음",Vector2(36,y+5),11,Color("382619"))
	var slider:=Rect2(100,y-7,125,14);m._ui_style_box(m.sb_meter,slider)
	m._ui_rect(Rect2(112,y-4,maxf(1,101*m.SET.sfx),8),Color("8ead72"))
	m._ui_texture(m.icons.knob,Vector2(106+101*m.SET.sfx,y-9));m.set_rects.slider=Rect2(100,y-14,125,28)
	y+=40
	m._text("배경음",Vector2(36,y+5),11,Color("382619"))
	var music:=Rect2(100,y-12,125,27);button(m,music,"%d%% · 눌러 변경" % roundi(m.SET.music*100));m.set_rects.music=music
	y+=40
	m._text("진동",Vector2(36,y+5),11,Color("382619"))
	var vib:=Rect2(100,y-12,125,27);button(m,vib,["꺼짐","약","중","강"][int(m.SET.vib_level)]);m.set_rects.vib=vib
	var book:=Rect2(38,y+28,194,30);button(m,book,"몸짓 도감 · 소리와 진동 체험");m.set_rects.tut=book
	var reset:=Rect2(38,y+68,194,30);button(m,reset,"게임 데이터 초기화");m.set_rects.reset=reset
	var license:=Rect2(38,r.end.y-52,194,22);button(m,license,"글꼴 · 라이선스");m.set_rects.license=license
	m._text("버전 v"+m._ver_name(),Vector2(135,r.end.y-15),9,Color("5a3e28"),true)
static func press(m,pos: Vector2) -> void:
	if m.set_rects.is_empty(): return
	if m.reset_confirm:
		if m.set_rects.get("no",Rect2()).has_point(pos) or not m.set_rects.panel.has_point(pos): m.reset_confirm=false
		elif m.set_rects.get("yes",Rect2()).has_point(pos): m.reset_progress()
		return
	if m.set_rects.close.has_point(pos) or not m.set_rects.panel.has_point(pos): m.settings_open=false;m._save_set();return
	if m.set_rects.slider.has_point(pos): m.slider_drag=true;m._slider_set(pos.x);return
	if m.set_rects.music.has_point(pos):
		m.SET.music=fposmod(roundf(m.SET.music*4)/4+0.25,1.25);m._save_set();return
	if m.set_rects.vib.has_point(pos):
		m.SET.vib_level=(int(m.SET.vib_level)+1)%4;m.SET.vib=m.SET.vib_level>0;m._save_set()
		m.vib_queue.clear();m.vib_wait=0.0
		if m.SET.vib: m.buzz([70])
		else: Input.vibrate_handheld(0)
		return
	m.audio_feedback.sound(m,"click",-14)
	if m.set_rects.tut.has_point(pos): m.set_view="book"
	elif m.set_rects.reset.has_point(pos): m.reset_confirm=true
	elif m.set_rects.license.has_point(pos): m.set_view="license";m.font_license_page=0
