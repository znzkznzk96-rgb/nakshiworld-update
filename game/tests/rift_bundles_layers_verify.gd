extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String)->void:
	if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
	var m=load("res://main.gd").new();m.SET.music=0;m.SET.sfx=0;m.development_preview=true;root.add_child(m);await process_frame;m.set_process(false);m.development_preview=true
	if "--reload" in OS.get_cmdline_user_args():
		var gold:int=m.gold
		check(m.progression.claimed(3,2) and gold==9045100,"independent reload persisted exact owner payout")
		check(not m.progression.claim_reward(m,3,2) and m.gold==gold,"independent restart duplicate blocked")
		m.audio_feedback.dispose();m.queue_free();await process_frame
		print("RIFT_BUNDLE_RELOAD_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1);return
	var p=m.progression;var ui=m.V.bundle_preview
	check(m.spots.PRICES[3]==4635000 and m.spots.PRICES[4]==30150000,"existing entry fees")
	check(p.bundle_targets(3,0).size()==6 and p.bundle_targets(3,1).size()==6 and p.bundle_targets(3,2).size()==1,"6/6/1 structure")
	for kind in 3:
		for target in p.bundle_targets(3,kind):check(int(target.grade)==0 and int(target.count)==1,"normal minimum one specimen")
	check(p.bundle_targets(3,2)[0].species=="r3:s19","approved storm tuna owner")
	for kind in [1,2]:
		p.restore({});m.gold=100;m.souls=0;m.pearl=0
		p.extra_completed[p.bundle_key(3,kind)]=true
		var expected:int=3015000 if kind==1 else 9045000
		check(ui.reward_amount(m,3,kind)==expected and ui.reward_preview_amount(m,3,kind)==expected,"next-fee reward display")
		check(not p.claim_reward(m,3,kind) and m.gold==100 and not p.claimed(3,kind),"actual failed save rolls back")
		m.development_preview=false
		check(p.claim_reward(m,3,kind) and m.gold==100+expected,"payout exact")
		check(m.souls==(50 if kind==1 else 0) and m.pearl==(6 if kind==2 else 0),"previous extras preserved")
		var saved:Dictionary=p.serialize().duplicate(true);p.restore(saved)
		check(not p.claim_reward(m,3,kind) and m.gold==100+expected,"restored claim no duplicate")
		m.development_preview=true
	p.restore({});m.bag=[]
	for target in p.bundle_targets(3,0):m.bag.append({"sp":ui.species_id(target),"grade":0,"price":123})
	var old_bag:Array=m.bag.duplicate(true)
	check(not p.donate_bundle(m,3,0,0,0) and m.bag==old_bag and p.bundle_counts(3,0)==[0,0,0,0,0,0],"donation failed save rollback")
	for kind in 3:
		ui.region=3;ui.tab=kind;m.text_items=[];m.ui_commands=[];ui.draw(m,540)
		check(not m.text_items.is_empty(),"bundle renderer and approved names")
	check(p.available_regions==[0,1,2] and m.FISH_NAME.size()==60,"no speculative gameplay/catalog change")
	var e=m.environment.rift;var state:Dictionary=p.serialize().duplicate(true)
	seed(451);var expected_rng:=randf();seed(451)
	for i in 101:
		m.clock=i*.1;e.update(.1)
		check(absf(e.bob_offset())<=1.5001 and e.boat.rotation==0,"small vertical motion no rotation")
	check(randf()==expected_rng and p.serialize()==state,"layers preserve gameplay RNG and saves")
	check(e.layers.size()==13 and e.boat.texture.get_size()==Vector2(360,450),"separate boat and procedural layers")
	check(load("res://art/rift/cloud_bank.png").get_size()==Vector2(1080,440),"half-grid cloud exported at nearest2x")
	for kind in ["sky","clouds","reflection","cliffs"]:check(e.layers.has("scenery_"+kind),"independent concept scenery layer "+kind)
	var tears=e.layers["open_tears"]
	check(tears.opening_areas.size()==2 and tears.opening_areas[0]>5000 and tears.opening_areas[1]>5000,"sky tears have visible interior area, not a polyline")
	var bubbles=e.layers["underwater_bubbles"]
	for i in 28:
		for seconds in [0.0,12.0,45.0,95.0]:
			var pos:Vector2=bubbles.bubble_position(i,seconds)
			check(pos.y>657 and not bubbles.CLEAR_CENTER.has_point(pos),"bubbles stay underwater and outside fight center")
	for kind in ["fish","kelp","jellies","motes","bubbles"]:check(e.layers.has("underwater_"+kind),"underwater decorative layer "+kind)
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("RIFT_BUNDLES_LAYERS_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
