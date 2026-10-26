extends RefCounted
var data = preload("res://addons/expedition/model.gd").new()
var opened: String = ""
var tab: int = 0
var explore_tab: int = 0
var selected_round: int = 1
var page: int = 0
var selected: Array = []
var pair: Array = [0,0]
var pair_slot: int = 0
var rects: Dictionary = {}
var textures: Dictionary = {}
var drag_slot: int = -1
var drag_start: Vector2
var drag_pos: Vector2
var notice: String = ""
var choosing_slot: int = -1
var approved: Dictionary = {}
var result_notice: float = 0.0
var training_uid: int = -1
const CARD_REGIONS = [Rect2(817,242,239,111),Rect2(1086,242,245,111),Rect2(1086,365,245,120),Rect2(817,365,239,120),Rect2(817,495,239,113),Rect2(1086,495,245,113),Rect2(1086,619,245,121),Rect2(817,619,239,121),Rect2(817,750,239,122),Rect2(1086,750,245,122)]
const ROOM_REGIONS = [Rect2(257,285,180,54),Rect2(525,285,181,54),Rect2(528,366,143,60),Rect2(211,183,508,76),Rect2(255,454,140,59),Rect2(531,454,176,59),Rect2(530,540,140,56),Rect2(255,540,181,56),Rect2(257,628,180,56),Rect2(530,645,130,38)]
const EFILES = ["water","electric","poison","light","dark"]
const ROLES = {"attack":"공격","defense":"방어","support":"지원"}
const ROOMS = ["젖은 현관","비어 있는 탈의실","반짝이는 세면대","꺼지지 않는 복도","거울 없는 세면실","잠긴 관리실","물소리 나는 계단","끝없는 여과실","돌아오는 복도","출구를 닮은 문"]
const WALLS = ["24596e","347c74","225f79","956526","3d366f","395472","263d70","1d6a67","704530","2e2352"]

func setup() -> void:
	for u in data.catalog.soldiers: textures[u.id]=load("res://art/expedition/%s.png"%u.id)
	for i in range(1,19):
		textures[str(i)]=[]
		for j in 7: textures[str(i)].append(preload("res://addons/expedition/opaque_body.gd").prepare(load("res://art/expedition/normal%02d_%d.png"%[i,j]),128))
	for id in ["3R","5R","7R","10R"]: textures[id]=preload("res://addons/expedition/opaque_body.gd").prepare(load("res://art/expedition/boss%s.png"%id),320 if id=="10R" else 224)
	for e in EFILES: textures[e]=load("res://art/expedition/%s.png"%e)
	for key in ["menu","screens","route"]: approved[key]=load("res://art/expedition/approved/%s-reference.jpg"%key)
	for i in 6: approved["menu%d"%i]=atlas(approved.menu,Rect2([90,313,538,769,1005,1230][i],692,210,174))
	textures.explore=approved.menu3;textures.alchemy=approved.menu4
	textures.bolt=load("res://art/expedition/bolt.png")

func open(m,screen: String) -> void:
	if screen=="explore" and m.scene!="village" and not data.battle.is_empty() and not data.active():
		m.show_toast("탐험 결과는 마을에서 확인해 주세요",Color("ffdc96"));return
	opened=screen;page=0;selected=[];notice="";choosing_slot=-1;m.menu_open=false;m.holding=false
	selected_round=mini(data.unlocked,maxi(1,selected_round))

func update(m,dt: float) -> void:
	var was_active: bool=data.active()
	if data.update(dt,Time.get_unix_time_from_system()): m._save_game()
	if was_active and not data.active(): result_notice=6.0
	result_notice=maxf(0,result_notice-dt)
	if not data.battle.is_empty() and not data.active() and not bool(data.battle.get("result_seen",false)):
		if m.scene=="village" and m.V.shop=="" and opened=="" and not m.menu_open and not m.mailbox.opened and not m.guide.opened and not m.personal_dex.opened and not m.settings_open and not m.market_open and m.trans.is_empty():
			open(m,"explore");data.battle.result_seen=true;m._save_game()

func panel(m,r: Rect2) -> void:
	m._ui_style_box(m.hud_reference_style,r)
	m._ui_rect(r.grow(-5),Color("f6e6c1"))

func button(m,key: String,r: Rect2,label: String,enabled: bool=true) -> void:
	m._ui_style_box(m.sb_btn,r)
	if not enabled: m._ui_rect(r.grow(-3),Color(0.2,0.15,0.1,0.28))
	m._text(label,r.get_center()+Vector2(0,3),9,Color("382619") if enabled else Color("796b58"),true,r.size.x-8)
	rects[key]=r

func sprite(m,id: int,box: Rect2,frame: int=0,alpha: float=1.0) -> void:
	var u: Dictionary=data.catalog.soldiers[id]
	var sz: Vector2=Vector2(int(u.frame_size[0]),int(u.frame_size[1]))
	var size: Vector2=sz*minf(box.size.x/sz.x,box.size.y/sz.y)
	m._ui_texture_rect_region(textures[u.id],Rect2((box.get_center()-size/2).round(),size.round()),Rect2(frame%int(u.frame_count)*sz.x,0,sz.x,sz.y),Color(1,1,1,alpha))

func atlas(texture: Texture2D,region: Rect2) -> AtlasTexture:
	var a=AtlasTexture.new();a.atlas=texture;a.region=region;return a

func primary(m,key: String,r: Rect2,label: String,enabled: bool=true) -> void:
	m._ui_style_box(m.sb_btn,r)
	m._ui_rect(r.grow(-4),Color("07515c") if enabled else Color("4c6261"))
	m._ui_rect(Rect2(r.position+Vector2(6,5),Vector2(r.size.x-12,2)),Color("16a4ab"))
	m._ui_rect(Rect2(r.position+Vector2(6,r.size.y-8),Vector2(r.size.x-12,3)),Color("07323b"))
	m._text(label,r.get_center()+Vector2(0,4),11,Color("fff0d1"),true,r.size.x-16,true)
	rects[key]=r

