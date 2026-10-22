extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func hook(m,success: bool) -> void:
	m.start_wait();m.S.grade=0;m.start_hook();m.S.pos=m.S.zc+(0.1 if success else 0.4);m.hook_tap()
func run() -> void:
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;m.title_open=false;root.add_child(m);await process_frame;m.set_process(false)
	m.development_preview=true;m.title_open=false;m.TUT.done=true;m.lesson_open=false;m.guide.opened=false;m.mailbox.opened=false;m.settings_open=false;m.market_open=false;m.trans={};m.scene="fish"
	m.bait=100;m.pond_stock=80;m.active_region=0;m.region_shop.unlocked=[0,1];m.equipment.active_parts=["float","hook","line","reel"]
	var p=m.progression;p.restore({})
	for grade in 5:
		p.owner_gauge[0]=0;p.fishing_event(m,0,"catch",grade)
		check(p.owner_gauge[0]==([1,1,1,2,3][grade]),"gain uses final specimen grade %d"%grade)
	p.owner_gauge[0]=20
	for event in ["cast","miss","sell","buyback","donate"]:p.fishing_event(m,0,event,4)
	check(p.owner_gauge[0]==20,"non-catch events never advance gauge")
	for missing in ["float","hook","line","reel"]:
		m.equipment.active_parts=["float","hook","line","reel"];m.equipment.active_parts.erase(missing)
		p.fishing_event(m,0,"catch",4)
		check(p.owner_gauge[0]==20 and not m.owner_ui.visible(m),"each required equipped part gates gain and display: "+missing)
	m.equipment.active_parts=["float","hook","line","reel"]
	p.owner_gauge[0]=99;p.fishing_event(m,0,"catch",4);check(p.owner_gauge[0]==100,"gain clamps at exactly 100")
	m.start_cast();check(p.owner_gauge[0]==100,"casting does not consume readiness")
	m.start_wait();check(not m.S.owner and m.S.star<4,"owner is not selected during bite")
	m.fail("missed bite");check(p.owner_gauge[0]==100,"missed bite preserves 100")
	hook(m,false);check(not m.S.owner and p.owner_gauge[0]==100,"hook MISS preserves readiness and regular fish")
	m.fail("regular fight loss");check(p.owner_gauge[0]==100,"regular loss after hook MISS preserves readiness")
	hook(m,true);check(m.S.owner and m.S.star==4 and m.S.sp==19 and m.S.phase=="pre","next GREAT confirms reservoir owner")
	m.text_items=[];m.ui_commands=[];m.owner_ui.draw(m)
	check(not m.owner_ui.warning_bounds.size.is_zero_approx(),"warning appears only for confirmed owner")
	check(m.text_items.any(func(it):return str(it[2])=="경고 · 주인 등장") and m.text_items.any(func(it):return str(it[2])=="청룡잉어"),"warning names regional owner")
	for i in 40:m._process(0.05)
	check(m.S.phase=="pre" and p.owner_gauge[0]==100,"owner fight waits through readable warning")
	for i in 25:m._process(0.05)
	check(m.S.phase=="fight","warning automatically ends and fight starts after three seconds")
	m.owner_ui.draw(m);check(m.owner_ui.warning_bounds.size.is_zero_approx(),"warning disappears during fight")
	m.fail("owner lost");m._settle_owner(false);check(p.owner_gauge[0]==70,"confirmed owner loss settles once to 70")
	p.owner_gauge[0]=100;hook(m,true);m.start_catch();m._settle_owner(true)
	check(p.owner_gauge[0]==0,"owner caught resets to zero without adding normal catch gain")
	p.owner_gauge[0]=10;m.S={"phase":"fight","owner_region":0,"grade":3,"owner":false};m._settle_owner(true);m._settle_owner(true)
	check(p.owner_gauge[0]==12,"normal catch grade gain is not duplicated")
	p.owner_gauge[0]=31;m.active_region=1;m.equipment.active_parts=["r1_float","r1_hook","r1_line","r1_reel"];p.owner_gauge[1]=100
	hook(m,true);check(m.S.owner and m.S.sp==39,"valley uses its own owner")
	m.fail("valley loss");check(p.owner_gauge[1]==70 and p.owner_gauge[0]==31,"regional gauges settle independently")
	m.equipment.active_parts=["float","hook","line","reel"];p.fishing_event(m,1,"catch",4)
	check(p.owner_gauge[1]==70 and not m.owner_ui.visible(m),"other region parts do not count as equipped valley parts")
	var saved: Dictionary=p.serialize();p.restore(saved);check(p.owner_gauge[0]==31 and p.owner_gauge[1]==70,"regional progress survives serialization")
	m.development_preview=false;m._save_game();p.owner_gauge[0]=0;p.owner_gauge[1]=0;m._load_game();m.development_preview=true
	check(p.owner_gauge[0]==31 and p.owner_gauge[1]==70,"regional progress survives actual save and reload")
	p.restore({"owner_gauge":[-10,145,12]});check(p.owner_gauge[0]==0 and p.owner_gauge[1]==100 and p.owner_gauge[2]==12,"old saves clamp invalid progress and preserve valid progress")
	p.restore({});check(p.owner_gauge==[0.0,0.0,0.0,0.0,0.0,0.0],"old save missing progress defaults to zero")
	m.active_region=0;m.scene="village";check(not m.owner_ui.visible(m),"gauge hidden away from fishing")
	m.scene="fish";m.TUT.done=false;check(not m.owner_ui.visible(m),"tutorial remains free of owner gauge")
	var ui=m.owner_ui
	ui.load_frames();check(ui.frames.size()==6,"all six region frames load")
	for area in 6:
		check(ui.frames[area].get_size()==Vector2(256,48),"native pixel frame size %d"%area)
		for value in [0,73,100]:
			m.text_items=[];m.ui_commands=[];ui.draw_frame(m,area,value,Vector2(7,75))
			check(ui.bounds.encloses(ui.label_bounds) and ui.bounds.encloses(ui.track_bounds),"label and trough stay inside frame %d"%area)
			check(ui.fill_bounds.size.x==floorf((ui.track_bounds.size.x-2)*value/100.0),"dynamic fill reflects exact percentage %d/%d"%[area,value])
			check(ui.fill_bounds.end.x<=ui.track_bounds.end.x-1,"fill never crosses reviewed trough %d"%area)
			if area<2:check(ui.bounds.encloses(ui.image_bounds),"approved owner sprite stays inside frame %d"%area)
			check(m.text_items.any(func(it):return str(it[2])=="%d%%"%value),"percentage text rendered independently %d/%d"%[area,value])
			var owners: Array=m.CATALOG.by_star(area,4)
			var label: String=m.FISH_NAME[int(owners[0])] if not owners.is_empty() else "주인의 기척"
			check(m._text_w(label,9)+m._text_w("100%",9)+10<=ui.label_bounds.size.x,"full owner name and maximum percent fit without overlap %d"%area)
	check(p.available_regions==[0],"art does not enable unfinished fishing grounds")
	print("OWNER_GAUGE_VERIFY failures=",failures)
	m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
