extends SceneTree
const Gifts=preload("res://addons/reservoir/mail_gifts.gd")
var failures: Array=[]
func check(ok: bool,label: String):
	if not ok: failures.append(label);push_error(label)
func _initialize(): call_deferred("run")
func run():
	check(Gifts.info("1.26").gold==preload("res://addons/reservoir/spot_selection.gd").PRICES[3],"tile gift equals approved rift entry fee")
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
	if "resume" in OS.get_cmdline_user_args():
		check(m.gold==7735123 and m.souls==1007 and m.expedition.data.souls==[51,52,53,54,55],"independent restart currencies")
		check(m.bag.size()==93 and m.testing_grants.size()==6,"independent restart contents and IDs")
		for version in Gifts.DATA: check(not Gifts.claim(m,version),"restart blocks "+version)
	else:
		for version in Gifts.DATA:
			m.testing_grants=["unrelated-existing-id"];m.gold=123;m.souls=7;m.expedition.data.souls=[1,2,3,4,5]
			m.bag=[{"sp":0,"star":0,"grade":2,"len":12.0,"w":0.08,"price":99,"shoulder":false}]
			var bag: Array=m.bag.duplicate(true)
			m.development_preview=true;check(not Gifts.claim(m,version),"preview "+version);m.development_preview=false
			m.resetting=true;check(not Gifts.claim(m,version),"reset "+version);m.resetting=false
			check(m._save_game(),"persist fixture "+version)
			var disk: PackedByteArray=FileAccess.get_file_as_bytes("user://save.json")
			check(DirAccess.make_dir_absolute("user://save.json.tmp")==OK,"block real write "+version)
			check(not Gifts.claim(m,version),"reject real write failure "+version)
			check(m.gold==123 and m.souls==7 and m.expedition.data.souls==[1,2,3,4,5] and m.bag==bag and m.testing_grants==["unrelated-existing-id"],"rollback every field "+version)
			check(FileAccess.get_file_as_bytes("user://save.json")==disk,"preserve save bytes "+version)
			check(DirAccess.remove_absolute("user://save.json.tmp")==OK,"unblock "+version)
		# Claim all five in a single save to detect cross-gift marker/rollback interference.
		check(not Gifts.claim(m,"unknown") and m.bag.size()==1,"unknown letter is inert")
		for version in Gifts.DATA:
			m.mailbox.detail=version;m.mailbox.draw(m,540)
			check(m.mailbox.rects.has("gift"),"button "+version)
			m.mailbox.press(m,m.mailbox.rects.gift.get_center())
			check(Gifts.info(version).id in m.testing_grants,"mail dispatch "+version)
			check(not Gifts.claim(m,version),"duplicate "+version)
		check(m.gold==7735123 and m.souls==1007 and m.expedition.data.souls==[51,52,53,54,55],"combined exact currencies")
		check(m.bag.size()==93 and m.testing_grants.size()==6,"combined contents and existing marker")
		for area in 2:
			var targets: Array=m.progression.bundle_targets(area,0)
			for slot in targets.size():
				var specimen: Dictionary=m.bag[81+area*6+slot]
				check(m.CATALOG.key(specimen.sp)==targets[slot].species and specimen.grade==targets[slot].grade,"required donation specimen")
		for i in 80:
			var f: Dictionary=m.bag[i+1]
			check(f.sp==(i%20 if i<40 else i-20) and f.grade==(3 if i<40 else 0),"combined species and grade")
			check(is_equal_approx(f.w,float(m.W_BASE[f.star])*float(m.W_GRADE[f.grade])),"average weight")
			if i>=60:check(f.sp in m.CATALOG.by_star(2,f.star) and f.price==m.fish_price(f.sp,f.star,0,1.0),"tile specimen star/price preserved")
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("MAIL_GIFTS_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
