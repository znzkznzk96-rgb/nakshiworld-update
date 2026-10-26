extends RefCounted
# One save transaction owns inventory, pending alchemy, battle and unclaimed rewards.
const ELEMENTS = ["물", "전기", "독", "빛", "어둠"]
const TICK = 1.5
const POWER = 0.2
const BALANCE_REVISION = 1
const ENEMY_ATTACK_SCALE = [3.0,3.5,3.2,5.0,2.5,4.5,1.5,3.5,3.5,1.0]
const START_SHIELD_RATIO = 0.044
const POUCH_DROP_CHANCE = 0.25
const POUCH_PRICE = 500
const FIRST_POUCHES = [1,1,2,1,3,1,4,1,1,5]
const BOSS_POUCH_CHANCE = {3:0.05,5:0.08,7:0.12,10:0.20}
var pouches: int = 0
const TRAINING = [0.70,0.80,0.90,1.0]
var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://addons/expedition/catalog.json"))
var souls: Array = [0,0,0,0,0]
var soldiers: Array = []
var discovered: Array = []
var team: Array = []
var next_uid: int = 1
var unlocked: int = 1
var completed: Array = []
var pending: Dictionary = {}
var battle: Dictionary = {}
var recovery_until: float = 0
var rng = RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

func serialize() -> Dictionary:
	return {"pouches":pouches,"v":3,"discovered":discovered.duplicate(),"souls":souls.duplicate(),"soldiers":soldiers.duplicate(true),"team":team.duplicate(),"next_uid":next_uid,"unlocked":unlocked,"completed":completed.duplicate(),"pending":pending.duplicate(true),"battle":battle.duplicate(true),"recovery_until":recovery_until}

func restore(d: Dictionary) -> void:
	pouches=maxi(0,int(d.get("pouches",0)))
	souls=[0,0,0,0,0];soldiers=[];discovered=[];team=[];completed=[];pending={};battle={};next_uid=1;unlocked=1;recovery_until=0
	var history=d.get("discovered",[])
	if history is Array:
		for id in history:
			if (id is int or id is float) and float(id)==int(id) and int(id) in range(15): discover(int(id))
	var stored: Array=d.get("souls",[])
	for i in mini(5,stored.size()): souls[i]=maxi(0,int(stored[i]))
	for u in d.get("soldiers",[]):
		if not u is Dictionary or int(u.get("id",-1)) not in range(15): continue
		var uid: int=int(u.get("uid",0))
		if uid<1 or not unit(uid).is_empty(): continue
		var iv: Array=u.get("iv",[0,0,0]);iv.resize(3)
		for i in 3: iv[i]=clampi(int(iv[i]),0,8)
		soldiers.append({"uid":uid,"id":int(u.id),"star":clampi(int(u.get("star",1)),1,3),"iv":iv,"rarity":clampi(int(u.get("rarity",0)),0,2),"level":clampi(int(u.get("level",0)),0,3),"locked":bool(u.get("locked",false))})
		discover(int(u.id))
		next_uid=maxi(next_uid,uid+1)
	next_uid=maxi(next_uid,int(d.get("next_uid",1)))
	for uid in d.get("team",[]):
		if team.size()<3 and not int(uid) in team and not unit(int(uid)).is_empty(): team.append(int(uid))
	unlocked=clampi(int(d.get("unlocked",1)),1,10)
	for r in d.get("completed",[]):
		if int(r) in range(1,11) and not int(r) in completed: completed.append(int(r))
	pending=d.get("pending",{}).duplicate(true)
	battle=d.get("battle",{}).duplicate(true)
	recovery_until=maxf(0,float(d.get("recovery_until",0)))

func unit(uid: int) -> Dictionary:
	for u in soldiers:
		if int(u.uid)==uid: return u
	return {}

func discover(id: int) -> void:
	if id in range(15) and id not in discovered: discovered.append(id)

func is_discovered(id: int) -> bool:
	return id in discovered

func add_unit(id: int, star: int=1, iv: Array=[]) -> Dictionary:
	var u: Dictionary={"uid":next_uid,"id":id,"star":star,"iv":roll_iv() if iv.is_empty() else iv.map(func(n):return int(n)),"rarity":0,"level":0,"locked":false}
	next_uid+=1;soldiers.append(u);discover(id)
	return u

func roll_iv() -> Array:
	return [rng.randi_range(0,8),rng.randi_range(0,8),rng.randi_range(0,8)]

func on_capture(_sp: int) -> bool:
	if rng.randf()>=POUCH_DROP_CHANCE: return false
	pouches+=1
	return true

func open_pouches(count: int) -> Array:
	if count<1 or count>pouches: return []
	var result: Array=[0,0,0,0,0]
	for i in count: result[rng.randi_range(0,4)]+=1
	pouches-=count
	for i in 5: souls[i]+=int(result[i])
	return result

