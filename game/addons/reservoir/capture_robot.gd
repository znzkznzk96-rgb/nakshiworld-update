extends RefCounted
const RATES := [12,16,20,24,28,32,36,42,48,54,60,66,72]
const COSTS := [240,360,480,2000,3000,4000,390000,390000,1100000,1100000,2600000,2600000]
const GATES := [0,0,0,0,1,1,1,2,3,4,4,5,5]
const CAPS := [20,30,40,50,60]
const CAP_COST := [300,800,1800,4000]
const PREC_COST := [12000,65000,210000]
const ART = preload("res://art/ui/capture_robot_b/motions.png")
const SLEEP = preload("res://art/ui/capture_robot_b/sleep.png")
const CAPTURE = preload("res://art/ui/capture_robot_b/capture.png")
const SUCCESS = preload("res://art/ui/capture_robot_b/success.png")
const FULL = preload("res://art/ui/capture_robot_b/full.png")
const WATER_BACKDROP = preload("res://art/bg/reservoir_approved.png")
const WORKSHOP = preload("res://art/ui/capture_robot_b/workshop.png")
const LICENSE = preload("res://art/rewards67/license_0.png")
const PARTS = [preload("res://art/ui/capture_robot_b/speed.png"),preload("res://art/ui/capture_robot_b/storage.png"),preload("res://art/ui/capture_robot_b/precision.png")]
var icon_art = preload("res://addons/reservoir/robot_icon_art.gd").new()
var shop_tab := 0
var visual_time := 0.0
var visual_bounds := {}

var owned := false
var enabled := false
var speed := 0
var capacity := 0
var precision := 0
var escrow := 0.0
var progress := 0.0
var job: Dictionary = {}
var fish: Array = []
var opened := false
var button := Rect2()
var rects := {}
var flash := 0.0
var since_save := 0.0
var notice := ""

func serialize() -> Dictionary:
	return {"owned":owned,"enabled":enabled,"speed":speed,"capacity":capacity,"precision":precision,"escrow":escrow,"progress":progress,"job":job.duplicate(true),"fish":fish.duplicate(true)}
func valid_fish(f: Variant) -> bool:
	return f is Dictionary and int(f.get("sp",-1)) in range(40) and int(f.get("star",-1)) in range(4) and int(f.get("grade",-1)) in range(4) and is_finite(float(f.get("w",0))) and float(f.get("w",0))>0
func restore(d: Dictionary) -> void:
	owned=bool(d.get("owned",false));enabled=owned and bool(d.get("enabled",false))
	speed=clampi(int(d.get("speed",0)),0,RATES.size()-1);capacity=clampi(int(d.get("capacity",0)),0,CAPS.size()-1);precision=clampi(int(d.get("precision",0)),0,3)
	escrow=clampf(float(d.get("escrow",0)),0,1);progress=maxf(0,float(d.get("progress",0)))
	if not is_finite(escrow): escrow=0
	if not is_finite(progress): progress=0
	job=d.get("job",{}).duplicate(true) if d.get("job",{}) is Dictionary else {}
	if not job.is_empty() and not valid_fish(job): job={};progress=0
	if not job.is_empty(): escrow=0
	fish=[]
	for f in d.get("fish",[]):
		if valid_fish(f): fish.append(f.duplicate(true))
	if not owned: enabled=false
func make_fish(m) -> Dictionary:
	var unlocked:=0
	for slot in ["float","hook","line"]:
		if m.region_shop.has_active(m,slot,m.active_region): unlocked+=1
		else: break
	var top:=mini(precision,unlocked)
	var base: Array=m.STAR_P if m.active_region==0 else m.OTHER_REGION_STAR_P
	var weights: Array=[]
	var ratio: float=maxf(.7,m.pond_stock/m.pond_max())
	for i in 5: weights.append(float(base[i])*pow(.04+.96*ratio,i) if i<=top else 0.0)
	var star: int=m.pick(weights)
	var grades: Array=(m.GRADE_P if m.active_region==0 else m.OTHER_REGION_GRADE_P).duplicate()
	for g in range(precision+1,5): grades[0]+=grades[g];grades[g]=0.0
	var grade: int=m.pick(grades)
	var list: Array=m.CATALOG.by_star(m.active_region,star)
	var sp: int=list[randi()%list.size()]
	# Robot average-sized fish; preserve normal per-species valuation without forge bonus.
	var price: int=roundi(m.fish_price(sp,star,grade,1.0)/(1.0+.05*m.forge_lv))
	return {"sp":sp,"star":star,"grade":grade,"len":float(m.FISH_LEN[sp]),"w":float(m.W_BASE[star])*float(m.W_GRADE[grade]),"price":price,"shoulder":false,"robot":true}
