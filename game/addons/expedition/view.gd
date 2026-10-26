extends RefCounted
var data = preload("res://addons/expedition/model.gd").new()
var opened: String = ""
var tab: int = 0
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
const EFILES = ["water","electric","poison","light","dark"]
const ROLES = {"attack":"공격","defense":"방어","support":"지원"}
const ROOMS = ["젖은 현관","비어 있는 탈의실","반복되는 세면대","꺼지지 않는 복도","거울 없는 세면실","잠긴 관리실","물소리 나는 계단","끝없는 여과실","돌아오는 복도","출구를 닮은 문"]
const WALLS = ["24596e","347c74","225f79","956526","3d366f","395472","263d70","1d6a67","704530","2e2352"]

func setup() -> void:
	for u in data.catalog.soldiers: textures[u.id]=load("res://art/expedition/%s.png"%u.id)
	for i in range(1,19):
		textures[str(i)]=[]
		for j in 7: textures[str(i)].append(load("res://art/expedition/normal%02d_%d.png"%[i,j]))
	for id in ["3R","5R","7R","10R"]: textures[id]=load("res://art/expedition/boss%s.png"%id)
	for e in EFILES: textures[e]=load("res://art/expedition/%s.png"%e)
	textures.explore=load("res://art/expedition/explore.svg")
	textures.alchemy=load("res://art/expedition/alchemy.svg")
	textures.bolt=load("res://art/expedition/bolt.png")

func open(m,screen: String) -> void:
	opened=screen;page=0;selected=[];notice="";m.menu_open=false;m.holding=false
	selected_round=mini(data.unlocked,maxi(1,selected_round))

func update(m,dt: float) -> void:
	if data.update(dt,Time.get_unix_time_from_system()): m._save_game()

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

func room(m,r: Rect2,index: int) -> void:
	var wall: Color=Color(WALLS[index%10]);m._ui_rect(r,wall.darkened(0.12))
	var horizon: float=roundf(r.position.y+r.size.y*0.68)
	m._ui_rect(Rect2(r.position.x,horizon,r.size.x,r.end.y-horizon),wall.darkened(0.55))
	for y in range(int(r.position.y)+4,int(horizon),8):
		m._ui_line(Vector2(r.position.x,y),Vector2(r.end.x,y),wall.darkened(0.25),1)
		for x in range(int(r.position.x)+((y/8)%2)*8,int(r.end.x),16): m._ui_line(Vector2(x,y),Vector2(x,mini(y+8,int(horizon))),wall.darkened(0.25),1)
	for j in 3:
		var x: float=roundf(r.position.x+r.size.x*(0.18+j*0.3))
		var w: float=maxf(7,roundf(r.size.x*0.12));var dh: float=roundf(r.size.y*0.46)
		m._ui_rect(Rect2(x,horizon-dh,w,dh),wall.lightened(0.12))
		m._ui_rect(Rect2(x+2,horizon-dh+2,w-4,dh-2),Color("142938"))
		m._ui_rect(Rect2(x-2,r.position.y+3,w+4,2),Color("ffd06d") if index%2==1 else Color("82eee3"))
	if index in [0,2,6,7]:
		for j in 3: m._ui_rect(Rect2(r.position.x+6+j*r.size.x/3,horizon+3+j%2*3,r.size.x/5,2),Color("288ea3"))
	elif index==4:
		for j in 3: m._ui_rect(Rect2(r.position.x+8+j*r.size.x/3,horizon-6,12,5),Color("b9d2c4"))
	elif index==9: m._ui_rect(Rect2(r.get_center().x-7,horizon-r.size.y*.55,14,r.size.y*.55),Color("b044ae"))

func skull(m,c: Vector2,king: bool=false) -> void:
	m._ui_rect(Rect2(c-Vector2(5,4),Vector2(10,7)),Color("efdfb6"))
	m._ui_rect(Rect2(c+Vector2(-3,3),Vector2(6,3)),Color("efdfb6"))
	for x in [-3,1]: m._ui_rect(Rect2(c+Vector2(x,-2),Vector2(2,3)),Color("302038"))
	if king:
		m._ui_rect(Rect2(c+Vector2(-6,-7),Vector2(12,3)),Color("eaaa31"))
		for x in [-6,-1,4]: m._ui_rect(Rect2(c+Vector2(x,-10),Vector2(2,4)),Color("ffd66f"))