func room(m,r: Rect2,index: int) -> void:
	var region: Rect2=ROOM_REGIONS[index%10]
	var progress: float=1.0 if not data.battle.is_empty() else 0.0
	if data.active() and data.battle.get("phase","")=="approach":
		var t: float=clampf(float(data.battle.phase_time)/4,0,1)
		progress=1-pow(1-t,2)
	# A wider view of the approved room pans left, avoiding mirrored/repeated seams.
	var window: Rect2=Rect2(region.position+Vector2(region.size.x*.22*progress,0),Vector2(region.size.x*.78,region.size.y))
	m._ui_texture_rect_region(approved.screens,r,window)


func skull(m,c: Vector2,king: bool=false) -> void:
	m._ui_rect(Rect2(c-Vector2(5,4),Vector2(10,7)),Color("efdfb6"))
	m._ui_rect(Rect2(c+Vector2(-3,3),Vector2(6,3)),Color("efdfb6"))
	for x in [-3,1]: m._ui_rect(Rect2(c+Vector2(x,-2),Vector2(2,3)),Color("302038"))
	if king:
		m._ui_rect(Rect2(c+Vector2(-6,-7),Vector2(12,3)),Color("eaaa31"))
		for x in [-6,-1,4]: m._ui_rect(Rect2(c+Vector2(x,-10),Vector2(2,4)),Color("ffd66f"))

func stage_name(round_no: int) -> String:
	return "1-%d"%clampi(round_no,1,10)

func encounter_name() -> String:
	return "%d/3전투"%mini(3,int(data.battle.get("index",0))+1)

func strip_label() -> String:
	if data.battle.is_empty(): return "탐험대를 편성해 보세요"
	return "%s · %s"%[stage_name(int(data.battle.round)),encounter_name()]

func draw_strip(m) -> void:
	var r: Rect2=Rect2(8,m.top_y+69,254,72)
	m._ui_style_box(m.hud_reference_style,r)
	var b: Dictionary=data.battle
	var index: int=(int(b.round)-1) if not b.is_empty() else selected_round-1
	room(m,Rect2(r.position+Vector2(4,20),Vector2(r.size.x-8,r.size.y-24)),index)
	m._ui_rect(Rect2(r.position+Vector2(4,4),Vector2(r.size.x-8,16)),Color("f7e7c5"))
	var label: String=strip_label()
	var status: String="" if b.is_empty() else ("%d%%"%int(b.get("progress",0)) if data.active() else ("돌파" if b.status=="win" else "귀환"))
	m._text(label,r.position+Vector2(8,15),9,Color("382619"),false,193)
	m._text(status,r.position+Vector2(231,15),8,Color("382619"),true,37)
	if not b.is_empty(): battle_art(m,Rect2(r.position+Vector2(4,20),Vector2(r.size.x-8,r.size.y-24)))
	else: m._text("어혼을 모아 병사 3마리를 보내세요",r.position+Vector2(127,49),9,Color("fff0d1"),true,230,true)
	rects.strip=r

func rarity_label(u: Dictionary) -> String:
	return " · "+["레어","유니크","전설"][clampi(int(u.get("rarity",0)),0,2)] if int(u.star)==3 else ""

func enemy_pose(b: Dictionary) -> Vector2i:
	var phase: String=str(b.get("phase","approach"));var t: float=float(b.get("clock",0))
	var boss: bool=str(b.enemy.id).ends_with("R")
	var fx: Dictionary=b.get("fx",{});var age: float=float(fx.get("age",99))
	if phase=="death":
		var d: float=float(b.phase_time)
		return Vector2i(mini(5,int(d/.2)),3) if boss else Vector2i(5 if d<.4 else 6,0)
	if phase=="fight":
		if bool(fx.get("enemy_hit",false)) and age<.36:
			return Vector2i(mini(5,int(age/.06)),2) if boss else Vector2i(4,0)
		if boss:
			return Vector2i(mini(5,int(t/1.1*6)),1) if t<1.1 else Vector2i(int((t-1.1)/.065)%6,0)
		return Vector2i(1 if t<.5 else (2 if t<.8 else (3 if t<1.25 else 0)),0)
	return Vector2i(int(float(b.get("phase_time",0))/.12)%6,0) if boss else Vector2i.ZERO

func fighter_effect(f: Dictionary,fx: Dictionary) -> Dictionary:
	var age: float=float(fx.get("age",99));var uid: int=int(f.get("uid",-2))
	var dying: bool=int(f.hp)<=0
	var alpha: float=1.0
	if dying:
		alpha=1.0-smoothstep(.08,.85,age) if uid==int(fx.get("death_uid",-1)) else 0.0
	var hit: bool=uid==int(fx.get("hit_uid",-1)) and age>=.38 and age<.68 and not dying
	return {"alpha":alpha,"x":-sin((age-.38)/.3*PI)*4 if hit else 0.0,"y":minf(1,age/.85)*7 if dying else 0.0,"hit":hit}

