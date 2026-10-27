extends SceneTree
var failures: Array=[]
class ClaimProbe:
	extends RefCounted
	var gold: int=10
	var save_ok: bool=true
	func _save_game() -> bool: return save_ok
	func show_toast(_a,_b): pass
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label)
func _initialize() -> void:
	var v=load("res://addons/expedition/view.gd").new()
	var d=v.data;d.unlocked=10
	for id in [3,0,7]: d.team.append(d.add_unit(id,2,[4,4,4]).uid)
	var p=ClaimProbe.new()
	for round_no in [1,3,10]:
		for win in [true,false]:
			d.battle={};d.recovery_until=0;d.start(round_no,1000);d.battle.cleared=3 if win else 1;d.finish(win,1000)
			var c=v.result_copy()
			check(c.stage.begins_with("1-%d"%round_no),"actual stage")
			check(("비늘 %d"%int(d.battle.reward)) in c.record if win else c.record=="처치한 적 1 / 3","actual rewards / kills")
			check(not "1-11" in c.note,"no nonexistent unlock")
			v.rects={"claim":Rect2(0,0,50,30)};v.explore_tab=0
			var before=d.serialize().duplicate(true);var gold=p.gold
			p.save_ok=false;v.press(p,Vector2(10,10))
			check(d.serialize()==before and p.gold==gold and v.explore_tab==0,"failed save preserves result and reward")
			p.save_ok=true;v.press(p,Vector2(10,10))
			check(d.battle.is_empty() and v.explore_tab==1,"claim returns to formation")
			var once=p.gold;var pouch=d.pouches;v.press(p,Vector2(10,10))
			check(p.gold==once and d.pouches==pouch,"repeat press no duplicate reward")
	d.recovery_until=0;d.start(3,1000);d.battle.first=true;d.battle.reward_revision=0;d.finish(true,1000)
	check("어혼 1개" in v.result_copy().record,"legacy soul reward visible")
	print("EXPEDITION_RESULT_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
