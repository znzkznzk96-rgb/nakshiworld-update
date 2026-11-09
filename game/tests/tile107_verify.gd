extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String):
	if not ok: failures.append(label);push_error(label)
func _initialize(): call_deferred("run")
func fish(sp: int,value: int=100,grade: int=0) -> Dictionary:
	return {"sp":sp,"star":0,"grade":grade,"len":20.0,"w":0.1,"price":value}
func run():
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
	m.title_open=false;m.trans={};m.TUT.done=true;m.lesson_open=false
	var p=m.progression;p.restore({});m.region_shop.restore({});m.region_shop.unlocked=[0,1];m.gold=500000
	check(not m.region_shop.unlock(m,2) and m.gold==500000,"tile certificate required")
	p.main_completed[1]=true
	check(not m.region_shop.unlock(m,2),"completion without reward receipt stays locked")
	check(p.claim_reward(m,1,0),"valley reward grants eligibility")
	m.development_preview=true
	check(not m.region_shop.unlock(m,2) and m.gold==500000,"failed save rolls purchase back")
	m.development_preview=false;m.gold=311999
	check(not m.region_shop.unlock(m,2) and m.gold==311999,"short payment cannot unlock")
	m.gold=312000;m.scene="spots";m.spots.index=2;m.spots.rects.enter=Rect2(20,200,200,30)
	m.spots.press(m,Vector2(100,215))
	check(m.active_region==2 and m.region_shop.is_unlocked(2) and m.gold==0,"real entry pays exact existing price")
	m._switch_scene("fish");m.trans={};m._save_game();m.active_region=0;m._load_game()
	check(m.active_region==2 and m.region_shop.is_unlocked(2),"tile entry survives restart")
	check(m.region_shop.unlock(m,2) and m.gold==0,"repeat entry free")
	check(m.environment.tile.root.visible and not m.environment.valley.root.visible and not m.bg_node.visible,"tile scene only")
	check(m.environment.tile.plate.texture.get_size()==Vector2(801,1962),"native source unchanged")
	check(m.fish_tex.size()==60 and m.CATALOG.by_star(2,4)==[59],"tile full catalog and owner")
	for sp in range(40,60):
		check(m.fish_tex[sp]!=null and m.fish_used[sp].size.x>0,"approved fish texture loaded")
		check(m.species_max_cm(sp)==m.CATALOG.VALLEY_MAX[sp%20],"approved provisional length")
	m.equipment.active_parts=[];m.bait=100;m.pond_stock=80;m.S={"phase":"idle"}
	for i in 50:
		m.start_wait();check(m.S.sp>=40 and m.S.sp<48,"tile starter catches remain local and star1")
	m.equipment.active_parts=["r2_float","r2_hook","r2_line","r2_reel"];p.owner_gauge[2]=100
	m.start_wait();m.start_hook();m.S.pos=m.S.zc;m.hook_tap()
	check(m.S.owner and m.S.sp==59,"tile owner from local gear and gauge")
	m.start_catch();check(p.owner_gauge[2]==0 and m.fish_counts(59)[m.S.grade]>0,"owner catch recorded")
	m.S={"phase":"idle"};m.gold=0;m.souls=0;m.pearl=0
	for kind in 3:
		var targets=p.bundle_targets(2,kind)
		check(targets.size()==(1 if kind==2 else 6),"bundle dimensions")
		for i in targets.size():
			var sp: int=59 if kind==2 else p.MAIN_SPECIES[2][i] if kind==0 else p.SUB_SPECIES[2][i]
			m.bag=[fish(sp,101,i%5)]
			if i==0:
				m.development_preview=true
				check(not p.donate_bundle(m,2,kind,0,i) and m.bag.size()==1 and p.bundle_counts(2,kind)[i]==0,"failed donation save rolls back")
				m.development_preview=false
			check(p.donate_bundle(m,2,kind,0,i),"mixed grade donations accepted")
			m._save_game();m._load_game()
		check(p.bundle_done(2,kind) and not p.claimed(2,kind),"completion persists without auto payout")
		m.development_preview=true
		check(not p.claim_reward(m,2,kind) and not p.claimed(2,kind),"failed claim rolls back")
		m.development_preview=false
		check(p.claim_reward(m,2,kind) and not p.claim_reward(m,2,kind),"claim exactly once")
	check(m.gold==1854000 and m.souls==50 and m.pearl==6,"tile next unlock cost4635000 times10% plus30%")
	check(p.licensed(3),"tile main grants rift eligibility")
	m.gold=99999999
	check(not m.region_shop.unlock(m,3) and m.gold==99999999,"unfinished rift cannot charge")
	m._save_game();p.restore({});m._load_game()
	check(p.claimed(2,0) and p.claimed(2,1) and p.claimed(2,2),"reward receipt persists")
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("TILE107_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