func draw_strip(m) -> void:
	var r: Rect2=Rect2(8,m.top_y+69,254,67)
	m._ui_style_box(m.hud_reference_style,r)
	var inner: Rect2=r.grow(-5)
	var b: Dictionary=data.battle
	room(m,inner,(int(b.round)-1) if not b.is_empty() else selected_round-1)
	if b.is_empty():
		m._text("탐험대를 편성해 보세요",Vector2(135,r.position.y+28),11,Color("fff0d1"),true,230,true)
		m._text("어혼을 모아 병사를 연성할 수 있어요",Vector2(135,r.position.y+47),8,Color("e4d2ac"),true,230,true)
	else:
		battle_art(m,inner)
		var status: String="%dR · %d%%"%[int(b.round),int((float(b.cleared)/3.0)*100)] if data.active() else ("탐험 성공 · 보상 받기" if b.status=="win" else "탐험 종료 · 결과 보기")
		m._text(status,Vector2(135,r.position.y+15),9,Color("fff0d1"),true,230,true)
	rects.strip=r

func battle_art(m,r: Rect2) -> void:
	var b: Dictionary=data.battle
	var phase: String=str(b.get("phase","approach"));var t: float=float(b.get("clock",0))
	var ground: float=r.end.y-2
	for i in b.fighters.size():
		var f: Dictionary=b.fighters[i]
		if int(f.hp)<=0: continue
		var u: Dictionary=data.catalog.soldiers[int(f.id)]
		var frame: int=0
		if phase=="fight": frame=mini(int(u.frame_count)-1,int(t/1.5*int(u.frame_count)))
		var x: float=r.position.x+12+(2-i)*31
		if phase=="approach": x-=8*(1-minf(1,float(b.phase_time)/.8))
		sprite(m,int(f.id),Rect2(x,ground-39,48,40),frame)
		if int(f.shield)>0: m._ui_arc(Vector2(x+25,ground-16),17,-1.5,1.5,9,Color("f5df83"),1)
		if u.id=="eel" and phase=="fight" and t>0.55 and t<1.5:
			var p: float=(t-.55)/.95
			m._ui_texture_rect(textures.bolt,Rect2(lerpf(x+30,r.end.x-28,p),ground-22,13,5))
	var e: Dictionary=b.enemy;var key: String=str(e.id)
	var is_boss: bool=key.ends_with("R");var n: int=320 if key=="10R" else (224 if is_boss else 128)
	var row: int=0;var col: int=0;var alpha: float=1
	if phase=="fight":
		if is_boss: row=1;col=mini(5,int(t/TICK_LENGTH()*6))
		else: col=1 if t<.5 else (2 if t<.8 else (3 if t<1.25 else 0))
		if t<.13 and int(b.ticks)>0: row=2 if is_boss else 0;col=0 if is_boss else 4
	elif phase=="death":
		var d: float=float(b.phase_time)
		row=3 if is_boss else 0;col=mini(5,int(d/.2)) if is_boss else (5 if d<.4 else 6)
		alpha=1.0-smoothstep(1.3,2.2,d)
	var display: float=63 if key=="10R" else (49 if is_boss else 39)
	m._ui_texture_rect_region(textures[key] if is_boss else textures[key][col],Rect2(r.end.x-display-10,ground-display,display,display),Rect2(col*n if is_boss else 0,row*n,n,n),Color(1,1,1,alpha))

func TICK_LENGTH() -> float: return 1.5

func draw(m,h: float) -> void:
	if opened=="": return
	# Hide underlying text as well as surfaces so world/shop labels cannot leak through.
	m.text_items=m.text_items.filter(func(it): return it[1].y<m.top_y+65)
	var y: float=m.top_y+69;var bottom: float=h-m.bot_pad-8
	panel(m,Rect2(6,y,258,bottom-y));rects={}
	m._ui_style_box(m.hud_reference_style,Rect2(11,y+5,248,26))
	m._text("저수지 탐사 노선도" if opened=="explore" else "어혼 연성",Vector2(125,y+22),12,Color("fff0d1"),true,208)
	button(m,"close",Rect2(233,y+8,22,20),"×")
	if not data.pending.is_empty(): draw_pending(m,y+37,bottom);return
	if opened=="merge_confirm": draw_confirmation(m,y+37,bottom)
	elif opened=="explore": draw_explore(m,y+37,bottom)
	else: draw_alchemy(m,y+37,bottom)
	if notice!="": m._text(notice,Vector2(135,bottom-9),8,Color("934d28"),true,236)

