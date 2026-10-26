extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var failures: Array=[]
	var Model=load("res://addons/expedition/model.gd");var ref=Model.new();var roles={"attack":[],"defense":[],"support":[]}
	for i in 15: roles[ref.catalog.soldiers[i].role].append(i)
	var report=[]
	for stars in [[1,1,1],[2,1,1],[1,2,1],[1,1,2],[2,2,1],[2,2,2]]:
		var wins=0;var total=0;var losses=[]
		for tank in roles.defense:
			for attack in roles.attack:
				for support in roles.support:
					var d=Model.new();d.unlocked=10
					for i in 3: d.team.append(d.add_unit([tank,attack,support][i],stars[i],[0,0,0]).uid)
					for u in d.soldiers: u.level=3
					d.start(10,1000)
					for t in 8000:
						if not d.active(): break
						d.update(.1,1000)
					total+=1
					if d.battle.status=="win": wins+=1
					else: losses.append([tank,attack,support])
		report.append({"stars":stars,"wins":wins,"total":total,"losing_compositions":losses})
	for result in report:
		if result.stars==[1,1,1] and result.wins!=0: failures.append("one-star gate")
		if result.stars in [[2,1,1],[1,2,1],[1,1,2]] and result.wins>50: failures.append("one two-star majority still cannot clear")
		if result.stars==[2,2,1] and (result.wins<94 or result.wins>=125): failures.append("two two-star composition matters")
		if result.stars==[2,2,2] and result.wins!=125: failures.append("three two-star growth payoff")
	print("BALANCE_RUNTIME ",JSON.stringify(report))
	print("EXPEDITION_BALANCE_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
