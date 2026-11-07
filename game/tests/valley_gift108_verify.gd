extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String):
	if not ok: failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
	var Gift=load("res://addons/reservoir/valley_gift108.gd")
	m.testing_grants=["testing-20261026-078","reservoir-legendary-20261029-093"];m.gold=123;m.souls=7;m.pearl=11
	m.bag=[{"sp":0,"star":0,"grade":2,"len":12.0,"w":0.08,"price":99,"shoulder":false}]
	var bag: Array=m.bag.duplicate(true);var ids: Array=m.testing_grants.duplicate()
	var dex: Dictionary=m.personal_dex.serialize().duplicate(true);var counts: Dictionary=m.catch_counts.duplicate(true)
	var grades: Dictionary=m.DEX.duplicate(true);var records: Dictionary=m.REC.duplicate(true)
	var progress: Dictionary=m.progression.serialize().duplicate(true);var region: Dictionary=m.region_shop.serialize().duplicate(true)
	check(m._save_game(),"save synthetic original")
	m.development_preview=true;check(not Gift.claim(m),"preview cannot claim");m.development_preview=false
	m.resetting=true;check(not Gift.claim(m),"reset cannot claim");m.resetting=false
	var disk: String=FileAccess.get_file_as_string("user://save.json")
	check(DirAccess.make_dir_absolute("user://save.json.tmp")==OK,"create actual write blocker")
	check(not Gift.claim(m),"real save failure rejected")
	check(m.gold==123 and m.bag==bag and m.testing_grants==ids,"real failure rolls entire gift back")
	check(FileAccess.get_file_as_string("user://save.json")==disk,"real failure preserves primary bytes")
	check(DirAccess.remove_absolute("user://save.json.tmp")==OK,"remove blocker")
	m.mailbox.detail="1.08";m.mailbox.draw(m,540)
	check(m.mailbox.rects.has("gift"),"new mail exposes gift")
	m.mailbox.press(m,m.mailbox.rects.gift.get_center())
	check(m.gold==1000123 and m.souls==7 and m.pearl==11,"mail button gives exact additive currency")
	check(m.bag.size()==21 and m.bag[0]==bag[0],"existing specimen preserved plus20")
	for i in 20:
		var f: Dictionary=m.bag[i+1];var sp: int=i+20
		check(f.sp==sp and f.grade==0 and f.len==float(m.FISH_LEN[sp]),"one normal average specimen per valley species")
		check(sp in m.CATALOG.by_star(1,int(f.star)) and f.price==m.fish_price(sp,int(f.star),0,1.0),"correct valley star and value")
	check(m.personal_dex.serialize()==dex and m.catch_counts==counts and m.DEX==grades and m.REC==records,"gift does not forge catches or records")
	check(m.progression.serialize()==progress and m.region_shop.serialize()==region,"gift does not auto donate or unlock")
	check(ids.all(func(id):return id in m.testing_grants) and Gift.ID in m.testing_grants,"old and new grant markers coexist")
	check(not Gift.claim(m) and m.gold==1000123 and m.bag.size()==21,"repeat blocked")
	m._load_game()
	check(not Gift.claim(m) and m.gold==1000123 and m.bag.size()==21,"reload preserves gift and blocks repeat")
	check(m._save_game(),"persist claimed fixture")
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("VALLEY_GIFT108_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