func checkpoint(m,before: Dictionary,stock_before: float) -> bool:
	if m._save_game(): since_save=0;return true
	restore(before);m.pond_stock=stock_before;enabled=false
	notice="저장 실패 · 작동을 멈췄어요"
	return false
func update(m,dt: float) -> void:
	visual_time+=dt
	flash=maxf(0,flash-dt)
	if not owned or not enabled or fish.size()>=CAPS[capacity]: return
	var before:=serialize();var stock_before: float=m.pond_stock
	since_save+=dt
	if job.is_empty():
		var take: float=minf(m.pond_stock,1.0-escrow)
		m.pond_stock-=take;escrow+=take
		if escrow<1.0-0.000001:
			if since_save>=15: checkpoint(m,before,stock_before)
			return
		escrow=0;progress=0;job=make_fish(m)
		if not checkpoint(m,before,stock_before): return
		before=serialize();stock_before=m.pond_stock
	progress+=dt
	if progress>=3600.0/RATES[speed]:
		fish.append(job);job={};progress=0;flash=2.0
		checkpoint(m,before,stock_before)
	elif since_save>=15: checkpoint(m,before,stock_before)
func can_level(m,level: int) -> bool:
	return level in m.progression.available_regions and m.progression.licensed(level)
func transact(m,action: String) -> bool:
	var old:=serialize();var gold: int=m.gold;var bag: Array=m.bag.duplicate(true)
	var dex: Dictionary=m.DEX.duplicate(true);var counts: Dictionary=m.catch_counts.duplicate(true)
	match action:
		"buy":
			if owned or m.gold<1000: return false
			m.gold-=1000;owned=true;enabled=true
		"speed":
			if not owned or speed>=COSTS.size() or not can_level(m,GATES[speed+1]) or m.gold<COSTS[speed]: return false
			m.gold-=COSTS[speed];speed+=1
		"capacity":
			if not owned or capacity>=CAP_COST.size() or m.gold<CAP_COST[capacity]: return false
			m.gold-=CAP_COST[capacity];capacity+=1
		"precision":
			if not owned or precision>=PREC_COST.size() or not m.progression.licensed(precision+1) or m.gold<PREC_COST[precision]: return false
			m.gold-=PREC_COST[precision];precision+=1
		"toggle":
			if not owned: return false
			enabled=not enabled
		"collect":
			var left: Array=[];var count:=0
			for f in fish:
				if m.bag_weight()+float(f.w)<=m.bag_cap()+0.00001:
					m.bag.append(f.duplicate(true));count+=1
					var key: String=m.fish_key(int(f.sp))
					var seen: Array=m.DEX.get(key,[])
					if int(f.grade) not in seen: seen.append(int(f.grade))
					m.DEX[key]=seen
					var caught: Array=m.catch_counts.get(key,[0,0,0,0,0])
					caught[int(f.grade)]+=1;m.catch_counts[key]=caught
				else: left.append(f)
			fish=left
			notice="%d마리 받았어요"%count if count>0 else "가방 공간이 부족해요"
		_ : return false
	if m._save_game(): return true
	restore(old);m.gold=gold;m.bag=bag;m.DEX=dex;m.catch_counts=counts;notice="저장 실패 · 다시 시도해 주세요";return false