func battle_art(m,r: Rect2) -> void:
	var b: Dictionary=data.battle
	var phase: String=str(b.get("phase","approach"));var t: float=float(b.get("clock",0))
	var fx: Dictionary=b.get("fx",{});var age: float=float(fx.get("age",99))
	var ground: float=r.end.y-2
	var front_uid: int=-1
	for fighter in b.fighters:
		if int(fighter.hp)>0: front_uid=int(fighter.uid);break
	for i in b.fighters.size():
		var f: Dictionary=b.fighters[i];var effect: Dictionary=fighter_effect(f,fx)
		if float(effect.alpha)<=0: continue
		var u: Dictionary=data.catalog.soldiers[int(f.id)]
		var frame: int=0
		if phase=="fight" and int(f.hp)>0: frame=mini(int(u.frame_count)-1,int(t/1.5*int(u.frame_count)))
		for event in fx.get("support",[]):
			if int(event.source)==int(f.get("uid",-1)) and age<.6: frame=mini(int(u.frame_count)-1,int(age/.6*int(u.frame_count)))
		var x: float=r.position.x+8+(2-i)*34+float(effect.x)
		if phase=="fight": x+=sin(clampf(t/1.1,0,1)*PI)*(27 if int(f.uid)==front_uid else 3)
		if phase=="approach": x-=8*(1-minf(1,float(b.phase_time)/4.0))
		var fh: float=minf(43,r.size.y*.70)
		if phase=="approach": effect.y+=sin(float(b.phase_time)*12+i)*1.5
		sprite(m,int(f.id),Rect2(x,ground-fh+float(effect.y),48*fh/40,fh),frame,float(effect.alpha))
		if int(f.uid)==front_uid:
			var hp: float=float(f.hp)
			if age<.38 and int(fx.get("hit_uid",-1))==int(f.uid): hp=float(fx.get("front_hp_before",hp))
			health_bar(m,Rect2(x+4,ground-fh-4,33,4),hp,float(f.max_hp),float(fx.get("front_hp_before",hp)) if age<.8 and int(fx.get("hit_uid",-1))==int(f.uid) else hp,Color("74cc6a"))
		if int(fx.get("hit_uid",-1))==int(f.uid) and age>=.38 and age<1.08:
			floating_value(m,Vector2(x+20,ground-fh+10),"-%d"%int(fx.get("incoming",0)),Color("ffc393"),age-.38)
			if int(fx.get("blocked",0))>0: floating_value(m,Vector2(x+20,ground-fh+21),"◇%d"%int(fx.blocked),Color("96dcfa"),age-.38)
		if int(f.shield)>0 and int(f.hp)>0: m._ui_arc(Vector2(x+25,ground-16),17,-1.5,1.5,9,Color("f5df83"),1)
		for event in fx.get("support",[]):
			if int(event.target)!=int(f.get("uid",-1)) or age>=.75 or int(f.hp)<=0: continue
			floating_value(m,Vector2(x+20,ground-19),"+%d"%int(event.amount),Color("79f1b4") if event.kind!="ward" else Color("96dcfa"),age)
			var color: Color=Color("53e6bc") if event.kind!="ward" else Color("f7d65b")
			color.a=1.0-smoothstep(.35,.75,age)
			var c: Vector2=Vector2(x+22,ground-23-age*7).round()
			if event.kind=="ward": m._ui_arc(c,7+age*5,0,TAU,12,color,1)
			else:
				m._ui_rect(Rect2(c-Vector2(1,4),Vector2(2,8)),color)
				m._ui_rect(Rect2(c-Vector2(4,1),Vector2(8,2)),color)
		if u.id=="eel" and phase=="fight" and int(f.hp)>0 and t>0.55 and t<1.5:
			var p: float=(t-.55)/.95
			m._ui_texture_rect(textures.bolt,Rect2(lerpf(x+30,r.position.x+165,p),ground-22,13,5))
	var key: String=str(b.enemy.id) if b.enemy.id is String else str(int(b.enemy.id))
	var is_boss: bool=key.ends_with("R");var n: int=320 if key=="10R" else (224 if is_boss else 128)
	var pose: Vector2i=enemy_pose(b);var alpha: float=1.0
	if phase=="death": alpha=1.0-smoothstep(1.3,2.2,float(b.phase_time))
	var display: float=minf(r.size.y*.94,63) if key=="10R" else minf(r.size.y*.77,49) if is_boss else minf(r.size.y*.95,76)
	var enemy_x: float=r.position.x+minf(r.size.x-display-10,145)
	if phase=="approach": enemy_x+= (r.end.x+2-enemy_x)*(1-smoothstep(0,3.8,float(b.phase_time)))
	elif phase=="fight" and age<.38: enemy_x-=sin(age/.38*PI)*9
	var source: Rect2=Rect2(pose.x*n if is_boss else 0,pose.y*n,n,n)
	var target: Rect2=Rect2(enemy_x,ground-display,display,display)
	var visible: Rect2=target.intersection(r)
	if visible.has_area():
		var clipped: Rect2=Rect2(source.position+(visible.position-target.position)/display*n,visible.size/display*n)
		m._ui_texture_rect_region(textures[key] if is_boss else textures[key][pose.x],visible,clipped,Color(1,1,1,alpha))
	if phase!="approach" and int(b.enemy.hp)>0:
		health_bar(m,Rect2(enemy_x+display/2-18,r.position.y+3,36,4),float(b.enemy.hp),float(b.enemy.max_hp),float(fx.get("enemy_hp_before",b.enemy.hp)) if age<.8 else float(b.enemy.hp),Color("df665a"))
	if age<.7 and fx.has("outgoing"): floating_value(m,Vector2(enemy_x+display/2,r.position.y+20),"-%d"%int(fx.outgoing),Color("fff0c1"),age)


func TICK_LENGTH() -> float: return 1.5

func draw(m,h: float) -> void:
	if opened=="": return
	# Hide underlying text as well as surfaces so world/shop labels cannot leak through.
	m.text_items=m.text_items.filter(func(it): return it[1].y<m.top_y+65)
	var y: float=m.top_y+69;var bottom: float=h-m.bot_pad-8
	panel(m,Rect2(6,y,258,bottom-y));rects={}
	m._ui_style_box(m.hud_reference_style,Rect2(11,y+5,248,26))
	m._ui_texture_rect(textures.explore if opened=="explore" else textures.alchemy,Rect2(18,y+7,25,22))
	m._text("탐험" if opened=="explore" else "연성",Vector2(50,y+23),13,Color("fff0d1"),false,128)
	if opened=="explore": button(m,"go_alchemy",Rect2(184,y+8,44,20),"연성")
	else:
		button(m,"go_explore",Rect2(112,y+8,44,20),"탐험")
		button(m,"roster",Rect2(158,y+8,70,20),"병사 강화")
	button(m,"close",Rect2(233,y+8,22,20),"×")
	if not data.pending.is_empty(): draw_pending(m,y+37,bottom);return
	if opened=="merge_confirm": draw_confirmation(m,y+37,bottom)
	elif opened=="explore": draw_explore(m,y+37,bottom)
	elif opened=="training": draw_training(m,y+37,bottom)
	else: draw_alchemy(m,y+37,bottom)



