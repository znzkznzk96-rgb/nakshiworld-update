extends SceneTree
var failures: Array=[]
class DrawProbe:
	extends RefCounted
	var calls: Array=[]
	func _ui_texture_rect_region(_texture,rect,region,color=Color.WHITE): calls.append({"rect":rect,"region":region,"alpha":color.a})
	func _ui_arc(_a,_b,_c,_d,_e,_f,_g): pass
	func _ui_texture_rect(_a,_b): pass
	func _ui_rect(_a,_b): pass
	func _text(_a,_b,_c,_d,_e,_f): pass
func check(ok: bool,label: String):
	if not ok: failures.append(label)
func _initialize(): call_deferred("run")
func run():
	var v=load("res://addons/expedition/view.gd").new();v.setup();var probe=DrawProbe.new()
	for id in ["3R","5R","7R","10R"]:
		var seen={};var n=320 if id=="10R" else 224
		for phase in ["approach","fight","death"]:
			for step in 301:
				var t: float=step/200.0
				v.data.battle={"phase":phase,"clock":t,"phase_time":step/100.0,"ticks":1,"fighters":[],"enemy":{"id":id,"hp":100,"max_hp":100},"fx":{"age":t,"enemy_hit":true}}
				probe.calls=[];v.battle_art(probe,Rect2(0,0,246,48))
				if probe.calls.is_empty(): continue
				var region: Rect2=probe.calls[-1].region
				seen["%d,%d"%[int(region.position.y/n),int(region.position.x/n)]]=true
		# First attack cycle has no prior hit event.
		for step in 150:
			v.data.battle.phase="fight";v.data.battle.clock=step/100.0;v.data.battle.fx={}
			var pose: Vector2i=v.enemy_pose(v.data.battle);seen["%d,%d"%[pose.y,pose.x]]=true
		check(seen.size()==24,id+" all24 original frames reachable")
	var f={"id":0,"uid":1,"hp":0,"max_hp":100,"shield":0}
	var fades: Array=[]
	for age in [0.0,.2,.5,.8,1.0]:
		v.data.battle={"phase":"defeat","clock":0,"phase_time":age,"ticks":1,"fighters":[f],"enemy":{"id":"3R","hp":100,"max_hp":100},"fx":{"age":age,"death_uid":1,"hit_uid":1}}
		probe.calls=[];v.battle_art(probe,Rect2(0,0,246,48));fades.append(probe.calls[0].alpha if probe.calls.size()==2 else 0.0)
	check(fades[0]==1 and fades[1]>fades[2] and fades[2]>fades[3] and fades[4]==0,"death fades rather than vanishes")
	f.hp=20;check(float(v.fighter_effect(f,{"age":.5,"hit_uid":1}).x)<0,"hit recoil")
	check(float(v.fighter_effect(f,{"age":.9,"hit_uid":1}).x)==0,"recoil ends")
	for rarity in 3: check(v.rarity_label({"star":3,"rarity":rarity}).contains(["레어","유니크","전설"][rarity]),"rarity labels")
	check(v.rarity_label({"star":2,"rarity":2})=="","no false low-star rarity")
	var Model=load("res://addons/expedition/model.gd")
	for id in 15:
		var b=Model.new();var skill: String=b.catalog.soldiers[id].skill
		if skill not in ["heal","regen","ward"]: continue
		for j in [3,0,id]: b.team.append(b.add_unit(j,2,[0,0,0]).uid)
		b.start(1,1000);b.battle.utility_revision=0;b.battle.enemy.hp=100000;b.battle.enemy.atk=1;b.battle.ticks=2
		b.battle.fighters[0].hp=100;b.tick()
		check(b.battle.fx.support.size()==1,skill+" emits one actual event")
		var event: Dictionary=b.battle.fx.support[0]
		check(event.source==3 and event.target==1 and event.amount>0,skill+" correct source target delta")
		var copy=Model.new();copy.restore(b.serialize());check(copy.serialize()==b.serialize(),skill+" event survives save")
		copy.update(.2,1000);check(float(copy.battle.fx.age)>=.2,"event clock advances")
	# Legacy snapshots without effect metadata stay valid and draw safely.
	v.data.battle={"phase":"fight","clock":.5,"phase_time":.5,"ticks":4,"fighters":[f],"enemy":{"id":"10R","hp":100,"max_hp":100}}
	probe.calls=[];v.battle_art(probe,Rect2(0,0,246,48));check(probe.calls.size()==2,"legacy battle without fx")
	print("EXPEDITION_MOTION_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