func action(m,a: String) -> bool:
	if not a.begins_with("robot:"): return false
	var key:=a.get_slice(":",1)
	if key.begins_with("tab_"): shop_tab=clampi(int(key.trim_prefix("tab_")),0,2)
	else: transact(m,key)
	return true
func row(m,r: Rect2,label: String,key: String) -> void:
	m._ui_style_box(m.sb_btn,r);m._text(label,r.get_center()+Vector2(0,4),10,Color("493421"),true,r.size.x-12)
	rects[key]=r
func motion_frame(state: int) -> int:
	if state==0: return int(visual_time/0.19)%9
	if state==1: return int(visual_time/0.14)%9
	return clampi(int((2.0-flash)/0.18),0,8)
func draw_robot(m,r: Rect2,state: int=0) -> void:
	m._ui_texture_rect_region(ART,r,Rect2(motion_frame(state)*160,state*80,160,80))
func draw_shop(m,r: Rect2,y: float) -> void:
	rects={};visual_bounds={}
	var x:=r.position.x+12
	var w:=r.size.x-24
	var available:=r.end.y-y-9
	var hero_h:=clampf(available-232,31,92)
	var hero:=Rect2(x,y,w,hero_h)
	# Reuse the approved lake artwork. Crop to the panel aspect, never tile/stretch.
	var source_w:=540.0
	var source_h:=source_w*hero.size.y/hero.size.x
	var source:=Rect2(395,650-source_h*.45,source_w,source_h)
	m._ui_texture_rect_region(WATER_BACKDROP,hero,source)
	m._ui_rect(Rect2(x+4,y+3,82,minf(31,hero_h-4)),Color(.94,.96,.86,.88))
	m._text("포획 로봇",Vector2(x+12,y+14),11,Color("173b4b"))
	m._text("보유 중" if owned else "구매 전",Vector2(x+12,y+28),8,Color("254e5a"))
	draw_robot(m,Rect2(x+w-102,y+maxf(0,(hero_h-48)/2),96,48))
	visual_bounds.hero=hero
	y+=hero_h+5
	if not owned:
		m._text("접속 중 자동 포획",Vector2(x+w/2,y+20),12,Color("493421"),true)
		m._text("시간당 12마리 · 보관 20마리",Vector2(x+w/2,y+42),10,Color("68533d"),true,w)
		m._text("강화로 속도·보관·포획 등급 성장",Vector2(x+w/2,y+64),9,Color("68533d"),true,w)
		var buy:=Rect2(x,y+82,w,34)
		m._ui_style_box(m.sb_btn,buy)
		m._ui_texture_rect(m.icons.scale,Rect2(x+10,buy.position.y+8,16,18))
		m._text("1,000",Vector2(x+31,buy.position.y+21),11,Color("493421"))
		m._text("로봇 구매",Vector2(x+w-48,buy.position.y+21),11,Color("493421"),true,83)
		rects.buy=buy
	else:
		var names: Array=["속도","보관","정밀"]
		var values: Array=["%d마리/h"%RATES[speed],"%d마리"%CAPS[capacity],"★%d %s"%[precision+1,m.GRADE_N[precision]]]
		for i in 3:
			var tr:=Rect2(roundf(x+i*(w+3)/3),y,floorf((w-6)/3),72)
			m._ui_style_box(m.V.shop_styles.forge.header if i==shop_tab else m.V.shop_styles.forge.card,tr)
			var icon_box:=Rect2(tr.position+Vector2((tr.size.x-34)/2,7),Vector2(34,30))
			visual_bounds["tab_icon_%d"%i]=icon_art.draw(m,["speed","storage","precision"][i],icon_box)
			visual_bounds["tab_%d"%i]=tr
			var ink:=Color("fff0d1") if i==shop_tab else Color("493421")
			m._text(names[i],tr.position+Vector2(tr.size.x/2,51),10,ink,true,tr.size.x-6)
			m._text(values[i],tr.position+Vector2(tr.size.x/2,64),8,ink,true,tr.size.x-6)
			rects["tab_%d"%i]=tr
		y+=77
		var detail:=Rect2(x,y,w,112)
		m._ui_style_box(m.V.shop_styles.forge.card,detail)
		m._text(["포획 속도 강화","보관 공간 강화","정밀 장치 강화"][shop_tab],Vector2(x+w/2,y+15),11,Color("493421"),true,w-12)
		var maxed: bool=[speed>=COSTS.size(),capacity>=CAP_COST.size(),precision>=PREC_COST.size()][shop_tab]
		var cost: int=0
		var gate:=0
		var allowed:=true
		var after: String="최대 단계"
		if not maxed:
			match shop_tab:
				0: cost=COSTS[speed];gate=GATES[speed+1];allowed=can_level(m,gate);after="%d마리/h"%RATES[speed+1]
				1: cost=CAP_COST[capacity];after="%d마리"%CAPS[capacity+1]
				2: cost=PREC_COST[precision];gate=precision+1;allowed=m.progression.licensed(gate);after="★%d %s"%[precision+2,m.GRADE_N[precision+1]]
		m._text("현재",Vector2(x+w*.25,y+31),8,Color("866449"),true)
		m._text("강화 후",Vector2(x+w*.75,y+31),8,Color("338a85"),true)
		m._text(values[shop_tab],Vector2(x+w*.25,y+46),11,Color("493421"),true,w*.43)
		m._text("→",Vector2(x+w*.5,y+45),11,Color("987145"),true)
		m._text(after,Vector2(x+w*.75,y+46),11,Color("267c78"),true,w*.43)
		m._ui_texture_rect(LICENSE,Rect2(x+8,y+53,24,18))
		var requirement: String="최대 단계입니다" if maxed else ("현재 강화 가능" if allowed else "라이선스 %d 필요"%gate)
		m._text(requirement,Vector2(x+38,y+66),9,Color("68533d") if allowed else Color("a04d3e"),false,w-45)
		var pay:=Rect2(x+7,y+78,w-14,27)
		m._ui_style_box(m.sb_btn,pay)
		m._ui_texture_rect(m.icons.scale,Rect2(pay.position+Vector2(5,6),Vector2(14,16)))
		m._text("—" if maxed else str(cost),pay.position+Vector2(23,18),10,Color("493421"),false,w*.4-20)
		var buy:=Rect2(x+w*.5,y+78,w*.5-7,27)
		m._ui_style_box(m.V.shop_styles.forge.header,buy)
		m._text("완료" if maxed else ("강화" if allowed else "잠김"),buy.get_center()+Vector2(0,4),10,Color("fff0d1"),true,buy.size.x-6)
		if not maxed and allowed: rects[["speed","capacity","precision"][shop_tab]]=buy
		visual_bounds.detail=detail
		y+=117
		var storage:=Rect2(x,y,w,29)
		m._ui_style_box(m.V.shop_styles.forge.card,storage)
		icon_art.draw(m,"full",Rect2(x+5,y+4,28,20))
		m._text("보관함 %d/%d"%[fish.size(),CAPS[capacity]],Vector2(x+36,y+19),10,Color("493421"),false,w-93)
		row(m,Rect2(x+w-54,y+3,50,23),"확인","manage")
		visual_bounds.storage=storage
	for key in rects: m.V.rects.rows.append([rects[key],"robot:"+key])
