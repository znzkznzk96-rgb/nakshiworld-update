extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var m=load("res://main.gd").new();m.SET.music=0;m.SET.sfx=0;m.title_open=false;root.add_child(m);await process_frame;m.set_process(false)
	for i in 6:
		check(m.region_shop.bait_icon(i)!=null,"bait asset %d"%i)
		check(load("res://art/rewards67/license_%d.png"%i)!=null,"license asset %d"%i)
		if i>0:check(m.V.ROD_COST[i]<m.spots.PRICES[i] and m.V.ROD_COST[i]>m.V.ROD_COST[i-1],"rod progression price")
	m.V.open_shop(m,"forge");m.V.draw_shop(m,540)
	check(not m.V.rects.has("rod_page"),"no rod pagination")
	m.gold=1999;m.equipment.rods=[0];m.rod_owned=0;m.rod_lv=0
	check(m.V.commerce.request(m.V,m,"rod:1"),"carbon quote")
	check(not m.V.commerce.confirm(m.V,m) and m.gold==1999,"insufficient funds preserved")
	m.gold=2000;check(m.V.commerce.confirm(m.V,m) and m.gold==0 and 1 in m.equipment.rods,"carbon costs exactly 2000")
	check(m.V.bundle_preview._amount(1340000)=="1,340,000","currency grouping")
	m.audio_feedback.dispose();await create_timer(0.1).timeout;m.queue_free();await process_frame
	print("REWARDS_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
