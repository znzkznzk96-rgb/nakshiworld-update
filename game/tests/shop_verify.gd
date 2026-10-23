extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;m.title_open=false;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false;m.scene="village";m.S={"phase":"idle"}
	m.SET.sfx=0.0
	m.gold=100000;m.bait=0;m.parts_owned=[];m.equipment.active_parts=[];m.equipment.unlocked_parts=[];m.region_shop.restore({})
	var c=m.V.commerce
	check(c.quote(m.V,m,"rpart:1:0").is_empty(),"locked region purchase rejected")
	check(c.quote(m.V,m,"bait:3:1").is_empty(),"future bait purchase rejected")
	check(c.quote(m.V,m,"bait:0:0").is_empty() and c.quote(m.V,m,"bait:0:-1").is_empty(),"invalid quantities rejected")
	c.request(m.V,m,"bait:0:100");check(c.confirm(m.V,m),"100 worms purchase")
	check(m.bait==100 and m.gold==99500,"quantity and currency exact")
	check(not c.confirm(m.V,m) and m.bait==100,"double confirm cannot charge twice")
	m.gold=0;c.request(m.V,m,"bait:0:5");check(not c.confirm(m.V,m) and m.bait==100,"insufficient funds preserved");c.pending={};m.gold=100000
	check(not m.region_shop.unlock(m,2),"region sequence enforced")
	check(not m.region_shop.unlock(m,1),"unfinished region cannot charge")
	m.progression.available_regions=[0,1]
	check(not m.region_shop.unlock(m,1),"certificate needed before currency unlock")
	m.progression.main_completed[0]=true;m.progression.certificates[0]=true
	var original_prices: Array=[0,3300,52000,1030000,6700000,28300000]
	for area in range(1,6):
		for slot in 4:
			check(m.region_shop.price(m,area,slot)==maxi(10,roundi(original_prices[area]*[.05,.10,.18,.30][slot]/10.0)*10),"part prices unaffected by unlock fee")
	m.gold=6599
	check(not m.region_shop.unlock(m,1) and m.gold==6599,"new fee enforced without partial charge")
	m.gold=100000
	var unlock_gold: int=m.gold
	check(m.region_shop.unlock(m,1) and m.gold==unlock_gold-6600,"licensed region charges once")
	check(m.region_shop.unlock(m,1) and m.gold==unlock_gold-6600,"repeat unlock never charges twice")
	check(not c.quote(m.V,m,"bait:1:5").is_empty(),"region unlock opens bait")
	check(c.quote(m.V,m,"rpart:1:1").is_empty(),"part sequence enforced")
	for slot in 4:
		c.request(m.V,m,"rpart:1:%d" % slot);check(c.confirm(m.V,m),"regional part purchase %d" % slot)
	check(m.region_shop.has_active(m,"hook",1) and not m.region_shop.has_active(m,"hook",0),"regional hook only affects its own ground")
	check(m.equipment.equip(m,"part:r1_hook",false),"regional detach")
	check(m.equipment.sell(m,"part:r1_hook"),"regional sale")
	check(not m.equipment.sell(m,"part:r1_hook"),"regional duplicate sale rejected")
	c.request(m.V,m,"rpart:1:1");check(c.confirm(m.V,m),"regional repurchase")
	c.request(m.V,m,"bait:1:5");check(c.confirm(m.V,m),"better bait purchase")
	check(is_equal_approx(m.region_shop.take_bait(m),1.0) and m.region_shop.stocks[1]==4,"large bait consumed with base grade multiplier")
	m._save_game();m.region_shop.restore({});m._load_game()
	check(m.region_shop.is_unlocked(1) and m.region_shop.stocks[1]==4,"region and bait save round trip")
	check("r1_hook" in m.equipment.active_parts,"regional equipment persists")
	m.region_shop.stocks[1]=0;m.bait=1
	check(m.region_shop.take_bait(m)==1.0 and m.bait==0,"empty selected bait falls back to worm")
	check(m.region_shop.take_bait(m)==0.85,"empty inventory uses bare hook")
	m.V.open_shop(m,"work");m.text_items=[];m.V.draw_shop(m,660)
	check(m.text_items.any(func(it):return "보유 비늘" in str(it[2])),"sell tab displays scales")
	m.V.tab="clean";m.text_items=[];m.V.draw_shop(m,660)
	check(m.text_items.any(func(it):return "물고기의 혼" in str(it[2])),"clean tab displays souls")
	print("SHOP_VERIFY failures=",failures)
	c.pending={};c.notice_icon=null;c=null;m.region_shop.icons.clear()
	m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