func surface_layout(m) -> Dictionary:
	var water: float=m.WATER+m.oy
	var t:=visual_time*TAU/3.2
	var bob:=sin(t)*1.5
	var follow:=sin(t-0.12)*1.5
	var center:=Vector2(237,water-2+bob)
	# Content-led size: a 44x30 icon, or Zzz plus a separate fixed timer.
	return {"robot":Rect2(center-Vector2(27,17),Vector2(54,27)),"bubble":Rect2(196,water-66+follow,68,40),"water":water}
func draw_bubble(m,r: Rect2) -> void:
	# Crisp stepped corners and a short pixel tail, moving together with all contents.
	m._ui_rect(r,Color("593720"))
	m._ui_rect(r.grow(-1),Color("dfa654"))
	m._ui_rect(r.grow(-2),Color("fff1ce"))
	m._ui_rect(Rect2(r.get_center().x-3,r.end.y,6,2),Color("593720"))
	m._ui_rect(Rect2(r.get_center().x-2,r.end.y-1,4,2),Color("fff1ce"))
	m._ui_rect(Rect2(r.get_center().x-1,r.end.y+1,2,1),Color("593720"))
func draw_surface(m) -> void:
	button=Rect2()
	if not owned or m.scene!="fish" or m.S.phase in ["fight","hook","catch"] or m.market_open or m.settings_open or m.menu_open: return
	var layout:=surface_layout(m)
	var robot: Rect2=layout.robot
	var bubble: Rect2=layout.bubble
	button=robot.merge(bubble).grow(3)
	var state:=0
	if enabled and flash>0: state=2
	elif enabled and not job.is_empty() and fish.size()<CAPS[capacity]: state=1
	draw_robot(m,robot,state)
	# Ripples belong to the fixed scene waterline, never to the bobbing sprite.
	var water: float=layout.water
	m._ui_line(Vector2(215,water),Vector2(223,water),Color(.45,.8,.94,.65),1)
	m._ui_line(Vector2(251,water+1),Vector2(260,water+1),Color(.45,.8,.94,.55),1)
	draw_bubble(m,bubble)
	var p:=bubble.position.round()
	var box:=Rect2(p+Vector2(10,5),Vector2(48,30))
	if not enabled:
		icon_art.draw(m,"sleep",Rect2(p+Vector2(5,5),Vector2(29,28)))
		m._text("OFF",p+Vector2(49,24),8,Color("68533d"),true,27)
	elif fish.size()>=CAPS[capacity]:
		icon_art.draw(m,"full",box,Color(1,1,1,.85+.15*sin(visual_time*3.0)))
	elif flash>0:
		box.position.y+=roundf(sin(visual_time*7))
		icon_art.draw(m,"success",box)
	elif job.is_empty():
		icon_art.draw(m,"sleep",Rect2(p+Vector2(5,5+roundf(sin(visual_time*3))),Vector2(29,28)))
		var seconds:=ceili((1-escrow)*3600/maxf(1,m.pond_recovery()))
		m._text("%d초"%seconds,p+Vector2(49,24),8,Color("493421"),true,28)
	else:
		box.position.y+=roundf(sin(visual_time*7))
		icon_art.draw(m,"capture",box)
