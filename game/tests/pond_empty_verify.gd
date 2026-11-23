extends SceneTree
var failures: Array = []
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m = load("res://main.gd").new()
	root.add_child(m)
	await process_frame
	m.set_process(false);m.SET.sfx=0;m.SET.music=0;m.TUT.done=true
	m.equipment.rod_equipped=true;m.bait=10000
	for area in 4:
		m.active_region=area
		for stock in [0.0,0.01,0.5,0.999]:
			m.pond_stock=stock;m.S={"phase":"idle"};m.holding=true
			var bait_before=m.bait
			var gauge_before=m.progression.owner_gauge.duplicate()
			m.start_cast()
			check(m.S.phase=="idle" and not m.holding,"empty blocks cast %d/%s"%[area,stock])
			check(m.pond_stock==stock and m.bait==bait_before and m.progression.owner_gauge==gauge_before,"blocked cast preserves resources")
		m.pond_stock=1.0;m.start_cast()
		check(m.S.phase=="cast" and m.pond_stock==0 and not m.S.insufficient,"last unit starts valid cast")
		m.start_wait()
		check(m.S.phase=="wait","last unit continues fishing")
	# Sample valid last-unit waits with region 2 parts; zero after cast must not force star 1.
	m.active_region=2;m.equipment.active_parts=["r2_float","r2_hook","r2_line","r2_reel"]
	m.region_shop.unlocked=[0,1,2];m.region_shop.selected_bait=0
	var higher=0
	seed(18012026)
	for i in 4000:
		m.pond_stock=1.0;m.start_cast();m.start_wait()
		if m.S.star>0: higher+=1
	check(higher>0,"last unit has nonzero higher-star chance")
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("POND_EMPTY_VERIFY failures=",failures)
	call_deferred("finish")

func finish() -> void:
	# Let run() release its local RefCounted resources before engine shutdown.
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures.is_empty() else 1)
