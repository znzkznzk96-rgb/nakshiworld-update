extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String):
	if not ok:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
	var Gift=load("res://addons/reservoir/valley_gift108.gd")
	check(m.gold==1000123 and m.bag.size()==21 and Gift.ID in m.testing_grants,"independent process restores exact gift")
	check(not Gift.claim(m) and m.gold==1000123 and m.bag.size()==21,"independent process blocks repeat")
	for i in 20:check(m.bag[i+1].sp==i+20,"all20 survive restart")
	m.progression.restore({"certificates":[true,false,false],"main_completed":[true,false,false],"reward_claimed":{"0:0":true}})
	var plan: Array=m.progression.donation_plan(m,1,0)
	check(plan.size()==6 and m.progression.donate_all(m,1,0,plan)==6,"gift provides every valley main bundle specimen")
	check(m.progression.claim_reward(m,1,0) and m.progression.licensed(2),"normal gift can earn tile certificate")
	check(m.region_shop.unlock(m,2) and m.gold==688123,"gift currency supports exact tile unlock cost")
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("VALLEY_GIFT108_RESUME_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