func draw_explore(m,y: float,bottom: float) -> void:
	for i in 2:
		button(m,"explore_tab:%d"%i,Rect2(17+i*119,y,117,24),["탐사 노선","병사 배치"][i])
		if explore_tab==i: m._ui_rect(Rect2(23+i*119,y+20,105,2),Color("159d9d"))
	y+=31
	if explore_tab==1:
		draw_formation(m,y,bottom);return
	if not data.battle.is_empty():
		var b: Dictionary=data.battle
		if not data.active():
			m._text("탐험 성공!" if b.status=="win" else "탐험 실패",Vector2(135,y+27),17,Color("98651f") if b.status=="win" else Color("8c4935"),true,226)
			m._text("%s · %s"%[stage_name(int(b.round)),ROOMS[int(b.round)-1]],Vector2(135,y+51),10,Color("6c553b"),true,226)
			room(m,Rect2(23,y+69,224,88),int(b.round)-1)
			for i in b.fighters.size(): sprite(m,int(b.fighters[i].id),Rect2(40+i*65,y+86,60,60))
			m._text("수고했어요, 탐험대!",Vector2(135,y+183),12,Color("382619"),true,226)
			m._text("획득 비늘  %d"%int(b.reward),Vector2(135,y+211),11,Color("82502a"),true,226)
			if b.status=="win" and bool(b.first): m._text("첫 돌파 보상 · %s 어혼 1개"%data.ELEMENTS[(int(b.round)-1)%5],Vector2(135,y+235),10,Color("82502a"),true,226)
			button(m,"claim",Rect2(22,bottom-57,226,30),"보상 받고 편성으로")
			return
		m._text("%s · %s"%[stage_name(int(b.round)),ROOMS[int(b.round)-1]],Vector2(135,y+12),11,Color("382619"),true,230)
		var r: Rect2=Rect2(17,y+23,236,85);room(m,r,int(b.round)-1);battle_art(m,r)
		for i in b.fighters.size():
			var f: Dictionary=b.fighters[i]
			m._text("%s  %d/%d"%[data.catalog.soldiers[int(f.id)].name,int(f.hp),int(f.max_hp)],Vector2(25,y+130+i*20),10,Color("382619"),false,220)
		m._text("조우 %d/3 · 획득 %d비늘"%[mini(3,int(b.index)+1),int(b.reward)],Vector2(135,y+203),10,Color("382619"),true,220)
		if data.active():
			button(m,"minimize",Rect2(22,bottom-65,226,29),"마을에서 진행 보기")
			m._text("낚시 중에도 진행 · 앱을 닫으면 일시정지",Vector2(135,bottom-24),8,Color("6c553b"),true,230)
		else:
			m._text("탐험 성공!" if b.status=="win" else "병사들이 돌아왔어요",Vector2(135,y+230),12,Color("82502a"),true,230)
			button(m,"claim",Rect2(22,bottom-65,226,29),"보상 받고 편성으로")
		return
	# Ten distinct approved room cards; the route follows the reference's zigzag.
	m._text("저수지 탐사 노선도",Vector2(21,y+9),10,Color("382619"),false,164)
	m._text("%d / 10 돌파"%data.completed.size(),Vector2(218,y+9),8,Color("6c553b"),true,62)
	var tile_h: float=clampf((bottom-y-73)/5,34,72)
	var map_y: float=y+18
	var boxes: Array=[]
	for idx in range(10):
		var row: int=idx/2;var col: int=idx%2 if row%2==0 else 1-idx%2
		boxes.append(Rect2(17+col*123,map_y+row*tile_h,113,tile_h-5))
	for idx in 9:
		m._ui_line(boxes[idx].get_center(),boxes[idx+1].get_center(),Color("6d391a"),1)
	for idx in 10:
		var r: Rect2=boxes[idx]
		m._ui_texture_rect_region(approved.route,r,CARD_REGIONS[idx])
		if idx+1>data.unlocked: m._ui_rect(r.grow(-3),Color(.04,.06,.09,.53))
		if idx+1==selected_round:
			m._ui_rect(r.grow(1),Color("12c6ca"),false,1)
			for corner in [r.position,r.position+Vector2(r.size.x-4,0),r.end-Vector2(4,4),r.position+Vector2(0,r.size.y-4)]: m._ui_rect(Rect2(corner,Vector2(4,4)),Color("a7fff0"),false,1)
		rects["round:%d"%(idx+1)]=r
	var remaining: int=maxi(0,ceili(data.recovery_until-Time.get_unix_time_from_system()))
	m._text("편성 %d/3 · 병사 배치 탭에서 변경"%data.team.size(),Vector2(135,bottom-49),8,Color("6c553b"),true,232)
	primary(m,"start",Rect2(18,bottom-35,234,27),"회복 중 %d초"%remaining if remaining>0 else "탐험 보내기 · "+stage_name(selected_round),data.team.size()==3 and remaining==0)

func draw_roster(m,y: float,bottom: float) -> void:
	# A separate selection sheet keeps the approved three-slot layout uncluttered.
	m.text_items=m.text_items.filter(func(it): return it[1].y<y)
	panel(m,Rect2(11,y,248,bottom-y-4));rects={}
	m._text("%s 병사 선택"%["앞","중간","뒤"][choosing_slot],Vector2(118,y+19),12,Color("382619"),true,188)
	button(m,"roster_close",Rect2(229,y+4,23,23),"×")
	var total: int=maxi(1,ceili(data.soldiers.size()/4.0));page=clampi(page,0,total-1)
	for i in 4:
		var n: int=page*4+i
		if n>=data.soldiers.size(): break
		var u: Dictionary=data.soldiers[n];var spec: Dictionary=data.catalog.soldiers[int(u.id)]
		var r: Rect2=Rect2(18,y+34+i*49,234,45)
		m._ui_style_box(m.sb_btn,r);sprite(m,int(u.id),Rect2(r.position+Vector2(2,1),Vector2(43,40)))
		m._text(spec.name+" · "+ROLES[spec.role],r.position+Vector2(49,14),9,Color("382619"),false,177)
		m._text(spec.description,r.position+Vector2(49,29),8,Color("6c553b"),false,177)
		m._text("★".repeat(int(u.star))+rarity_label(u)+(" · 편성 중" if int(u.uid) in data.team else ""),r.position+Vector2(49,40),7,Color("96703b"),false,177)
		rects["unit:%d"%int(u.uid)]=r
	button(m,"prev",Rect2(18,y+237,35,23),"‹");button(m,"next",Rect2(217,y+237,35,23),"›")
	m._text("%d / %d"%[page+1,total],Vector2(135,y+253),9,Color("6c553b"),true,140)
	button(m,"remove_slot",Rect2(36,bottom-42,198,27),"이 편성 칸 비우기")
	if data.soldiers.is_empty(): m._text("연성에서 병사를 먼저 만들어 주세요",Vector2(135,y+112),10,Color("6c553b"),true,223)