func draw_explore(m,y: float,bottom: float) -> void:
	if not data.battle.is_empty():
		var b: Dictionary=data.battle
		m._text("%dR · %s"%[int(b.round),ROOMS[int(b.round)-1]],Vector2(135,y+12),11,Color("382619"),true,230)
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
	var tile_h: float=clampf((bottom-y-176)/5,25,35)
	for idx in range(10):
		var row: int=idx/2;var col: int=idx%2 if row%2==0 else 1-idx%2
		var r: Rect2=Rect2(18+col*121,y+row*tile_h,113,tile_h-3)
		m._ui_style_box(m.hud_reference_style,r);room(m,r.grow(-3),idx)
		if idx+1>data.unlocked: m._ui_rect(r.grow(-3),Color(0.05,0.05,0.12,.68))
		if idx+1==selected_round: m._ui_rect(r,Color("ffc45a"),false,2)
		m._text("%02d"%(idx+1),r.position+Vector2(6,12),9,Color("fff0d1"),false,23,true)
		if idx+1 in [3,5,7,10]: skull(m,r.end-Vector2(14,11),idx==9)
		rects["round:%d"%(idx+1)]=r
	y+=5*tile_h
	m._text(ROOMS[selected_round-1],Vector2(135,y+10),9,Color("513b29"),true,230)
	for i in 3:
		var r: Rect2=Rect2(18+i*80,y+17,74,59)
		m._ui_style_box(m.hud_reference_style,r)
		m._text(["앞","중간","뒤"][i],r.position+Vector2(7,12),8,Color("f3d7a3"),false,25)
		if i<data.team.size():
			var u: Dictionary=data.unit(int(data.team[i]));sprite(m,int(u.id),Rect2(r.position+Vector2(13,3),Vector2(50,40)))
			m._text("★".repeat(int(u.star))+" "+ROLES[data.catalog.soldiers[int(u.id)].role],r.position+Vector2(37,50),8,Color("fff0d1"),true,67)
		else: m._text("선택",r.get_center()+Vector2(0,5),9,Color("d2b98c"),true,60)
		rects["slot:%d"%i]=r
	m._text("병사 선택 · 드래그로 순서 변경",Vector2(135,y+87),8,Color("6c553b"),true,230)
	var total: int=maxi(1,ceili(data.soldiers.size()/4.0));page=clampi(page,0,total-1)
	for i in 4:
		var n: int=page*4+i
		if n>=data.soldiers.size(): break
		var u: Dictionary=data.soldiers[n];var r: Rect2=Rect2(31+i*53,y+92,49,37)
		m._ui_rect(r,Color("bba278") if int(u.uid) in data.team else Color("e7cf9e"));sprite(m,int(u.id),r)
		rects["unit:%d"%int(u.uid)]=r
	button(m,"prev",Rect2(13,y+95,16,28),"‹");button(m,"next",Rect2(245,y+95,15,28),"›")
	var remaining: int=maxi(0,ceili(data.recovery_until-Time.get_unix_time_from_system()))
	button(m,"start",Rect2(18,bottom-43,234,27),"회복 중 %d초"%remaining if remaining>0 else "%dR 탐험 출발"%selected_round,data.team.size()==3 and remaining==0)
	if data.soldiers.is_empty(): notice="연성 탭에서 어혼 2개로 병사를 만드세요"

func soul_row(m,y: float) -> void:
	for i in 5:
		var x: float=18+i*48
		m._ui_texture_rect(textures[EFILES[i]],Rect2(x,y,23,23))
		m._text(str(data.souls[i]),Vector2(x+29,y+17),9,Color("382619"),true,23)

