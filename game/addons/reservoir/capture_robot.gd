extends RefCounted
const RATES := [12,16,20,24,28,32,36,42,48,54,60,66,72]
const COSTS := [240,360,480,2000,3000,4000,390000,390000,1100000,1100000,2600000,2600000]
const GATES := [0,0,0,0,1,1,1,2,3,4,4,5,5]
const CAPS := [20,30,40,50,60]
const CAP_COST := [300,800,1800,4000]
const PREC_COST := [12000,65000,210000]
const ART = preload("res://art/ui/capture_robot/robot.png")
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
	transact(m,a.get_slice(":",1));return true
func row(m,r: Rect2,label: String,key: String) -> void:
	m._ui_style_box(m.sb_btn,r);m._text(label,r.get_center()+Vector2(0,4),10,Color("493421"),true,r.size.x-12)
	rects[key]=r
func draw_shop(m,r: Rect2,y: float) -> void:
	rects={}
	m._ui_texture_rect(ART,Rect2(r.position.x+15,y,65,44),false)
	m._text("포획 로봇",Vector2(r.position.x+90,y+16),12,Color("493421"),false,130)
	m._text("접속 중 포획 · 대기 재고 1마리",Vector2(r.position.x+15,y+56),9,Color("68533d"),false,r.size.x-30)
	y+=56
	if not owned:
		m._text("시간당 12마리 · 보관 20마리",Vector2(r.position.x+15,y+12),10,Color("493421"),false,r.size.x-30)
		row(m,Rect2(r.position.x+15,y+26,r.size.x-30,30),"구매 · 1,000 비늘","buy")
	else:
		var labels: Array=["속도 %d → %d/h · %s"%[RATES[speed],RATES[mini(speed+1,RATES.size()-1)],str(COSTS[speed]) if speed<COSTS.size() else "최대"],"보관 %d → %d · %s"%[CAPS[capacity],CAPS[mini(capacity+1,CAPS.size()-1)],str(CAP_COST[capacity]) if capacity<CAP_COST.size() else "최대"],"정밀 ★%d · %s"%[precision+1,m.GRADE_N[precision]]]
		for i in 3:
			row(m,Rect2(r.position.x+15,y+i*38,r.size.x-30,30),labels[i],["speed","capacity","precision"][i])
			if i==0 and speed<COSTS.size() and not can_level(m,GATES[speed+1]): m._text("다음 라이선스 필요",Vector2(r.position.x+18,y+i*38+40),8,Color("93613e"))
			if i==2: m._text("다음: %s 비늘 · 라이선스 %d 필요"%[str(PREC_COST[precision]) if precision<3 else "최대",precision+1],Vector2(r.position.x+18,y+i*38+40),8,Color("93613e"),false,r.size.x-35)
		row(m,Rect2(r.position.x+15,r.end.y-36,r.size.x-30,28),"보관함 · %d/%d"%[fish.size(),CAPS[capacity]],"manage")
	for key in rects: m.V.rects.rows.append([rects[key],"robot:"+key])
func draw_surface(m) -> void:
	button=Rect2()
	if not owned or m.scene!="fish" or m.S.phase in ["fight","hook","catch"] or m.market_open or m.settings_open or m.menu_open: return
	var p:=Vector2(240,m.WATER+m.oy-13+sin(m.ui_clock*2)*1.2)
	m._ui_texture_rect(ART,Rect2(p-Vector2(16,6),Vector2(32,23)),false)
	button=Rect2(p-Vector2(21,25),Vector2(42,48))
	var bubble:=Rect2(p-Vector2(19,30),Vector2(38,23))
	var bubble_style:=StyleBoxFlat.new();bubble_style.bg_color=Color("fff1ce");bubble_style.border_color=Color("624227");bubble_style.set_border_width_all(1);bubble_style.set_corner_radius_all(3)
	m._ui_style_box(bubble_style,bubble)
	m._ui_polygon(PackedVector2Array([Vector2(p.x-3,bubble.end.y),Vector2(p.x+3,bubble.end.y),Vector2(p.x+1,bubble.end.y+4)]),PackedColorArray([Color("fff1ce")]))
	if not enabled: m._text("OFF",bubble.get_center()+Vector2(0,3),8,Color("68533d"),true)
	elif fish.size()>=CAPS[capacity]: m._text("가득",bubble.get_center()+Vector2(0,3),8,Color("68533d"),true)
	elif flash>0: m._ui_texture_rect(m.fish_tex[int(fish[-1].sp)],Rect2(bubble.position+Vector2(7,6),Vector2(24,12)),false)
	elif job.is_empty(): m._text("%d초"%ceili((1-escrow)*3600/m.pond_recovery()),bubble.get_center()+Vector2(0,3),8,Color("68533d"),true)
	else:
		m._ui_texture_rect(m.V.rods[0],Rect2(bubble.position+Vector2(6,3),Vector2(20,18)),false)
		if 3600.0/RATES[speed]-progress<3: m._ui_texture_rect(m.fish_tex[int(job.sp)],Rect2(bubble.position+Vector2(21,10),Vector2(13,8)),false)
func draw_panel(m,h: float) -> void:
	if not opened: return
	rects={};var r:=Rect2(16,maxf(80,(h-250)/2),238,250)
	m._ui_rect(Rect2(0,0,270,h),Color(0,0,0,.65));m._ui_style_box(m.sb_panel,r)
	m._text("포획 로봇",r.position+Vector2(119,26),14,Color("493421"),true)
	m._ui_texture_rect(ART,Rect2(r.position+Vector2(79,37),Vector2(80,54)),false)
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