func soul_row(m,y: float) -> void:
	for i in 5:
		var x: float=18+i*48
		m._ui_texture_rect(textures[EFILES[i]],Rect2(x,y,23,23))
		m._text(str(data.souls[i]),Vector2(x+29,y+17),9,Color("382619"),true,23)

func draw_alchemy(m,y: float,bottom: float) -> void:
	for i in 2:
		var r: Rect2=Rect2(17+i*119,y,117,25)
		if tab==i: primary(m,"tab:%d"%i,r,["어혼 연성","병사 합성"][i])
		else: button(m,"tab:%d"%i,r,["어혼 연성","병사 합성"][i])
	y+=35
	if tab==0:
		m._text(notice if notice!="" else "어혼을 조합하세요.",Vector2(135,y+9),10,Color("9b4329") if notice!="" else Color("382619"),true,234)
		var owned_y: float=bottom-108
		var result_h: float=clampf((owned_y-y)*.4,92,135)
		var size: float=minf(82,owned_y-18-result_h-32-(y+21))
		var result_y: float=y+21+size+25
		for i in 2:
			var r: Rect2=Rect2(84+i*102-size/2,y+21,size,size)
			m._ui_style_box(m.hud_reference_style,r);m._ui_rect(r.grow(-4),Color("092b39"))
			m._ui_texture_rect(textures[EFILES[int(pair[i])]],r.grow(-8))
			if pair_slot==i: m._ui_rect(r.grow(-2),Color("3bf2e1"),false,1)
			m._text(data.ELEMENTS[int(pair[i])],r.get_center()+Vector2(0,size/2+12),9,Color("382619"),true,63)
			rects["pair:%d"%i]=r
		var plus: Vector2=Vector2(135,y+21+size/2)
		m._ui_rect(Rect2(plus-Vector2(8,3),Vector2(16,6)),Color("54270f"));m._ui_rect(Rect2(plus-Vector2(3,8),Vector2(6,16)),Color("54270f"))
		m._ui_rect(Rect2(plus-Vector2(6,1),Vector2(12,2)),Color("b97b44"));m._ui_rect(Rect2(plus-Vector2(1,6),Vector2(2,12)),Color("b97b44"))
		m._text("▼",Vector2(135,result_y-6),11,Color("d79825"),true,20)
		var box: Rect2=Rect2(66,result_y,138,result_h)
		m._ui_style_box(m.hud_reference_style,box);m._ui_rect(box.grow(-5),Color("07505a"))
		m._ui_rect(Rect2(box.position+Vector2(13,21),Vector2(box.size.x-26,box.size.y-42)),Color("082c35"))
		m._ui_style_box(m.hud_reference_style,Rect2(box.position+Vector2(14,-4),Vector2(110,19)))
		m._text("결과 미리보기",Vector2(135,result_y+9),10,Color("fff0d1"),true,104)
		var id: int=data.recipe(int(pair[0]),int(pair[1]));var u: Dictionary=data.catalog.soldiers[id]
		if data.is_discovered(id):
			sprite(m,id,Rect2(box.position+Vector2(36,18),Vector2(66,result_h-40)))
			m._ui_style_box(m.sb_btn,Rect2(97,box.end.y-20,76,18))
			m._text(ROLES[u.role],Vector2(135,box.end.y-8),9,Color("382619"),true,68)
			m._text(u.name+" · "+u.description,Vector2(135,box.end.y+12),7,Color("6c553b"),true,231)
		else:
			m._text("?",box.get_center()+Vector2(0,8),28,Color("b6ccc9"),true,100)
			m._text("아직 만들지 않은 병사",Vector2(135,box.end.y+12),9,Color("6c553b"),true,231)
		rects["preview"]=box
		m._ui_style_box(m.hud_reference_style,Rect2(17,owned_y-3,70,16))
		m._text("보유 어혼",Vector2(52,owned_y+8),9,Color("fff0d1"),true,64)
		for i in 5:
			var r: Rect2=Rect2(17+i*48,owned_y+16,44,40)
			m._ui_style_box(m.hud_reference_style,r);m._ui_rect(r.grow(-3),Color("092c38"))
			m._ui_texture_rect(textures[EFILES[i]],Rect2(r.position+Vector2(6,3),Vector2(30,30)))
			if i in pair: m._ui_rect(r.grow(-1),Color("27dfd6"),false,1)
			m._text(str(data.souls[i]),r.position+Vector2(35,34),8,Color("fff0d1"),true,16,true)
			m._text(data.ELEMENTS[i],r.position+Vector2(22,49),8,Color("382619"),true,42)
			rects["element:%d"%i]=r
		primary(m,"craft",Rect2(18,bottom-28,234,25),"연성하기 · 어혼 2개")
		return
	soul_row(m,y);y+=30
	var rows: int=maxi(1,mini(4,int((bottom-y-90)/56)))
	var total: int=maxi(1,ceili(data.soldiers.size()/float(rows)));page=clampi(page,0,total-1)
	for i in rows:
		var n: int=page*rows+i
		if n>=data.soldiers.size(): break
		var u: Dictionary=data.soldiers[n];var st: Dictionary=data.stats(u);var spec: Dictionary=data.catalog.soldiers[int(u.id)]
		var r: Rect2=Rect2(18,y+i*56,234,53)
		m._ui_rect(r,Color("d2b577") if int(u.uid) in selected else Color("eddbb6"));sprite(m,int(u.id),Rect2(r.position,Vector2(42,40)))
		m._text(("%s %s +%d"%["★".repeat(int(u.star)),spec.name,int(u.get("level",0))])+rarity_label(u),r.position+Vector2(44,12),8,Color("382619"),false,156 if tab==2 else 182)
		m._text("체%d 공%d 방%d · 개체 +%d/%d/%d"%[st.hp,st.atk,st.def,u.iv[0],u.iv[1],u.iv[2]],r.position+Vector2(44,25),7,Color("6c553b"),false,145 if tab==2 else 183)
		m._text(spec.description,r.position+Vector2(44,37),7,Color("6c553b"),false,145 if tab==2 else 183)
		rects["select:%d"%int(u.uid)]=r
		if tab==2:
			lock_icon(m,"lock:%d"%int(u.uid),Rect2(r.end.x-25,r.position.y,24,22),bool(u.locked))
			button(m,"upgrade:%d"%int(u.uid),Rect2(r.end.x-37,r.position.y+33,36,18),"강화")
	button(m,"prev",Rect2(18,y+rows*56+5,35,22),"‹");button(m,"next",Rect2(217,y+rows*56+5,35,22),"›")
	m._text("%d/%d · %d/60마리"%[page+1,total,data.soldiers.size()],Vector2(135,y+rows*56+20),9,Color("6c553b"),true,150)
	if tab==2:
		m._text("강화 버튼으로 육성 · 자물쇠로 잠금",Vector2(135,bottom-25),8,Color("6c553b"),true,232)
	if tab==1:
		var q: Dictionary=data.merge_cost(int(selected[0]),int(selected[1])) if selected.size()==2 else {}
		if notice!="": m._text(notice,Vector2(135,bottom-80),8,Color("9b4329"),true,232)
		elif not q.is_empty():
			m._text("어혼 %d개 + %d비늘 · 새 %d성"%[int(q.souls.reduce(func(a,b):return a+b,0)),q.gold,q.star],Vector2(135,bottom-80),8,Color("6c553b"),true,232)
		button(m,"merge_review",Rect2(22,bottom-64,226,28),"합성 결과·소모 재료 확인",not q.is_empty() and not data.active())
		m._text("같은 별 +3 병사 2마리 · 잠금 병사는 보호",Vector2(135,bottom-23),8,Color("6c553b"),true,232)

