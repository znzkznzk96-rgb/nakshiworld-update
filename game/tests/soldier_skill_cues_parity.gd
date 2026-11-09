extends SceneTree
const Model=preload("res://addons/expedition/model.gd")
func _init()->void:
	var traces:Dictionary={}
	for star in [1,2,3]:
		for id in 15:
			var m=Model.new();m.rng.seed=20261109;m.unlocked=10
			for i in 3:m.team.append(m.add_unit(id,star,[4,4,4]).uid)
			assert(m.start(10,1000));m.battle.index=2;m.spawn_enemy();m.battle.phase="fight";m.battle.enemy.hp=1000000;m.battle.enemy.max_hp=1000000
			for f in m.battle.fighters:f.hp=int(f.max_hp)*.6
			for n in 200:m.update(.1,1000+n*.1)
			var snapshot:Dictionary=m.serialize().duplicate(true)
			snapshot.get("battle",{}).erase("skill_popups")
			for e in snapshot.get("battle",{}).get("fx",{}).get("attacks",[]):
				for key in ["skill_id","skill_star","skill_at"]:e.erase(key)
			traces["%d:%d"%[star,id]]=JSON.stringify(snapshot,"",true).sha256_text()
	var path:String=OS.get_cmdline_user_args()[0]
	if OS.get_cmdline_user_args().size()>1:
		var expected=JSON.parse_string(FileAccess.get_file_as_string(path));assert(traces==expected,"combat timing/stats/save traces changed")
		print("SOLDIER_SKILL_PARITY_VERIFY failures=[] cases=45")
	else:
		var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(traces,"\t",true));print("BASELINE_CAPTURE cases=",traces.size())
	quit()
