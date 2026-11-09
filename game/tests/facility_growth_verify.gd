extends SceneTree
const FG=preload("res://addons/reservoir/facility_growth.gd")
const Store=preload("res://addons/reservoir/save_store.gd")
var failures:Array=[]
func check(ok:bool,label:String)->void:
	if not ok: failures.append(label);push_error(label)
func fish(i:int)->Dictionary:
	return {"sp":i%19,"star":0,"grade":0,"len":12.0,"w":0.1,"price":100+i,"stamp":"keep-%d"%i}
func snap(m)->Dictionary:
	return {"gold":m.gold,"aqua_lv":m.aqua_lv,"boat_lv":m.boat_lv,"pond_cap_lv":m.pond_cap_lv,"pond_regen_lv":m.pond_regen_lv,"stock":m.pond_stock,"reserve":m.pond_overflow,"aqua":m.aqua.duplicate(true),"bag":m.bag.duplicate(true)}
func _initialize()->void:call_deferred("run")
func run()->void:
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
	m.development_preview=false;m.TUT.done=true;m.title_open=false;m.lesson_open=false;m.scene="village";m.S={"phase":"idle"}
	if "resume" in OS.get_cmdline_user_args():
		check(m.gold==123456 and m.aqua_lv==6 and m.boat_lv==6 and m.pond_cap_lv==6 and m.pond_regen_lv==6,"independent restart keeps regional levels and cash")
		check(m.pond_overflow==17 and m.pond_stock==130 and m.testing_grants==["0.78","1.08","unrelated"],"independent restart keeps reserve and gift IDs")
		check(m.aqua[0].stamp=="keep-7" and m.bag[0].stamp=="keep-9","independent restart keeps exact specimens")
		print("FACILITY_GROWTH_RESUME_VERIFY failures=",failures)
		m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1);return
	check(m.pond_max()==30 and m.pond_stock==30 and m.pond_recovery()==30,"new game starts with30 and baseline recovery")
	var template:Dictionary={"gold":123456,"pearl":7,"souls":8,"testing_grants":["0.78","1.08","unrelated"],"mail_read":["1.12"],"mail_deleted":["0.91"],"bag":[fish(31)],"time":Time.get_unix_time_from_system(),"pond_stock":0,"aqua":[]}
	for base in [40,80]:
		for lv in 6:
			var d:Dictionary=template.duplicate(true);d.pond_base=base;d.pond_cap_lv=lv;d.pond_regen_lv=lv;d.boat_lv=lv;d.aqua_lv=mini(lv,4)
			for i in [3,6,10,15,20][mini(lv,4)]:d.aqua.append(fish(i))
			d.pond_stock=base+20*lv
			var before:Dictionary=d.duplicate(true);var n:Dictionary=FG.migrate(d)
			check(d==before,"migration leaves source intact")
			check(FG.migrate(n)==n,"migration idempotent")
			check(n.aqua==d.aqua and n.bag==d.bag and n.testing_grants==d.testing_grants and n.mail_read==d.mail_read and n.mail_deleted==d.mail_deleted,"migration keeps fish and gift/mail IDs")
			check(n.gold==123456 and n.pearl==7 and n.souls==8,"migration keeps currencies")
			check(n.pond_stock+n.pond_overflow==d.pond_stock,"migration preserves every unit of stock")
			check(FG.STOCK_ADD[n.pond_cap_lv]==20*lv and FG.RECOVERY[n.pond_regen_lv]==30+10*lv,"paid capacity and recovery effects preserved")
			check(FG.AQUA_CAP[n.aqua_lv]==[3,6,10,15,20][mini(lv,4)],"paid tank size preserved")
			m.boat_lv=n.boat_lv
			check(is_equal_approx(m.V.multiplier(m),(4.0+2*lv)/4*60/(60-4*lv)),"paid visitor multiplier preserved")
			check(Store.write("user://save.json",d),"write old fixture");m._load_game()
			check(m.aqua==JSON.parse_string(JSON.stringify(d.aqua)) and m.bag==JSON.parse_string(JSON.stringify(d.bag)) and m.gold==123456,"actual load preserves specimens and money")
			check(m.pond_stock+m.pond_overflow>=float(d.pond_stock)-0.01,"actual load retains legacy stock")
			var kept:Dictionary=snap(m);m._load_game();check(snap(m)==kept,"second load does not repeat migration or multiply stock")
	var oldest:Dictionary=FG.migrate({"pond_stock":80});check(oldest.pond_stock+oldest.pond_overflow==80,"pre pond_base legacy save keeps80")
	m.pond_stock=20;m.pond_cap_lv=0;m.pond_overflow=50;FG.refill_reserve(m)
	check(m.pond_stock==30 and m.pond_overflow==40,"reserve fills only available room once")
	FG.refill_reserve(m);check(m.pond_overflow==40,"full pond cannot consume reserve")
	m.pond_stock-=1;FG.refill_reserve(m);check(m.pond_stock==30 and m.pond_overflow==39,"consumed stock replaced without reserve duplication")
	m.pond_overflow=0;m.gold=99999999;m.region_shop.unlocked=[0];m.progression.available_regions=[0,1,2]
	for area in 3:
		m.region_shop.unlocked=range(area+1)
		for action in FG.FIELDS:
			m.set(FG.FIELDS[action],area*2);m.aqua.resize(m.aqua_capacity());m.pond_stock=m.pond_max()*0.4
			for step in 2:
				check(FG.unlocked(m,action),"regional two-step gate opens")
				var quote:Dictionary=m.V.commerce.quote(m.V,m,action);var gold:int=m.gold;var ratio:float=m.pond_stock/m.pond_max()
				check(not quote.is_empty() and quote.price==FG.cost(m,action),"quote uses actual regional price")
				check(m._save_game(),"save before one-write assertion")
				m.V._act(m,action)
				check(m.gold==gold-int(quote.price) and FG.level(m,action)==area*2+step+1,"one purchase charges once and advances once")
				check(is_equal_approx(m.pond_stock/m.pond_max(),ratio),"expansion preserves remaining stock ratio")
				check(int(Store.read("user://save.json").gold)==m.gold,"successful purchase persists")
				check(int(Store.read("user://save.json.bak").gold)==gold,"purchase saves exactly once")
			var before:Dictionary=snap(m);m.V._act(m,action)
			check(snap(m)==before and m.V.commerce.quote(m.V,m,action).is_empty(),"region lock rejects direct and quoted purchases")
	# Stale confirm cannot bypass a revoked region, even with enough money.
	m.region_shop.unlocked=[0,1];m.aqua_lv=2;m.aqua.resize(6);m.V.commerce.request(m.V,m,"aexpand");var before:Dictionary=snap(m);m.region_shop.unlocked=[0]
	check(not m.V.commerce.confirm(m.V,m) and snap(m)==before,"confirmation rechecks regional access")
	# All four purchase paths exercise real failed file creation and memory/disk rollback.
	m.region_shop.unlocked=[0,1,2]
	for action in FG.FIELDS:
		m.set(FG.FIELDS[action],0);m.aqua.resize(m.aqua_capacity());m.pond_stock=m.pond_max()*0.5;m.pond_overflow=7;m.gold=10000000
		check(m._save_game(),"persist transaction fixture");var disk:PackedByteArray=FileAccess.get_file_as_bytes("user://save.json");before=snap(m)
		check(DirAccess.make_dir_absolute("user://save.json.tmp")==OK,"block real write")
		m.V._act(m,action)
		check(snap(m)==before and FileAccess.get_file_as_bytes("user://save.json")==disk,"real IO failure rolls back "+action)
		check(DirAccess.remove_absolute("user://save.json.tmp")==OK,"unblock real write")
		m.gold=0;before=snap(m);check(not FG.purchase(m,action) and snap(m)==before,"insufficient funds has no side effects")
	m.progression.available_regions=[0,1,2,3,4,5];m.region_shop.unlocked=[0,1,2,3,4,5]
	for action in FG.FIELDS:
		for lv in range(6,13):
			m.set(FG.FIELDS[action],lv);check(not FG.unlocked(m,action) and not FG.purchase(m,action),"prepared future levels never free-buy")
	# Independent process resume checks migrated revision, IDs and reserve on disk.
	m.boat_lv=6;m.aqua_lv=6;m.aqua=[];m.aqua.resize(20);m.aqua[0]=fish(7);m.bag=[fish(9)];m.gold=123456;m.pond_cap_lv=6;m.pond_regen_lv=6;m.pond_stock=130;m.pond_overflow=17;m.testing_grants=["0.78","1.08","unrelated"]
	check(m._save_game(),"persist final migration specimen")
	print("FACILITY_GROWTH_VERIFY failures=",failures)
	m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
