extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.development_preview=true;m.TUT.done=true
	var shop=m.region_shop;var commerce=m.V.commerce
	shop.restore({"stocks":[0,7,9,11,13,15],"selected_bait":1});m.bait=4
	check(shop.stocks==[0,7,9,11,13,15] and m.bait==4,"existing stock preserved")
	for b in 3:
		var expected: int=[5,15,20][b]
		check(shop.bait_description(m,b).begins_with(str(expected)+"비늘"),"visible price matches purchase %d"%b)
		for count in [1,5,10,50,100]:
			var q: Dictionary=commerce.quote(m.V,m,"bait:%d:%d"%[b,count])
			check(q.price==expected*count,"bulk quote %d/%d"%[b,count])
		m.gold=expected-1;var before: int=shop.stock(m,b)
		commerce.pending=commerce.quote(m.V,m,"bait:%d:1"%b)
		check(not commerce.confirm(m.V,m) and shop.stock(m,b)==before and m.gold==expected-1,"insufficient balance atomic %d"%b)
		m.gold=expected;commerce.pending=commerce.quote(m.V,m,"bait:%d:1"%b)
		check(commerce.confirm(m.V,m) and m.gold==0 and shop.stock(m,b)==before+1,"exact balance purchase %d"%b)
	check(commerce.quote(m.V,m,"worm:10").price==50,"legacy worm quote aligned")
	check(preload("res://addons/reservoir/spot_selection.gd").PRICES==[0,6600,104000,1545000,10050000,42450000],"approved tiered unlock fees")
	check(m.progression.available_regions==[0,1],"only approved reservoir and valley are available")
	check(shop.BAIT_MULT==[1.0,1.0,1.5,1.8,2.1,2.5] and shop.BAIT_PRICES.slice(3)==[1200,3000,6000],"effects and future bait prices preserved")
	var summary: Array=[]
	shop.unlocked=[0,1];shop.selected_bait=0;m.bait=100000
	for area in 2:
		m.active_region=area
		m.equipment.active_parts=["float","hook","line","reel"] if area==0 else ["r1_float","r1_hook","r1_line","r1_reel"]
		var expected_floor: Array=[0.567259,0.314135,0.095856,0.022750,0.0] if area==0 else [0.717292,0.222407,0.052785,0.007517,0.0]
		for ratio in [0.0,0.3,0.7,1.0]:
			m.pond_stock=m.pond_max()*ratio;seed(76100+area)
			var stars=[0,0,0,0,0]
			for i in 5000:
				m.start_wait();stars[m.S.star]+=1
			check(stars[3]>15 and stars[4]==0,"star4 remains possible, owner excluded %d/%s"%[area,ratio])
			check(is_equal_approx(m.pond_stock,m.pond_max()*ratio),"probability floor never refills stock")
			if ratio<=0.7:
				for st in 5: check(absf(stars[st]/5000.0-expected_floor[st])<0.025,"observed floor probability %d/%s/%d"%[area,ratio,st])
			summary.append({"region":area,"stock":ratio,"counts":stars})
		m.equipment.active_parts=[];m.pond_stock=0
		for i in 100:
			m.start_wait();check(m.S.star==0,"depleted relief cannot bypass parts")
	# Snapshot/save fields and legacy fish values are not migrated or repriced.
	m.bag=[{"sp":1,"star":0,"grade":0,"len":25.0,"w":0.08,"price":12345}]
	m.development_preview=false;m._save_game();m.bag=[];m._load_game()
	check(m.bag.size()==1 and m.bag[0].price==12345,"stored fish value survives reload")
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("ECONOMY_BALANCE_VERIFY failures=",failures," draws=",summary);quit(0 if failures.is_empty() else 1)