func recipe(a: int,b: int) -> int:
	for i in catalog.soldiers.size():
		var e: Array=catalog.soldiers[i].elements
		if (int(e[0])==a and int(e[1])==b) or (int(e[0])==b and int(e[1])==a): return i
	return -1

func active() -> bool:
	return not battle.is_empty() and battle.get("status","")=="running"

func craft(a: int,b: int) -> bool:
	if not pending.is_empty() or soldiers.size()>=60 or a not in range(5) or b not in range(5): return false
	if int(souls[a])<1 or int(souls[b])<(2 if a==b else 1): return false
	souls[a]-=1;souls[b]-=1
	var u: Dictionary=add_unit(recipe(a,b))
	pending={"kind":"craft","uid":u.uid}
	return true

func merge_cost(a: int,b: int) -> Dictionary:
	var ua: Dictionary=unit(a);var ub: Dictionary=unit(b)
	if a==b or ua.is_empty() or ub.is_empty(): return {}
	if int(ua.star)!=int(ub.star) or int(ua.star)>=3: return {}
	if int(ua.get("level",0))!=3 or int(ub.get("level",0))!=3: return {}
	var es: Array=catalog.soldiers[int(ua.id)].elements.duplicate()
	es.append_array(catalog.soldiers[int(ub.id)].elements)
	var costs: Array=[0,0,0,0,0]
	# One matching soul per material at 1star; two per material at 2star.
	costs[int(es[0])]+=int(ua.star);costs[int(es[2])]+=int(ua.star)
	var candidates: Array=[]
	for x in catalog.soldiers[int(ua.id)].elements:
		for y in catalog.soldiers[int(ub.id)].elements:
			var id: int=recipe(int(x),int(y))
			if id not in candidates: candidates.append(id)
	return {"souls":costs,"gold":200 if int(ua.star)==2 else 0,"candidates":candidates,"star":int(ua.star)+1}

func begin_merge(a: int,b: int,gold: int) -> Dictionary:
	var q: Dictionary=merge_cost(a,b)
	if active() or not pending.is_empty() or q.is_empty(): return {}
	if unit(a).get("locked",false) or unit(b).get("locked",false): return {}
	if gold<int(q.gold): return {}
	for i in 5:
		if int(souls[i])<int(q.souls[i]): return {}
	var ivs: Array=[unit(a).iv.duplicate(),unit(b).iv.duplicate(),roll_iv()]
	var id: int=int(q.candidates[rng.randi_range(0,q.candidates.size()-1)])
	for i in 5: souls[i]-=int(q.souls[i])
	var positions: Array=[]
	for uid in [a,b]:
		if uid in team: positions.append(team.find(uid))
	soldiers=soldiers.filter(func(u): return int(u.uid)!=a and int(u.uid)!=b)
	team=team.filter(func(uid): return int(uid)!=a and int(uid)!=b)
	var rarity: int=0
	if int(q.star)==3:
		var roll: float=rng.randf();rarity=2 if roll<0.05 else (1 if roll<0.25 else 0)
	pending={"kind":"merge","id":id,"star":q.star,"ivs":ivs,"rarity":rarity,"team_position":positions.min() if not positions.is_empty() else -1}
	return q

func finish_merge(option: int) -> bool:
	if pending.get("kind","")!="merge" or option not in range(3): return false
	var u: Dictionary=add_unit(int(pending.id),int(pending.star),pending.ivs[option])
	u.rarity=int(pending.rarity)
	if int(pending.team_position)>=0 and team.size()<3: team.insert(mini(int(pending.team_position),team.size()),int(u.uid))
	pending={"kind":"craft","uid":u.uid}
	return true

func training_cost(uid: int) -> Dictionary:
	var u: Dictionary=unit(uid)
	if u.is_empty() or int(u.get("level",0))>=3: return {}
	var level: int=int(u.get("level",0))
	return {"gold":int(u.star)*[100,200,400][level],"element":int(catalog.soldiers[int(u.id)].elements[0]),"souls":level+1}

func train(uid: int,gold: int) -> Dictionary:
	var cost: Dictionary=training_cost(uid)
	if cost.is_empty() or active() or not pending.is_empty(): return {}
	if gold<int(cost.gold) or int(souls[int(cost.element)])<int(cost.souls): return {}
	souls[int(cost.element)]-=int(cost.souls)
	unit(uid).level=int(unit(uid).get("level",0))+1
	return cost