func draw_pending(m,y: float,bottom: float) -> void:
	var p: Dictionary=data.pending
	if p.kind=="craft":
		var u: Dictionary=data.unit(int(p.uid))
		if u.is_empty(): return
		sprite(m,int(u.id),Rect2(72,y+15,126,102),int(m.ui_clock*7)%int(data.catalog.soldiers[int(u.id)].frame_count))
		m._text("★".repeat(int(u.star))+" "+data.catalog.soldiers[int(u.id)].name,Vector2(135,y+140),12,Color("382619"),true,232)
		m._text("체력 +%d%% · 공격 +%d%% · 방어 +%d%%"%u.iv,Vector2(135,y+170),9,Color("855c26"),true,232)
		m._text(data.catalog.soldiers[int(u.id)].description,Vector2(135,y+196),9,Color("6c553b"),true,232)
		if int(u.star)==3: m._text(["레어","유니크","전설"][int(u.rarity)],Vector2(135,y+222),13,Color("a96d23"),true,232)
		button(m,"pending_done",Rect2(22,bottom-55,226,30),"병사 보관함으로")
	elif p.kind=="merge":
		sprite(m,int(p.id),Rect2(94,y,82,69))
		m._text("새 %d성 %s"%[p.star,data.catalog.soldiers[int(p.id)].name],Vector2(135,y+87),11,Color("382619"),true,230)
		m._text("계승할 개체값 한 묶음을 고르세요",Vector2(135,y+112),10,Color("6c553b"),true,230)
		for i in 3:
			var iv: Array=p.ivs[i]
			button(m,"inherit:%d"%i,Rect2(20,y+130+i*46,230,38),"%s  체+%d%% 공+%d%% 방+%d%%"%[["재료 A","재료 B","새 개체"][i],iv[0],iv[1],iv[2]])
		m._text("종료해도 결과와 선택지는 그대로 보존돼요",Vector2(135,bottom-22),8,Color("6c553b"),true,232)

func input_event(m,e: InputEvent) -> bool:
	if opened=="": return false
	if e is InputEventMouseButton and e.button_index==MOUSE_BUTTON_LEFT:
		var pos: Vector2=e.position-Vector2(m.ox,0)
		if e.pressed:
			drag_start=pos;drag_pos=pos;drag_slot=-1
			for i in 3:
				if not data.active() and rects.get("slot:%d"%i,Rect2()).has_point(pos) and i<data.team.size(): drag_slot=i
		else:
			if drag_slot>=0 and drag_start.distance_to(pos)>8:
				for i in data.team.size():
					if rects.get("slot:%d"%i,Rect2()).has_point(pos):
						var uid=data.team[drag_slot];data.team[drag_slot]=data.team[i];data.team[i]=uid;m._save_game();break
			else: press(m,pos)
			drag_slot=-1
	elif e is InputEventMouseMotion: drag_pos=e.position-Vector2(m.ox,0)
	return true

