extends SceneTree
var failures:Array=[]
const Store=preload("res://addons/reservoir/save_store.gd")
const Progress=preload("res://addons/reservoir/regional_progress.gd")
func check(ok:bool,label:String)->void:
 if not ok:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 m.TUT.done=true;m.title_open=false;m.lesson_open=false;m.trans={};m.scene="spots"
 if "--reload" in OS.get_cmdline_user_args():
  check(m.active_region==3 and m.region_shop.is_unlocked(3),"independent process rift saved entry")
  check(m.progression.bundle_done(2,0) and m.progression.claimed(2,0),"independent process tile license preserved")
  print("RIFT_UNLOCK_RELOAD_VERIFY failures=",JSON.stringify(failures));m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1);return
 var p=m.progression;p.restore({});m.region_shop.unlocked=[0,1,2];m.gold=4635000
 check(not m.region_shop.unlock(m,3) and m.gold==4635000,"tile main license required")
 p.main_completed[2]=true;check(not m.region_shop.unlock(m,3),"receive certificate first")
 check(p.claim_reward(m,2,0),"tile certificate claimed")
 var path_unlock="user://unlock-fixture.json"
 check(Store.write(path_unlock,{"region_shop":{"unlocked":[0,1,2]},"gold":100}),"write paid locations")
 var damaged={"region_shop":{"unlocked":[0],"stocks":[7]},"gold":3}
 DirAccess.copy_absolute(path_unlock,path_unlock+".bak")
 var file=FileAccess.open(path_unlock,FileAccess.WRITE);file.store_string(JSON.stringify(damaged));file.close()
 var restored=Store.read(path_unlock)
 check(restored.region_shop.unlocked==[0,1,2] and restored.gold==3 and int(restored.region_shop.stocks[0])==7,"recover paid locations only from backup")
 check(Store.write(path_unlock,damaged) and Store.read(path_unlock).region_shop.unlocked==[0,1,2],"preserve evidence through backup rotation")
 var visit={"region_shop":{},"active_region":2};Store.recover_unlocks(visit,{})
 check(visit.region_shop.unlocked==[0,1,2],"saved visit proves route")
 m.region_shop.unlocked=[0];check(not m.region_shop.unlock(m,3) and m.region_shop.unlock_error.contains("해금 기록"),"previous location reason with exact fee")
 m.region_shop.unlocked=[0,1,2]
 m.development_preview=true
 check(not m.region_shop.unlock(m,3) and m.gold==4635000 and not m.region_shop.is_unlocked(3),"failed write rolls purchase back")
 m.development_preview=false;m.gold=4634999
 check(not m.region_shop.unlock(m,3),"exact fee shortage blocked");check(m.region_shop.unlock_error=="1비늘이 부족해요","exact shortage shown")
 m.gold=4635000;m.spots.index=3;m.spots.rects.enter=Rect2(20,200,200,30);m.spots.press(m,Vector2(100,215));m.trans={}
 check(m.spots.unlock_fx.active() and m.scene=="spots","saved purchase presents unlock before entry")
 m.spots.process(m.spots.unlock_fx.DURATION,m);m.spots.press(m,Vector2(100,215))
 check(m.active_region==3 and m.region_shop.is_unlocked(3) and m.gold==0,"actual spot button unlocks rift exact fee")
 m._switch_scene("fish");m.trans={};m._save_game();m.active_region=0;m._load_game()
 check(m.active_region==3 and m.region_shop.is_unlocked(3),"rift entry reload preserved")
 check(m.region_shop.unlock(m,3) and m.gold==0,"repeat entry free")
 check(m.FISH_NAME.size()==80 and m.fish_tex.size()==80,"all eighty loaded")
 var ids:Array=[]
 for star in 5:ids.append_array(m.CATALOG.by_star(3,star))
 check(ids==range(60,80),"rift has 8/6/3/2/1 species")
 m.equipment.active_parts=["r3_float","r3_hook","r3_line","r3_reel"];m.region_shop.selected_bait=-1;m.pond_stock=m.pond_max()
 for sp in range(60,80):
  check(m.fish_tex[sp]!=null and m.fish_used[sp].size.x>0,"new static loaded %d"%sp)
  check(m.species_max_cm(sp)>m.FISH_LEN[sp] and m.fish_price(sp,0,0,1.0)>0,"positive size/price %d"%sp)
  m.S={"sp":sp,"star":0,"grade":0,"lf":1.0};m.start_fight()
  check(is_finite(m.S.reelMul) and m.S.reelMul>0 and m.S.tensionMul>0,"real fight factors %d"%sp)
 for sp in range(60,80):
  m.S={"sp":sp,"star":0,"grade":0,"lf":1.0,"len":float(m.FISH_LEN[sp]),"owner":false};m.start_fight();m.start_catch();m.keep_fish()
  check(m.fish_grades(sp).has(0) and m.fish_counts(sp)[0]>0,"real catch records %d"%sp)
 for i in 80:
  m.start_wait();check(m.S.sp>=60 and m.S.sp<79,"live wait regional species only")
 m.progression.owner_gauge[3]=100;m.start_wait();m.start_hook();m.S.pos=m.S.zc;m.hook_tap()
 check(m.S.owner and m.S.sp==79,"rift owner uses approved storm tuna")
 m.progression.owner_gauge[3]=0
 var Capture=load("res://addons/reservoir/capture_robot.gd");var cr=Capture.new();var f=cr.make_fish(m)
 check(cr.valid_fish(f) and f.sp>=60 and f.sp<80,"robot makes/restores rift specimen")
 var receipts=Progress.new();receipts.restore({"reward_claimed":{"2:0":true,"2:1":true,"2:2":true}})
 check(receipts.bundle_done(2,0) and receipts.bundle_done(2,1) and receipts.bundle_done(2,2) and receipts.certificates[2],"receipt-only legacy data restores completion, never repays")
 var old=Progress.new();old.restore({"main_completed":[false,false,true],"certificates":[false,false,true],"extra_completed":{"2:1":true,"2:2":true},"reward_claimed":{"2:0":true,"2:1":true,"2:2":true},"bundle_values":{"2:1":2000}})
 check(old.bundle_counts(2,0)==[1,1,1,1,1,1] and old.bundle_counts(2,1)==[1,1,1,1,1,1],"completed legacy flags display fulfilled slots")
 var fresh=Progress.new();var recovered=Store.recover_bundles(fresh.serialize(),old.serialize());fresh.restore(recovered)
 check(fresh.bundle_done(2,0) and fresh.bundle_done(2,1) and fresh.bundle_done(2,2),"backup recovers all evidenced tile bundles")
 var before:int=m.gold;m.progression=fresh
 check(not fresh.claim_reward(m,2,1) and not fresh.claim_reward(m,2,2) and m.gold==before,"paid backup receipts cannot repay")
 fresh.restore({});fresh.recover_unlock_evidence([0,1,2])
 check(fresh.bundle_done(1,0) and fresh.claimed(1,0) and not fresh.bundle_done(2,0) and not fresh.bundle_done(2,1),"tile unlock proves valley license, never fabricates tile completion")
 var a=Progress.new();a.donations={"2":[1,0,0,0,0,0]};var b=Progress.new();b.donations={"2":[0,1,0,0,0,0]}
 var merged=Store.recover_bundles(a.serialize(),b.serialize());a.restore(merged)
 check(a.bundle_counts(2,0)==[1,1,0,0,0,0] and not a.bundle_done(2,0),"partial maximum not sum or whole-complete")
 check(Store.recover_bundles(recovered,recovered)==recovered,"recovery is idempotent")
 var sample={"gold":777,"bag":[{"sp":42}],"testing_grants":["tile-once-20261112-126"],"regional_progress":old.serialize()}
 var path="user://recovery-fixture.json";check(Store.write(path,sample),"fixture first write")
 var current=sample.duplicate(true);current.gold=888;current.bag=[];current.regional_progress=Progress.new().serialize();check(Store.write(path,current),"fixture second write")
 var loaded=Store.read(path)
 check(loaded.gold==888 and loaded.bag==[] and loaded.testing_grants==current.testing_grants,"backup cannot roll back money/bag/gifts")
 var pp=Progress.new();pp.restore(loaded.regional_progress);check(pp.bundle_done(2,1) and pp.claimed(2,1),"real disk backup recovery")
 var empty=Progress.new();var unchanged=Store.recover_bundles(empty.serialize(),empty.serialize());check(unchanged==empty.serialize(),"fresh saves stay fresh")
 print("RIFT_UNLOCK_RECOVERY_VERIFY failures=",JSON.stringify(failures));m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