func stats(u: Dictionary) -> Dictionary:
	var v: Dictionary=catalog.soldiers[int(u.id)].stars[str(int(u.star))]
	var bonus: float=[1.0,1.04,1.08][int(u.get("rarity",0))] if int(u.star)==3 else 1.0
	bonus*=TRAINING[clampi(int(u.get("level",0)),0,3)]
	return {"hp":roundi(float(v.hp)*(1+int(u.iv[0])/100.0)*bonus),"atk":roundi(float(v.atk)*(1+int(u.iv[1])/100.0)*bonus),"def":roundi(float(v.def)*(1+int(u.iv[2])/100.0)*bonus)}

func start(round_no: int,now: float) -> bool:
	if not battle.is_empty() or not pending.is_empty() or now<recovery_until or team.size()!=3 or round_no<1 or round_no>unlocked: return false
	var fighters: Array=[]
	for uid in team:
		var u: Dictionary=unit(int(uid))
		if u.is_empty(): return false
		var st: Dictionary=stats(u)
		fighters.append({"id":u.id,"uid":u.uid,"hp":st.hp,"max_hp":st.hp,"atk":st.atk,"def":st.def,"shield":0,"hits":0})
	battle={"reward_revision":1,"pouch_reward":0,"repeat_pouch_roll":rng.randf(),"balance_revision":BALANCE_REVISION,"status":"running","round":round_no,"index":0,"fighters":fighters,"ticks":0,"clock":0.0,"phase":"approach","phase_time":0.0,"reward":0,"cleared":0,"first":round_no not in completed,"last_damage":0,"progress":0.0,"result_seen":false}
	spawn_enemy()
	return true

func spawn_enemy() -> void:
	var revised: bool=int(battle.get("balance_revision",0))>=1
	var key=catalog.rounds[int(battle.round)-1][int(battle.index)]
	for e in catalog.enemies:
		if str(e.id)==str(key):
			battle.enemy=e.duplicate(true);battle.enemy.max_hp=int(e.hp);battle.enemy.poison=0
			if revised: battle.enemy.atk=roundi(float(e.atk)*ENEMY_ATTACK_SCALE[int(battle.round)-1])
			break
	for f in battle.fighters:
		if int(f.hp)>0 and skill(f)=="shield": f.shield=roundi(int(f.max_hp)*(START_SHIELD_RATIO if revised else 0.22))
	battle.fx={};battle.ticks=0;battle.clock=0.0;battle.phase="approach";battle.phase_time=0.0

func skill(f: Dictionary) -> String:
	return str(catalog.soldiers[int(f.id)].skill)

func damage(atk: float,defense: float) -> int:
	return maxi(1,roundi(atk*POWER*100.0/(100.0+maxf(0,defense))))

func hurt(f: Dictionary,amount: int) -> void:
	var blocked: int=mini(int(f.shield),amount);f.shield-=blocked;f.hp=maxi(0,int(f.hp)-amount+blocked)