func draw_panel(m,h: float) -> void:
	if not opened: return
	rects={};var r:=Rect2(16,maxf(80,(h-250)/2),238,250)
	m._ui_rect(Rect2(0,0,270,h),Color(0,0,0,.65));m._ui_style_box(m.sb_panel,r)
	m._text("포획 로봇",r.position+Vector2(119,26),14,Color("493421"),true)
	draw_robot(m,Rect2(r.position+Vector2(71,37),Vector2(96,48)))
	m._text("%d마리/h · 보관 %d/%d"%[RATES[speed],fish.size(),CAPS[capacity]],r.position+Vector2(119,108),11,Color("493421"),true,216)
	row(m,Rect2(r.position+Vector2(15,124),Vector2(98,30)),"작동 ON" if enabled else "작동 OFF","toggle")
	row(m,Rect2(r.position+Vector2(125,124),Vector2(98,30)),"모두 받기","collect")
	m._text(notice if notice!="" else "접속 중 작동 · 강화는 대장간에서",r.position+Vector2(119,177),9,Color("68533d"),true,210)
	row(m,Rect2(r.position+Vector2(15,198),Vector2(208,30)),"닫기","close")
func press(m,pos: Vector2) -> bool:
	if opened:
		for key in rects:
			if rects[key].has_point(pos):
				if key=="close": opened=false
				else: transact(m,key)
				return true
		return true
	if m.scene=="fish" and not button.size.is_zero_approx() and button.has_point(pos) and not m.market_open and not m.settings_open and m.S.phase not in ["fight","hook","catch"]:
		opened=true;m.holding=false;return true
	return false
