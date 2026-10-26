extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var M=load("res://addons/expedition/model.gd")
	var d=M.new();d.souls=[100,100,100,100,100]
	var a=d.add_unit(0,1,[4,5,6]);var b=d.add_unit(1,1,[7,2,3])
	check(d.merge_cost(a.uid,b.uid).is_empty(),"untrained merge blocked")
	var gold: int=10000
	for level in 3:
		var prev=d.stats(a);var q=d.train(a.uid,gold);gold-=int(q.gold)
		check(int(a.level)==level+1 and d.stats(a).hp>prev.hp,"upgrade improves and persists")
	check(d.train(a.uid,gold).is_empty(),"max3 enforced")
	check(d.merge_cost(a.uid,b.uid).is_empty(),"both materials must be max")
	for i in 3: d.train(b.uid,10000)
	check(not d.merge_cost(a.uid,b.uid).is_empty(),"full+3 merge unlocked")
	var old=d.serialize();var restored=M.new();restored.restore(JSON.parse_string(JSON.stringify(old)))
	check(restored.unit(a.uid).level==3 and restored.unit(a.uid).iv==a.iv,"upgrade reload")
	var base=d.catalog.soldiers[0].stars['1'];check(d.stats(a).hp==roundi(float(base.hp)*1.04),"old stat equals+3")
	d.begin_merge(a.uid,b.uid,10000);d.finish_merge(0);check(d.soldiers[0].level==0,"new star restarts+0")
	var timings: Array=[]
	for r in range(1,11):
		var x=M.new();x.unlocked=10
		for id in [3,0,6]:
			var u=x.add_unit(id,3,[0,0,0]);u.level=3;x.team.append(u.uid)
		x.start(r,1000)
		var seen: Array=[];var seconds: float=0;var last: int=0
		while x.active() and seconds<1800:
			var enemy=str(x.battle.enemy.id)
			if not enemy in seen: seen.append(enemy)
			x.update(.05,1000);seconds+=.05
			var progress: int=int(x.battle.progress)
			check(progress>=last and progress-last<=1,"continuous integer progress");last=progress
		check(not x.active(),"round terminates")
		check(seconds>20,"readable expedition duration")
		for expected in x.catalog.rounds[r-1]: check(str(expected) in seen,"configured enemy appears")
		timings.append({"round":r,"seconds":snapped(seconds,.1),"status":x.battle.status})
	print("EXPEDITION079_TIMING ",JSON.stringify(timings))
	print("EXPEDITION079_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
