extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;m.title_open=false;root.add_child(m);await process_frame;m.set_process(false)
	m.development_preview=true;m.TUT.done=true;m.region_shop.selected_bait=0;m.bait=50000;m.active_region=0;m.equipment.active_parts=["float","hook","line","reel"];m.pond_stock=m.pond_max()
	var stars=[0,0,0,0,0];var grades=[0,0,0,0,0];seed(7022)
	for i in 20000:
		m.start_wait();stars[m.S.star]+=1;grades[m.S.grade]+=1
	for i in 5:
		check(absf(stars[i]/20000.0-m.STAR_P[i])<0.012,"reservoir star draw distribution %d"%i)
		check(absf(grades[i]/20000.0-m.GRADE_P[i])<0.012,"reservoir grade draw distribution %d"%i)
	check(stars[4]==0,"owner remains outside ordinary draw")
	check(m.OTHER_REGION_STAR_P==[0.62,0.27,0.09,0.018,0.0] and m.OTHER_REGION_GRADE_P==[0.8653,0.0661,0.0628,0.0042,0.0016],"other region odds unchanged")
	m.equipment.active_parts=[];m.start_wait();check(m.S.star==0,"no parts only star1")
	m.equipment.active_parts=["float","hook","line","reel"];m.pond_stock=0
	var depleted_rare:=0
	for i in 500:
		m.start_wait()
		if m.S.star>0: depleted_rare+=1
	check(depleted_rare>100,"depleted early pond preserves higher-star access")
	var p=m.progression;var ui=m.V.bundle_preview;p.restore({});m.forge_lv=0
	var saved: Dictionary=p.serialize().duplicate(true);var gold: int=m.gold
	for area in 2:
		for kind in [1,2]:
			check(ui.reward_preview_amount(m,area,kind)>0,"empty donation shows completion estimate %d/%d"%[area,kind])
			ui.region=area;ui.tab=kind;ui.draw(m,540)
			check(m.text_items.any(func(it):return "완료 예상" in str(it[2])),"estimate explicitly labeled")
	check(p.serialize()==saved and m.gold==gold,"view never changes progress or money")
	p.bundle_values={"0:1":750};p.extra_donations={"0:1":[1,1,1,0,0,0]}
	var expected:=750
	for i in range(3,6):
		var sp: int=p.SUB_SPECIES[0][i];expected+=m.fish_price(sp,ui.star(sp),0,1.0)
	check(ui.reward_preview_amount(m,0,1)==roundi(expected*1.2),"partial estimate retains actual value plus only missing fish")
	p.extra_completed={"0:1":true};check(ui.reward_preview_amount(m,0,1)==900,"completed display uses actual paid amount")
	check(ui.reward_preview_amount(m,0,0)==0 and ui.reward_preview_amount(m,2,1)==0,"main and future conditions untouched")
	print("ODDS_REWARDS_VERIFY failures=",failures," stars=",stars," grades=",grades)
	m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