func draw_alchemy(m,y: float,bottom: float) -> void:
	soul_row(m,y)
	for i in 3: button(m,"tab:%d"%i,Rect2(18+i*80,y+29,74,24),["연성","합성","병사"][i],tab!=i)
	y+=62
	if tab==0:
		m._text("어혼을 하나씩 골라 조합하세요",Vector2(135,y+12),10,Color("382619"),true,230)
		for i in 5:
			var r: Rect2=Rect2(18+i*48,y+23,43,46)
			m._ui_style_box(m.sb_btn,r);m._ui_texture_rect(textures[EFILES[i]],Rect2(r.position+Vector2(8,3),Vector2(27,27)))
			m._text(data.ELEMENTS[i],r.position+Vector2(21,39),8,Color("382619"),true,38);rects["element:%d"%i]=r
		for i in 2:
			var r: Rect2=Rect2(72+i*69,y+81,57,27)
			button(m,"pair:%d"%i,r,data.ELEMENTS[int(pair[i])],true)
			if pair_slot==i: m._ui_rect(r,Color("b7812c"),false,1)
		var id: int=data.recipe(int(pair[0]),int(pair[1]));var u: Dictionary=data.catalog.soldiers[id]
		sprite(m,id,Rect2(95,y+114,80,64))
		m._text(u.name,Vector2(135,y+190),11,Color("382619"),true,230)
		m._text(u.description,Vector2(135,y+207),8,Color("6c553b"),true,230)
		button(m,"craft",Rect2(22,bottom-52,226,29),"어혼 2개 · 1성 연성")
		m._text("낚시 성공 시 25%로 해당 어종의 어혼 획득",Vector2(135,bottom-12),8,Color("6c553b"),true,230)
		return
	var rows: int=4
	var total: int=maxi(1,ceili(data.soldiers.size()/float(rows)));page=clampi(page,0,total-1)
	for i in rows:
		var n: int=page*rows+i
		if n>=data.soldiers.size(): break
		var u: Dictionary=data.soldiers[n];var st: Dictionary=data.stats(u);var spec: Dictionary=data.catalog.soldiers[int(u.id)]
		var r: Rect2=Rect2(18,y+i*45,234,42)
		m._ui_rect(r,Color("d2b577") if int(u.uid) in selected else Color("eddbb6"));sprite(m,int(u.id),Rect2(r.position,Vector2(42,40)))
		m._text("%s %s · %s"%["★".repeat(int(u.star)),spec.name,ROLES[spec.role]],r.position+Vector2(44,12),9,Color("382619"),false,182)
		m._text("체%d 공%d 방%d · 개체 +%d/%d/%d"%[st.hp,st.atk,st.def,u.iv[0],u.iv[1],u.iv[2]],r.position+Vector2(44,25),7,Color("6c553b"),false,183)
		m._text(spec.description,r.position+Vector2(44,37),7,Color("6c553b"),false,183)
		rects["select:%d"%int(u.uid)]=r
		if tab==2: button(m,"lock:%d"%int(u.uid),Rect2(r.end.x-30,r.position.y+2,28,16),"잠금" if u.locked else "보호")
	button(m,"prev",Rect2(18,y+185,35,22),"‹");button(m,"next",Rect2(217,y+185,35,22),"›")
	m._text("%d/%d · %d/60마리"%[page+1,total,data.soldiers.size()],Vector2(135,y+200),9,Color("6c553b"),true,150)
	if tab==1:
		var q: Dictionary=data.merge_cost(int(selected[0]),int(selected[1])) if selected.size()==2 else {}
		if not q.is_empty():
			m._text("어혼 %d개 + %d비늘 · 새 %d성"%[int(q.souls.reduce(func(a,b):return a+b,0)),q.gold,q.star],Vector2(135,bottom-80),8,Color("6c553b"),true,232)
		button(m,"merge_review",Rect2(22,bottom-64,226,28),"합성 결과·소모 재료 확인",not q.is_empty() and not data.active())
		m._text("동일 별 2마리 소모 · 잠금 병사는 보호",Vector2(135,bottom-23),8,Color("6c553b"),true,232)

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
				if rects.get("slot:%d"%i,Rect2()).has_point(pos) and i<data.team.size(): drag_slot=i
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
		if str(k).begins_with("lock:") and rects[k].has_point(pos): key=k;break
	if key=="":
		for k in rects:
			if rects[k].has_point(pos): key=k;break
	notice=""
	if key=="close": opened="";return
	if key=="prev": page=maxi(0,page-1);return
	if key=="next": page+=1;return
	if key=="minimize": opened="";m.start_trans("village") if m.scene!="village" else m.play("ui");return
	if key.begins_with("round:"):
		var n: int=int(key.split(":")[1])
		if n<=data.unlocked: selected_round=n
		else: notice="이전 라운드를 먼저 완료하세요"
	elif key.begins_with("slot:"):
		var i: int=int(key.split(":")[1])
		if i<data.team.size(): data.team.remove_at(i)
	elif key.begins_with("unit:"):
		var uid: int=int(key.split(":")[1])
		if uid in data.team: data.team.erase(uid)
		elif data.team.size()<3: data.team.append(uid)
		else: notice="편성 칸을 눌러 빼고 교체하세요"
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
	elif key.begins_with("select:") and tab==1:
		var uid: int=int(key.split(":")[1])
		if uid in selected: selected.erase(uid)
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