func tick() -> void:
	var living: Array=battle.fighters.filter(func(f): return int(f.hp)>0)
	if living.is_empty(): finish(false);return
	battle.ticks+=1
	var enemy: Dictionary=battle.enemy
	var front: Dictionary=living[0]
	var enemy_def: float=float(enemy.defense)
	var enemy_atk: float=float(enemy.atk)
	for f in living:
		if skill(f)=="curse": enemy_def*=0.7
		if skill(f)=="weaken": enemy_atk*=0.8
	# Debuffs do not multiply with duplicate soldiers.
	enemy_def=maxf(enemy_def,float(enemy.defense)*0.7);enemy_atk=maxf(enemy_atk,float(enemy.atk)*0.8)
	battle.fx={"front_hp_before":int(front.hp),"enemy_hp_before":int(enemy.hp),"age":0.0,"hit_uid":int(front.uid),"death_uid":-1,"support":[],"enemy_hit":true}
	var attack: int=roundi(int(enemy.poison)*POWER)
	var heals: Array=[]
	for f in living:
		var sk: String=skill(f)
		if int(battle.ticks)%3==0 and sk in ["regen","heal","ward"]:
			heals.append([sk,int(f.atk),int(f.uid)]);continue
		var power: float=float(f.atk)
		if int(battle.ticks)%3==0 and sk=="bolt": power*=1.75
		if int(battle.ticks)%3==0 and sk=="flurry": power*=1.5
		attack+=damage(power,enemy_def*0.5 if sk=="pierce" else enemy_def)
		if sk=="drain": f.hp=mini(int(f.max_hp),int(f.hp)+roundi(power*0.18*POWER))
		if sk=="poison": enemy.poison=mini(18,int(enemy.poison)+maxi(1,roundi(power*0.08)))
	var incoming: int=damage(enemy_atk,float(front.def))
	battle.fx.blocked=mini(int(front.shield),incoming)
	battle.fx.incoming=mini(int(front.hp),incoming-int(battle.fx.blocked))
	hurt(front,incoming);front.hits+=1
	if skill(front)=="thorns": enemy.poison=mini(18,int(enemy.poison)+3)
	if skill(front)=="reflect": attack+=roundi(incoming*0.25)
	if skill(front)=="counter" and int(front.hits)%3==0: attack+=damage(float(front.atk)*1.5,enemy_def)
	if skill(front)=="mend" and int(front.hp)>0: front.hp=mini(int(front.max_hp),int(front.hp)+roundi(incoming*0.15))
	for heal in heals:
		var survivors: Array=battle.fighters.filter(func(f): return int(f.hp)>0)
		if survivors.is_empty(): break
		var target: Dictionary=survivors[0]
		if heal[0]=="heal":
			for f in survivors:
				if float(f.hp)/float(f.max_hp)<float(target.hp)/float(target.max_hp): target=f
		var old_hp: int=int(target.hp);var old_shield: int=int(target.shield)
		if heal[0]=="ward": target.shield=mini(roundi(int(target.max_hp)*0.25),int(target.shield)+roundi(int(heal[1])*POWER))
		else: target.hp=mini(int(target.max_hp),int(target.hp)+roundi(int(heal[1])*POWER*(1.0 if heal[0]=="heal" else 0.85)))
		battle.fx.support.append({"source":int(heal[2]),"target":int(target.uid),"kind":str(heal[0]),"amount":int(target.shield)-old_shield if heal[0]=="ward" else int(target.hp)-old_hp})
	if int(front.hp)<=0: battle.fx.death_uid=int(front.uid)
	battle.fx.outgoing=mini(int(enemy.hp),attack)
	enemy.hp=maxi(0,int(enemy.hp)-attack);battle.last_damage=attack
	if battle.fighters.all(func(f): return int(f.hp)<=0):
		battle.phase="defeat";battle.phase_time=0.0
	elif int(enemy.hp)<=0:
		battle.phase="death";battle.phase_time=0.0;battle.cleared+=1;battle.reward+=int(battle.round)*2
	elif int(battle.ticks)>=600:
		battle.phase="defeat";battle.phase_time=0.0

func update(dt: float,now: float) -> bool:
	if not active(): return false
	if battle.has("fx"): battle.fx.age=float(battle.fx.get("age",0))+dt
	battle.phase_time+=dt
	var previous_progress: int=int(battle.get("progress",0))
	var target: float=(float(battle.index)+(1.0-float(battle.enemy.hp)/maxf(1,float(battle.enemy.max_hp))))/3.0*100.0
	battle.progress=move_toward(float(battle.get("progress",0)),minf(99,target),dt*6.0)
	if battle.phase=="approach":
		if float(battle.phase_time)>=4.0: battle.phase="fight";battle.phase_time=0.0
	elif battle.phase=="fight":
		battle.clock+=dt
		if float(battle.clock)>=TICK:
			battle.clock-=TICK;tick();return true
	elif battle.phase=="death":
		if float(battle.phase_time)>=2.3 and (int(battle.index)<2 or previous_progress>=99):
			battle.index+=1
			if int(battle.index)>=3: finish(true,now)
			else: spawn_enemy()
			return true
	elif battle.phase=="defeat":
		if float(battle.phase_time)>=1.0: finish(false,now);return true
	return false

func finish(win: bool,now: float=0) -> void:
	if not active(): return
	battle.status="win" if win else "loss"
	battle.result_seen=false
	if int(battle.get("reward_revision",0))>=1:
		battle.reward=(26*int(battle.round) if bool(battle.first) else 2*int(battle.round)) if win else 0
		battle.pouch_reward=0
		if win and bool(battle.first): battle.pouch_reward=FIRST_POUCHES[int(battle.round)-1]
		elif win and float(battle.get("repeat_pouch_roll",1.0))<float(BOSS_POUCH_CHANCE.get(int(battle.round),0.0)): battle.pouch_reward=1
	if win: battle.progress=100.0
	if win:
		unlocked=mini(10,maxi(unlocked,int(battle.round)+1))
		if int(battle.round) not in completed:
			completed.append(int(battle.round))
			if int(battle.get("reward_revision",0))==0: battle.reward+=20*int(battle.round)
	recovery_until=(Time.get_unix_time_from_system() if now==0 else now)+30.0

func claim() -> Dictionary:
	if battle.is_empty() or active(): return {}
	var reward: Dictionary={"gold":int(battle.reward),"soul":-1,"pouches":int(battle.get("pouch_reward",0))}
	pouches+=int(reward.pouches)
	if battle.status=="win" and bool(battle.first) and int(battle.get("reward_revision",0))==0:
		reward.soul=(int(battle.round)-1)%5;souls[int(reward.soul)]+=1
	battle={}
	return reward
