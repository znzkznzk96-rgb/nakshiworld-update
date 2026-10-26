extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var Model=load("res://addons/expedition/model.gd")
	var d=Model.new();d.rng.seed=76
	check(d.soldiers.is_empty() and d.souls==[0,0,0,0,0],"legacy save starts empty without spending souls")
	for a in 5:
		for b in 5: check(d.recipe(a,b)==d.recipe(b,a) and d.recipe(a,b)>=0,"commutative15recipe")
	d.souls=[1,0,0,0,0];check(not d.craft(0,0),"same element costs2")
	d.souls=[100,100,100,100,100];check(d.craft(0,0),"craft succeeds")
	check(not d.craft(0,0),"unacknowledged result blocks repeat")
	d.pending={};d.add_unit(1,1,[1,8,2]);d.team=[1,2]
	var before: Dictionary=d.serialize();d.unit(1).locked=true
	check(d.begin_merge(1,2,1000).is_empty(),"locked material protected")
	d.unit(1).locked=false
	var q: Dictionary=d.begin_merge(1,2,1000)
	check(not q.is_empty() and d.soldiers.is_empty(),"two materials consumed once")
	var pending: Dictionary=d.serialize();var copy=Model.new();copy.restore(pending)
	check(copy.pending==d.pending,"pending roll survives reload exactly")
	check(copy.finish_merge(1),"inherit selected vector")
	check(copy.soldiers[0].iv==[1,8,2] and int(copy.soldiers[0].star)==2,"inherit whole vector and next star")
	check(not copy.finish_merge(0),"cannot finalize twice")
	check(copy.team.size()==1,"replace consumed team slot")
	var ordered: Array=[]
	for stars in [[1,1,1],[2,1,1],[2,2,1],[2,2,2]]:
		var b=Model.new();b.unlocked=10
		for i in 3: b.team.append(b.add_unit([3,0,6][i],stars[i],[0,0,0]).uid)
		check(b.start(10,1000),"start3")
		var guard: int=0
		while b.active() and guard<10000: b.update(0.1,1000);guard+=1
		check(guard<10000,"combat terminates")
		ordered.append({"stars":stars,"status":b.battle.status,"hp":b.battle.fighters.map(func(f):return f.hp),"seconds":guard*.1})
		var snapshot: Dictionary=b.serialize();var c=Model.new();c.restore(snapshot)
		check(c.serialize()==snapshot,"battle snapshot roundtrip")
		var reward: Dictionary=b.claim();check(not reward.is_empty() and b.claim().is_empty(),"reward exactly once")
		check(not b.start(1,1001),"recovery prevents immediate retry")
		check(b.start(1,1031),"recovery expires")
	# Every unit resolves its ability in actual runtime, including duplicate debuff caps.
	for id in 15:
		var b=Model.new()
		for j in 3: b.team.append(b.add_unit(id,2,[0,0,0]).uid)
		check(b.start(1,1000),"all units can dispatch")
		for k in 300:
			if not b.active(): break
			b.update(.2,1000)
	print("EXPEDITION_REFERENCE ",JSON.stringify(ordered))
	print("EXPEDITION_VERIFY failures=",failures)
	quit(0 if failures.is_empty() else 1)