func press(m,pos: Vector2) -> void:
	var key: String=""
	# Small lock controls take priority over their containing row.
	for k in rects:
		if (str(k).begins_with("lock:") or str(k).begins_with("upgrade:")) and rects[k].has_point(pos): key=k;break
	if key=="":
		for k in rects:
			if rects[k].has_point(pos): key=k;break
	notice=""
	if key=="close": opened="";choosing_slot=-1;return
	if key=="roster": opened="alchemy";tab=2;page=0;return
	if key=="go_alchemy": open(m,"alchemy");return
	if key=="go_explore": open(m,"explore");return
	if key.begins_with("explore_tab:"): explore_tab=int(key.split(":")[1]);page=0;choosing_slot=-1;return
	if key.begins_with("formation_unit:"):
		if data.active(): m.show_toast("탐험 중에는 편성을 바꿀 수 없어요",Color("ffdc96"));return
		var uid: int=int(key.split(":")[1])
		if uid in data.team: data.team.erase(uid)
		elif choosing_slot>=0 and choosing_slot<data.team.size(): data.team[choosing_slot]=uid
		elif data.team.size()<3: data.team.append(uid)
		else: m.show_toast("바꿀 편성 칸을 위에서 선택하세요",Color("ffdc96"))
		choosing_slot=-1;m._save_game();return
	if key.begins_with("upgrade:"): training_uid=int(key.split(":")[1]);opened="training";return
	if key=="roster_close": choosing_slot=-1;return
	if key=="remove_slot":
		if choosing_slot<data.team.size(): data.team.remove_at(choosing_slot)
		choosing_slot=-1;m._save_game();return
	if key=="prev": page=maxi(0,page-1);return
	if key=="next": page+=1;return
	if key=="minimize": opened="";m.start_trans("village") if m.scene!="village" else m.play("ui");return
	if key.begins_with("round:"):
		var n: int=int(key.split(":")[1])
		if n<=data.unlocked: selected_round=n
		else: notice="이전 라운드를 먼저 완료하세요"
	elif key.begins_with("slot:"):
		var i: int=int(key.split(":")[1])
		choosing_slot=i;page=0
	elif key.begins_with("unit:"):
		var uid: int=int(key.split(":")[1])
		if choosing_slot>=0:
			var previous: int=data.team.find(uid)
			if choosing_slot<data.team.size():
				if previous>=0: data.team[previous]=data.team[choosing_slot]
				data.team[choosing_slot]=uid
			elif previous<0 and data.team.size()<3: data.team.append(uid)
			choosing_slot=-1
		elif uid in data.team: data.team.erase(uid)
		elif data.team.size()<3: data.team.append(uid)
	elif key=="start":
		if data.start(selected_round,Time.get_unix_time_from_system()):
			opened="";m.start_trans("village") if m.scene!="village" else m.play("ui")
		else: notice="병사 3마리를 편성하고 회복을 기다리세요"
	elif key=="claim":
		var reward: Dictionary=data.claim()
		if not reward.is_empty(): m.gold+=int(reward.gold);notice="%d비늘 획득"%reward.gold
	elif key.begins_with("tab:"): tab=int(key.split(":")[1]);page=0;selected=[]
	elif key.begins_with("element:"): pair[pair_slot]=int(key.split(":")[1]);pair_slot=1-pair_slot
	elif key.begins_with("pair:"): pair_slot=int(key.split(":")[1])
	elif key=="craft":
		if not data.craft(int(pair[0]),int(pair[1])): notice="어혼이 부족하거나 보관함이 가득해요"
	elif key.begins_with("select:") and tab==2:
		training_uid=int(key.split(":")[1]);opened="training"
	elif key=="train":
		var cost: Dictionary=data.train(training_uid,m.gold)
		if cost.is_empty(): notice="어혼·비늘을 확인해 주세요. 탐험 중에는 강화할 수 없어요"
		else: m.gold-=int(cost.gold);notice="강화 완료! +%d"%int(data.unit(training_uid).level)
	elif key=="training_back": opened="alchemy";tab=2
	elif key.begins_with("select:") and tab==1:
		var uid: int=int(key.split(":")[1])
		if uid in selected: selected.erase(uid)
		elif int(data.unit(uid).get("level",0))!=3: notice="+3까지 강화한 병사만 합성할 수 있어요"
		elif bool(data.unit(uid).locked): notice="잠금을 먼저 풀어 주세요"
		elif selected.size()<2: selected.append(uid)
	elif key.begins_with("lock:"):
		var u: Dictionary=data.unit(int(key.split(":")[1]));u.locked=not u.locked
	elif key=="merge_review" and selected.size()==2:
		var q: Dictionary=data.merge_cost(int(selected[0]),int(selected[1]))
		if not q.is_empty() and not data.active():
			opened="merge_confirm";notice="";return
	elif key=="merge_cancel": opened="alchemy"
	elif key=="merge_confirm":
		if selected.size()==2:
			var q: Dictionary=data.begin_merge(int(selected[0]),int(selected[1]),m.gold)
			if q.is_empty(): notice="어혼·비늘 부족 또는 잠금 병사예요"
			else: m.gold-=int(q.gold);selected=[];opened="alchemy"
	elif key.begins_with("inherit:"): data.finish_merge(int(key.split(":")[1]))
	elif key=="pending_done": data.pending={};opened="alchemy";tab=2;page=maxi(0,ceili(data.soldiers.size()/4.0)-1)
	if notice!="": m.show_toast(notice,Color("ffdc96"))
	m._save_game()

func draw_confirmation(m,y: float,bottom: float) -> void:
	var q: Dictionary=data.merge_cost(int(selected[0]),int(selected[1]))
	m._text("두 병사가 소모됩니다",Vector2(135,y+15),13,Color("9b4329"),true,230)
	for i in 2:
		var u: Dictionary=data.unit(int(selected[i]));sprite(m,int(u.id),Rect2(41+i*108,y+24,80,65))
		m._text(data.catalog.soldiers[int(u.id)].name,Vector2(81+i*108,y+105),9,Color("382619"),true,104)
	m._text("가능한 결과 · 각 동일 확률",Vector2(135,y+133),10,Color("382619"),true,230)
	for i in q.candidates.size():
		var id: int=int(q.candidates[i]);m._text(data.catalog.soldiers[id].name,Vector2(135,y+154+i*17),9,Color("6c553b"),true,230)
	var cost: String=""
	for i in 5:
		if int(q.souls[i])>0: cost+="%s %d "%[data.ELEMENTS[i],q.souls[i]]
	m._text("어혼 "+cost+"· %d비늘"%q.gold,Vector2(135,bottom-100),9,Color("6c553b"),true,230)
	if int(q.star)==3: m._text("3성: 레어75% / 유니크20% / 전설5%",Vector2(135,bottom-81),8,Color("6c553b"),true,230)
	button(m,"merge_cancel",Rect2(20,bottom-60,109,29),"돌아가기")
	button(m,"merge_confirm",Rect2(139,bottom-60,109,29),"소모하고 합성")

func lock_icon(m,key: String,r: Rect2,locked: bool) -> void:
	var c: Vector2=r.position+Vector2(6,5)
	var ink: Color=Color("65451b") if locked else Color("545a5c")
	var fill: Color=Color("ffd65b") if locked else Color("a0aaad")
	var shift: float=0 if locked else 4
	m._ui_rect(Rect2(c+Vector2(2+shift,0),Vector2(9,10)),ink)
	m._ui_rect(Rect2(c+Vector2(4+shift,2),Vector2(5,8)),fill)
	m._ui_rect(Rect2(c+Vector2(5+shift,4),Vector2(3,7)),Color("eddbb6"))
	m._ui_rect(Rect2(c+Vector2(0,8),Vector2(14,11)),ink)
	m._ui_rect(Rect2(c+Vector2(1,9),Vector2(12,9)),fill)
	m._ui_rect(Rect2(c+Vector2(6,11),Vector2(2,4)),ink)
	rects[key]=r

