extends SceneTree
var failures: Array=[]
class Probe:
	extends RefCounted
	var bars: int=0
	var labels: Array=[]
	var colors: Array=[]
	var strokes: int=0
	func _ui_texture_rect_region(_a,_b,_c,_d=Color.WHITE): pass
	func _ui_texture_rect(_a,_b,_c=false,_d=Color.WHITE): pass
	func _ui_line(_a,_b,_c,_d): strokes+=1
	func _ui_arc(_a,_b,_c,_d,_e,_f,_g): pass
	func _ui_rect(r,c):
		if c==Color("33251e") and r.size==Vector2(31,4): bars+=1
	func _text(s,_b,_c,_d,_e,_f): labels.append(s);colors.append(_d)
func check(ok,label):
	if not ok: failures.append(label)
func _initialize(): call_deferred("run")
func run():
	var Model=load("res://addons/expedition/model.gd")
	var Old=load("res://tests/combat_feedback_baseline.gd")
	for id in 15:
		var fresh=Model.new();var old=Old.new()
		for model in [fresh,old]:
			model.rng.seed=1234;model.unlocked=10
			for j in [id,(id+1)%15,(id+2)%15]: model.team.append(model.add_unit(j,2,[4,4,4]).uid)
			model.start(10,1000);model.battle.utility_revision=0;model.battle.fighters.map(func(f): f.erase("support_budget"));model.battle.enemy.hp=100000;model.battle.enemy.max_hp=100000
		for step in 12:
			if fresh.battle.fighters.all(func(f): return f.hp<=0): break
			fresh.tick();old.tick()
			check(fresh.battle.fighters==old.battle.fighters,"fighters unchanged %d/%d"%[id,step])
			check(fresh.battle.enemy==old.battle.enemy,"enemy unchanged %d/%d"%[id,step])
			var total: int=int(fresh.battle.fx.poison_damage)
			for event in fresh.battle.fx.attacks: total+=int(event.amount)
			check(mini(int(fresh.battle.fx.enemy_hp_before),total)==int(fresh.battle.fx.outgoing),"damage accounting")
			var restored=Model.new();restored.restore(fresh.serialize())
			check(restored.serialize()==fresh.serialize(),"event save roundtrip")
	var v=load("res://addons/expedition/view.gd").new();v.setup()
	for id in [3,0,7]: v.data.team.append(v.data.add_unit(id,2,[0,0,0]).uid)
	v.data.start(1,1000);v.data.battle.utility_revision=0;v.data.battle.phase="fight";v.data.tick();v.data.battle.fx.age=.25
	for height in [48,78]:
		var probe=Probe.new();v.battle_art(probe,Rect2(0,0,246,height))
		check(probe.bars==3,"all three HP bars")
		for event in v.data.battle.fx.attacks:
			check(str(event.amount) in probe.labels,"separate numeric damage")
		check(not probe.labels.any(func(s): return "공격" in s or "지원" in s or "방어" in s),"no role-position labels")
	for role in ["attack","defense","support"]:
		var probe=Probe.new();v.damage_value(probe,Vector2.ZERO,20,role,.1)
		check(probe.strokes==0,"no decorative slash strokes")
		check(probe.colors.back()==Color("ff706b"),"all role damage red")
	v.data.battle.ticks=2;v.data.battle.fighters[0].hp=10;v.data.tick()
	check(v.data.battle.fx.attacks.size()==2,"support turn excludes support attack")
	print("COMBAT_FEEDBACK_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
