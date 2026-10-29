extends SceneTree
var failures: Array = []
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m = load("res://main.gd").new()
	m.SET.sfx=0;m.SET.music=0;m.title_open=false;root.add_child(m);await process_frame;m.set_process(false)
	check(m.FISH_NAME.size()==40 and m.fish_tex.size()==40,"40 species textures load")
	check(m.FISH_NAME[5]==m.FISH_NAME[20] and m.fish_key(5)!=m.fish_key(20),"same-name regional species have separate stable keys")
	m.DEX={"버들치":[0,2]};m.REC={"버들치":17.2};m.catch_counts={"버들치":[4,0,2,0,0]};m.catch_legacy={"버들치":[2]}
	m._migrate_fish_records()
	check(m.fish_grades(5)==[0,2] and m.fish_grades(20).is_empty(),"legacy dex stays in reservoir")
	check(is_equal_approx(m.fish_record_cm(5),17.2) and m.fish_record_cm(20)==0,"legacy maximum not copied to valley")
	m._migrate_fish_records();check(m.fish_counts(5)==[4,0,2,0,0],"migration is idempotent")
	m.S={"phase":"fight","sp":20,"star":0,"grade":1,"len":11.5,"lf":1.15}
	m.start_catch()
	check(m.fish_counts(20)==[0,1,0,0,0] and m.fish_counts(5)==[4,0,2,0,0],"new catch does not merge same-name counts")
	check(m.fish_grades(20)==[1] and is_equal_approx(m.fish_record_cm(20),11.5),"valley catch updates its own dex and record")
	m.bag=[{"sp":20,"star":0,"grade":1,"len":11.5,"w":0.08,"price":13}];m.aqua=[null,m.bag[0].duplicate(),null]
	m._save_game();m.DEX={};m.REC={};m.catch_counts={};m.bag=[];m.aqua=[null,null,null]
	m._load_rec();m._load_game()
	check(m.bag[0].sp==20 and m.aqua[1].sp==20 and m.fish_counts(20)[1]==1,"bag aquarium and regional history survive reload")
	check(m.fish_record_cm(5)>17 and m.fish_record_cm(20)==11.5,"both maximum records survive reload")
	check(m._fish_display_length(1,2.0,false,32)<m._fish_display_length(1,2.0,false,29),"small cloud minnow remains smaller than trout at same star")
	var valley_prices := [25,35,45,50,30,30,50,55,130,145,175,225,150,195,480,560,610,2240,2760,16000]
	for sp in range(20,40):
		var star := 0
		for s in range(5):
			if sp in m.CATALOG.by_star(1,s): star=s
		check(m.fish_price(sp,star,0,1.0)==valley_prices[sp-20],"conservative nominal price %d"%sp)
		for grade in range(5):
			for lf in [0.5,1.0,2.0]:
				check(m.fish_price(sp,star,grade,lf)==int(round(valley_prices[sp-20]*m.PRICE_GRADE[grade]*minf(lf*lf,2.5))),"valley grade and length scaling %d"%sp)
	check(m.fish_price(19,4,0,1.0)==8000 and m.fish_price(0,0,0,1.0)==10,"reservoir prices unchanged")
	m.forge_lv=2
	check(m.fish_price(39,4,0,1.0)==17600,"valley enhancement bonus preserved")
	m.forge_lv=0
	check(m.measurement_max_cm(25)==10 and m.measurement_max_cm(28)==60 and m.measurement_max_cm(39)==300,"species-fixed valley ruler ranges")
	seed(92469)
	for sp in range(20,40):
		var total := 0.0
		for i in 1000:
			var cm: float=m.sample_length_cm(sp);total+=cm
			check(cm>=m.FISH_LEN[sp]*0.5 and cm<m.species_max_cm(sp),"length respects species range %d"%sp)
		check(absf(total/1000.0-m.FISH_LEN[sp])<m.FISH_LEN[sp]*0.03,"length centered near planned mean %d"%sp)
	m.TUT.done=true;m.active_region=0;m.region_shop.unlocked=[0,1];m.pond_stock=80;m.bait=100
	m.equipment.active_parts=["float","hook","line","reel"];m.progression.owner_gauge=[100.0,33.0,0,0,0,0]
	m.start_wait();check(not m.S.owner and m.S.star<4,"full gauge waits for successful hook before owner")
	m.start_hook();m.S.pos=m.S.zc;m.hook_tap();check(m.S.owner and m.S.sp==19,"successful hook confirms reservoir owner")
	m.fail("test miss");check(m.progression.owner_gauge[0]==70 and m.progression.owner_gauge[1]==33,"owner miss sets only its region to 70")
	m.progression.owner_gauge[0]=100;m.start_wait();m.start_hook();m.S.pos=m.S.zc;m.hook_tap();m.start_catch()
	check(m.progression.owner_gauge[0]==0,"owner catch resets to zero")
	m.active_region=1;m.equipment.active_parts=["float","hook","line","reel"];m.progression.owner_gauge[1]=100
	m.start_wait();m.start_hook();m.S.pos=m.S.zc;m.hook_tap()
	check(not m.S.owner and m.S.star==0 and m.S.sp>=20,"other ground parts do not unlock valley owner or stars")
	m.equipment.active_parts=["r1_float","r1_hook","r1_line","r1_reel"];m.start_wait();m.start_hook();m.S.pos=m.S.zc;m.hook_tap()
	check(m.S.owner and m.S.sp==39,"correct regional parts enable valley owner")
	m.fail("test miss");check(m.progression.owner_gauge[1]==70 and m.progression.owner_gauge[0]==0,"valley miss independent from reservoir")
	m.progression.owner_gauge[1]=0;m.progression.fishing_event(m,1,"catch",3)
	check(m.progression.owner_gauge[1]==3,"legendary gain is three percentage points")
	m.progression.owner_gauge[1]=99;m.start_cast();m.start_wait()
	check(m.progression.owner_gauge[1]==99 and not m.S.owner,"casts do not fill owner gauge")
	m.progression.fishing_event(m,1,"catch",0)
	m.start_cast();m.start_wait();m.start_hook();m.S.pos=m.S.zc;m.hook_tap()
	check(m.S.owner and m.S.sp==39,"next successful hook after gauge fills is owner")
	m.progression.restore({});m.region_shop.unlocked=[0];m.gold=10000
	var before: int=m.gold
	check(not m.region_shop.unlock(m,1) and m.gold==before,"unfinished unlicensed region cannot charge")
	m.bag=[{"sp":5,"grade":1,"w":0.08},{"sp":20,"grade":1,"w":0.08},{"sp":5,"grade":0,"w":0.08},{"sp":5,"grade":1,"w":0.08}]
	check(not m.progression.donate(m,0,0,0) and m.bag.size()==4,"undefined bundle cannot consume fish")
	m.progression.main_targets={"0":[{"species":m.fish_key(5),"grade":1,"count":2}]}
	check(not m.progression.donate(m,0,1,0) and not m.progression.donate(m,0,2,0),"wrong regional species or grade rejected")
	check(m.progression.donate(m,0,0,0) and not m.progression.licensed(1),"partial donation grants no certificate")
	check(m.progression.donate(m,0,2,0) and not m.progression.licensed(1),"completed main waits for receipt")
	check(m.progression.claim_reward(m,0,0) and m.progression.licensed(1),"receive grants certificate and eligibility")
	check(m.gold==before,"bundle completion does not pay region cost")
	check(m.progression.available_regions==[0,1],"valley available without test override");m.gold=19799
	check(not m.region_shop.unlock(m,1) and m.gold==19799,"insufficient currency cannot unlock")
	m.gold=20500;check(m.region_shop.unlock(m,1) and m.gold==700,"certificate then separate currency purchase")
	check(m.region_shop.unlock(m,1) and m.gold==700,"repeat unlock does not charge twice")
	m.active_region=1;m._layout();m.environment.show_scene(true)
	check(m.environment.valley.root.visible and not m.bg_node.visible and not m.environment.layer.visible,"valley replaces reservoir layers")
	check(m.SURF<m.WATER and m.PY+57==m.SURF,"character foot platform and water anchors agree")
	var v=m.environment.valley
	check(v.waterfall_y(2.1,0)<v.waterfall_y(2.0,0),"waterfall streak travels upward")
	check(v.layers.size()==6,"separate plate cloud waterfall light reflection and wildlife layers")
	m.active_region=0;m._layout();m.environment.show_scene(true)
	check(not v.root.visible and m.bg_node.visible and m.WATER==roundi(m.environment.point(Vector2(0,m.environment.WATER_Y)).y),"return to reservoir restores reservoir plate anchors and scene")
	m.V.museum_region=1
	for sp in range(20,40): m.DEX[m.fish_key(sp)]=[0,1,2,3,4]
	m.text_items=[];m.ui_commands=[];m.V.rects={"rows":[]}
	m.V._draw_museum(m,Rect2(8,112,254,420),190)
	var names_checked := 0
	for item in m.text_items:
		var normalized: String=str(item[2]).replace("\n","").replace(" ","")
		for sp in range(20,40):
			if normalized==str(m.FISH_NAME[sp]).replace(" ",""):
				var rows: int=str(item[2]).split("\n").size()
				check(item[1].y+float(rows-1)*item[0].get_height(item[5])+item[0].get_descent(item[5]) < 190+23+27+(sp-20)/4*57+50,"long museum name above medals")
				names_checked+=1
	check(names_checked==20,"all valley names visible without truncation")
	m.S={"phase":"idle"};m.scene="village";print("REGIONAL_VERIFY failures=",failures)
	m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