func draw_training(m,y: float,bottom: float) -> void:
	var u: Dictionary=data.unit(training_uid)
	if u.is_empty(): return
	var st: Dictionary=data.stats(u)
	var cost: Dictionary=data.training_cost(training_uid)
	sprite(m,int(u.id),Rect2(89,y+10,92,80),int(m.ui_clock*7)%int(data.catalog.soldiers[int(u.id)].frame_count))
	m._text(data.catalog.soldiers[int(u.id)].name+" +%d"%int(u.get("level",0)),Vector2(135,y+112),12,Color("382619"),true,228)
	m._text("체력 %d · 공격 %d · 방어 %d"%[st.hp,st.atk,st.def],Vector2(135,y+138),10,Color("6c553b"),true,228)
	m._text("강화는 확정 성공 · 최대 +3",Vector2(135,y+165),9,Color("6c553b"),true,228)
	if not cost.is_empty():
		var next: Dictionary=u.duplicate(true);next.level=int(u.get("level",0))+1
		var ns: Dictionary=data.stats(next)
		m._text("+%d → 체력 %d · 공격 %d · 방어 %d"%[int(next.level),ns.hp,ns.atk,ns.def],Vector2(135,y+191),9,Color("382619"),true,228)
		m._text("%s 어혼 %d개 · %d비늘"%[data.ELEMENTS[int(cost.element)],cost.souls,cost.gold],Vector2(135,bottom-101),10,Color("6c553b"),true,228)
		button(m,"train",Rect2(22,bottom-83,226,30),"+%d 강화하기"%int(next.level),not data.active())
	else: m._text("최대 강화 완료",Vector2(135,y+195),12,Color("aa7620"),true,228)
	button(m,"training_back",Rect2(22,bottom-43,226,28),"병사 보관함으로")

func draw_result_notice(m) -> void:
	if m.scene=="village" or result_notice<=0 or data.battle.is_empty() or data.active(): return
	var r: Rect2=Rect2(43,m.top_y+72,184,24)
	m._ui_style_box(m.sb_chip,r)
	m._text("탐험 성공 · 마을에서 결과 확인" if data.battle.status=="win" else "탐험 실패 · 마을에서 결과 확인",r.get_center()+Vector2(0,3),8,Color("fff0d1"),true,174)

func draw_formation(m,y: float,bottom: float) -> void:
	for i in 3:
		var r: Rect2=Rect2(18+i*80,y+15,74,54)
		m._text(["앞 · 방어","중간","뒤"][i],Vector2(r.get_center().x,y+8),9,Color("6c553b"),true,74)
		m._ui_style_box(m.sb_btn,r)
		if choosing_slot==i: m._ui_rect(r.grow(-2),Color("169f9d"),false,1)
		if i<data.team.size():
			var u: Dictionary=data.unit(int(data.team[i]));sprite(m,int(u.id),Rect2(r.position+Vector2(14,1),Vector2(46,39)))
			m._text("★".repeat(int(u.star))+" +%d"%int(u.get("level",0)),Vector2(r.get_center().x,r.end.y-5),8,Color("382619"),true,66)
		else: m._text("빈 칸",r.get_center()+Vector2(0,4),9,Color("796044"),true,68)
		rects["slot:%d"%i]=r
	m._text("탐험 중 · 편성 변경 불가" if data.active() else "아래 병사를 눌러 편성 / 다시 눌러 해제",Vector2(135,y+85),8,Color("6c553b"),true,234)
	var list_y: float=y+95
	var rows: int=maxi(1,mini(5,int((bottom-list_y-39)/44)))
	var total: int=maxi(1,ceili(data.soldiers.size()/float(rows)));page=clampi(page,0,total-1)
	for i in rows:
		var n: int=page*rows+i
		if n>=data.soldiers.size(): break
		var u: Dictionary=data.soldiers[n];var spec: Dictionary=data.catalog.soldiers[int(u.id)]
		var r: Rect2=Rect2(18,list_y+i*44,234,41)
		m._ui_rect(r,Color("c4ddbb") if int(u.uid) in data.team else Color("eddbb6"))
		sprite(m,int(u.id),Rect2(r.position,Vector2(42,39)))
		m._text(spec.name+" +%d"%int(u.get("level",0))+rarity_label(u),r.position+Vector2(44,13),8,Color("382619"),false,180)
		m._text(ROLES[spec.role]+" · "+("편성 중 · 누르면 해제" if int(u.uid) in data.team else "누르면 편성"),r.position+Vector2(44,29),8,Color("6c553b"),false,180)
		rects["formation_unit:%d"%int(u.uid)]=r
	button(m,"prev",Rect2(18,bottom-30,35,23),"‹");button(m,"next",Rect2(217,bottom-30,35,23),"›")
	m._text("%d / %d"%[page+1,total],Vector2(135,bottom-14),9,Color("6c553b"),true,140)

func health_bar(m,r: Rect2,hp: float,maximum: float,previous: float,color: Color) -> void:
	m._ui_rect(r,Color("33251e"))
	var inner: Rect2=r.grow(-1)
	m._ui_rect(inner,Color("563d34"))
	m._ui_rect(Rect2(inner.position,Vector2(inner.size.x*clampf(previous/maxf(1,maximum),0,1),inner.size.y)),Color("f5cd87"))
	m._ui_rect(Rect2(inner.position,Vector2(inner.size.x*clampf(hp/maxf(1,maximum),0,1),inner.size.y)),color)

func floating_value(m,at: Vector2,value: String,color: Color,age: float) -> void:
	if value=="-0" or age<0 or age>.75: return
	var pos: Vector2=(at-Vector2(0,age*8)).round()
	color.a=1-smoothstep(.48,.75,age)
	for offset in [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1)]: m._text(value,pos+offset,9,Color(0.12,.09,.08,color.a),true,64)
	m._text(value,pos,9,color,true,64)
