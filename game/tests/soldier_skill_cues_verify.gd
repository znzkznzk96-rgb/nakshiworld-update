extends SceneTree
const Model=preload("res://addons/expedition/model.gd")
const Cues=preload("res://addons/expedition/skill_feedback.gd")
var failures:Array=[]
class Probe extends RefCounted:
	var textures:Array=[]
	var rects:Array=[]
	var labels:Array=[]
	var colors:Array=[]
	func _ui_rect(r,c):rects.append([r,c])
	func _ui_texture_rect(t,r,_flip=false,_color=Color.WHITE):textures.append([t,r])
	func _text(s,_p,_size,c,_center,_width):labels.append(s);colors.append(c)
func check(ok:bool,label:String)->void:
	if not ok:failures.append(label);push_error(label)
func team(ids:Array,star:int=3):
	var m=Model.new();m.rng.seed=123;m.unlocked=10
	for id in ids:m.team.append(m.add_unit(id,star,[4,4,4]).uid)
	m.start(1,1000);m.battle.phase="fight";m.battle.enemy.hp=100000;m.battle.enemy.max_hp=100000
	return m
func _init()->void:
	var c=Cues.new();var m=team([0,1,5]);m.battle.skill_time=2.9;m.battle.skill_accumulator=.06
	for f in m.battle.fighters:check(c.cue(m,f).get("kind","")=="prepare","all simultaneous casters get their own advance cue")
	m.battle.skill_time=3;m.battle.skill_accumulator=0
	for f in m.battle.fighters:m.TIER_SKILLS.cast(m,f);f.skill_ready=99
	m.battle.skill_time=3.1
	for f in m.battle.fighters:check(c.cue(m,f).get("kind","")=="cast","real cast holds its source icon")
	var events:Array=c.skill_events(m.battle.fx.attacks)
	check(events.size()==3,"same-source same-time multi-hit has one summed damage label")
	var before_sum:int=0;var after_sum:int=0
	for e in m.battle.fx.attacks:before_sum+=int(e.amount)
	for e in events:after_sum+=int(e.amount)
	check(before_sum==after_sum,"damage label grouping preserves damage total")
	for e in events:check(e.has("skill_id") and e.has("skill_star"),"skill damage records identity and tier")
	var restored=Model.new();restored.restore(JSON.parse_string(JSON.stringify(m.serialize())))
	check(restored.battle.skill_popups.size()==m.battle.skill_popups.size(),"popup count survives existing save roundtrip")
	for i in m.battle.skill_popups.size():
		var a:Dictionary=m.battle.skill_popups[i];var b:Dictionary=restored.battle.skill_popups[i]
		for key in ["source","amount","skill_id","skill_star"]:check(int(a[key])==int(b[key]),"popup identity/amount survives JSON numeric conversion")
		check(absf(float(a.skill_at)-float(b.skill_at))<.000001,"popup event time survives reload")
	var snapshot:Dictionary=m.serialize().duplicate(true);var rng_state:int=m.rng.state
	for f in m.battle.fighters:
		var p=Probe.new();c.draw_caster(p,m,f,Vector2(30,20),16,c.cue(m,f))
		check(p.textures.size()==1,"one existing tiered icon per source")
	check(m.serialize()==snapshot and m.rng.state==rng_state,"rendering never changes combat save state or RNG")
	m.battle.skill_time=3.91;m.battle.fx.age=0
	for f in m.battle.fighters:check(c.cue(m,f).is_empty(),"other attack age resets cannot extend old source cue")
	m.battle.skill_time=5;m.TIER_SKILLS.hit(m,m.battle.fighters[0],100)
	check(c.cue(m,m.battle.fighters[0]).get("kind","")=="cast","periodic or counter hit identifies its original caster")
	var heal=team([7,6,12]);heal.battle.skill_time=3
	for f in heal.battle.fighters:check(c.cue(heal,f).is_empty(),"full-health conditional heals do not fake a cast")
	heal.battle.fighters[0].hp-=10
	for f in heal.battle.fighters:check(c.cue(heal,f).get("kind","")=="prepare","eligible heal predicts next unchanged .1s step")
	var recent_count:int=c.damage_events(m.battle).size();m.battle.fx={}
	check(c.damage_events(m.battle).size()==recent_count,"normal FX reset cannot erase actual skill damage feedback")
	check(m.battle.skill_popups.size()<=48,"presentation event buffer is bounded")
	var old=team([0,1,5]);old.battle.erase("tier_skill_revision")
	check(c.cue(old,old.battle.fighters[0]).is_empty(),"legacy save stays compatible")
	var v=load("res://addons/expedition/view.gd").new();v.data=m;v.textures.role_attack=load("res://art/ui/roles/attack.png")
	var skill_probe=Probe.new();v.damage_value(skill_probe,Vector2(60,50),321,"attack",.1,events[1])
	var normal_probe=Probe.new();v.damage_value(normal_probe,Vector2(60,50),123,"attack",.1)
	check(skill_probe.labels.has("321") and normal_probe.labels.has("123"),"skill and normal numeric damage stay visible")
	check(skill_probe.colors[0]!=normal_probe.colors[0],"skill border has source element color")
	check(skill_probe.textures[0][0]!=normal_probe.textures[0][0],"skill icon differs from normal role icon")
	# Mixed simultaneous normal / skill hits, expired entries, all supported room heights.
	m.battle.skill_time=3.2;m.battle.skill_accumulator=0;m.battle.fx.age=.25
	m.battle.skill_popups=[];m.battle.fx.attacks=[]
	for i in 3:
		var f:Dictionary=m.battle.fighters[i]
		m.battle.fx.attacks.append({"source":f.uid,"amount":123456,"role":"attack"})
		m.battle.skill_popups.append({"source":f.uid,"amount":321,"role":"attack","skill_at":3.0,"skill_id":f.id,"skill_star":3})
	var saved:Dictionary=m.serialize().duplicate(true);var saved_rng:int=m.rng.state
	for height in [48,60,78,120]:
		var room:=Rect2(10,30,246,height)
		var labels:Array=c.damage_layout(m,room,190)
		check(labels.size()==3,"mixed hits capped at three")
		check(labels.any(func(v):return not v.skill) and labels.any(func(v):return v.skill),"normal and skill both get space")
		for i in labels.size():
			check(room.encloses(labels[i].rect),"label fully inside room")
			for j in range(i):check(not labels[i].rect.intersects(labels[j].rect),"damage label rectangles do not overlap")
	check(m.serialize()==saved and m.rng.state==saved_rng,"layout leaves combat and RNG untouched")
	m.battle.skill_time=4.1;m.battle.fx.age=1.1
	check(c.damage_layout(m,Rect2(0,0,246,60),180).is_empty(),"expired labels free all slots")
	for star in [1,2,3]:
		for id in 15:check(c.texture(id,star)!=null,"all 45 existing skill icons resolve")
	print("SOLDIER_SKILL_CUES_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
