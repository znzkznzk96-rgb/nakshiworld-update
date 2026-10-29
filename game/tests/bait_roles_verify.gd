extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.development_preview=true;m.TUT.done=true;m.active_region=0
	var shop=m.region_shop;shop.restore({"stocks":[0,7,9,11,13,15],"selected_bait":1})
	check(shop.stocks==[0,7,9,11,13,15],"old six bait stocks preserved")
	check(shop.bait_unlocked(0) and shop.bait_unlocked(1) and shop.bait_unlocked(2) and not shop.bait_unlocked(3),"three roles available from reservoir; future baits remain gated")
	m.equipment.active_parts=["float","hook","line","reel"];m.pond_stock=m.pond_max()
	var results: Array=[]
	for bait in 3:
		seed(7500+bait);shop.selected_bait=bait;m.bait=12000;shop.stocks[bait]=12000
		var rare:=0;var large:=0;var mean:=0.0
		for i in 10000:
			m.start_wait();check(m.S.bait_id==bait,"consumed bait identity")
			if m.S.grade>0: rare+=1
			if m.S.lf>1.15: large+=1
			mean+=m.S.lf
			check(m.S.lf<=m.species_max_cm(m.S.sp)/m.FISH_LEN[m.S.sp],"species size ceiling")
		results.append({"rare":rare/10000.0,"large":large/10000.0,"mean":mean/10000.0})
	check(results[1].large>results[0].large+0.09,"large bait improves record-sized specimen odds")
	check(absf(results[1].rare-results[0].rare)<0.025,"large bait does not change grade axis")
	check(results[2].rare>results[0].rare+0.12,"rare bait improves grade odds")
	check(absf(results[2].mean-results[0].mean)<0.01,"rare bait does not change size distribution")
	shop.selected_bait=1;shop.stocks[1]=0;m.bait=1;m.start_wait()
	check(m.S.bait_id==-1 and m.bait==1,"empty selected bait uses bare hook without consuming unselected worm")
	m.start_wait();check(m.S.bait_id==-1 and m.S.bare,"empty all uses original bare hook")
	check(shop.BAIT_PRICES[0]==5 and shop.BAIT_PRICES[1]==15 and shop.BAIT_PRICES[2]==20,"reviewed early costs")
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("BAIT_ROLES_VERIFY failures=",failures," results=",results);quit(0 if failures.is_empty() else 1)
