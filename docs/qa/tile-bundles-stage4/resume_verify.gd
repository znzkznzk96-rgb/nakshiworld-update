extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String):
	if not ok:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
	check(m.gold==2247 and m.souls==30 and m.pearl==2,"fresh process restores exact wallet")
	check(m.active_region==2 and m.region_shop.is_unlocked(2),"fresh process restores paid tile entry")
	for kind in 3:check(m.progression.bundle_done(2,kind) and m.progression.claimed(2,kind),"fresh process restores all bundle receipts")
	var gold: int=m.gold;var souls: int=m.souls;var pearl: int=m.pearl
	for kind in 3:check(not m.progression.claim_reward(m,2,kind),"fresh process rejects duplicate receipt")
	check(m.gold==gold and m.souls==souls and m.pearl==pearl,"duplicate requests never change wallet after restart")
	check(m.progression.licensed(3) and not m.region_shop.unlock(m,3),"rift remains preparing after restart")
	check(m.bag.size()==2 and m.bag[0].price==999 and m.bag[1].sp==0,"unsubmitted specimens survive restart")
	check(not m.personal_dex.best(m,5,"weight").is_empty(),"legacy specimen remains alongside new bundle progress")
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("BUNDLE_STAGE4_RESUME_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
