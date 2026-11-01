extends RefCounted
# Timed tier skills. All state belongs to the serializable battle dictionary.
const CDS = [[7,8,8,9,9,6,8,9,8,8,9,8,9,8,8],[6,8,8,8,8,5,7,8,8,7,8,7,7,7,6],[8,10,9,11,10,7,10,10,10,9,10,9,9,8,10]]
const NAMES = [["흡수", "전격 화살", "독가시", "보호막", "등불의 격려", "연속 베기", "재생", "긴급 회복", "회복 방패", "약화", "방어 관통", "반격", "보호 약초", "맹독", "피해 반사"],["물살 찌르기","전격 연사","독가시 부여","돌비늘","쇠약의 등불","바람 베기","재생 물방울","응급 치유","물의 장막","부식 물약","철갑 깨기","불꽃 엄호","약초 처방","급소 찌르기","달빛 받아치기"],["해일창","낙뢰","맹독 안개","대지 성벽","영혼 등불","폭풍 검무","생명의 비","기적의 물결","해류 수호","봉인 물약","분쇄 망치","불사르는 방패","숲의 결계","그림자 처형","거울달"]]
const DESCS = [["공격력 100% 피해 · 시전자 최대 체력 3% 회복", "공격력 150% 피해", "전열 독가시 4초 · 피격 시 매초 공격력 8% 독 3초", "전열 보호막: 시전자 최대 체력 8% · 4초", "아군 일반 공격에 시전자 공격력 20% 추가 · 3초", "공격력 60%로 2회 공격", "4초간 매초 시전자 최대 체력 1.5% 회복", "가장 다친 아군 공격력 120% 회복", "전열 아군을 시전자 최대 체력 8%만큼 회복", "공격력 80% 피해 · 적 공격력 감소 4초", "공격력 150% 피해 · 방어 25% 무시", "전열 다음 공격 방어 · 방어력 비례 반격", "전열에 공격력 120% 보호막 · 4초", "매초 공격력 15% 독 피해 · 4초", "전열 피해 일부 방어·반사 · 3초"],["공격력 90%로 2회 공격","공격력 80%로 3회 공격","전열에 독가시 5초 · 피격 시 공격력 15% 독 4초","전열 보호막: 시전자 최대 체력 12% · 5초","공격력 120% 피해 · 적 공격력 감소 4초","공격력 75%로 2회 공격","5초간 매초 시전자 최대 체력 2% 회복","공격력 180% 회복 · 체력 40% 이하면 240%","전열 피해 감소: 방어력 80% · 4초","공격력 100% 피해 · 적 방어력 감소 5초","공격력 220% 피해 · 적 방어력 감소 4초","공격력 100%+방어력 150% 피해 · 전열 보호막 6%","공격력 140% 회복 · 중독 제거","공격력 230% 피해 · 방어 20% 무시","다음 공격 방어·반격 · 방어 준비 4초"],["공격력 340% 피해 · 방어 50% 무시","공격력 420% 피해 · 기절 1초(보스 0.5초)","매초 공격력 45% 독 · 적 공격력 감소 · 5초","전체 보호막: 시전자 최대 체력 15% · 6초","아군 일반 공격에 시전자 공격력 55% 추가 · 5초","공격력 85%로 4회 공격","전체에 매초 시전자 최대 체력 2.5% 회복 · 5초","공격력 300% 회복(위기 400%) · 전체 정화","전체 피해 감소: 방어력 130% · 5초","공격력 200% 피해 · 공격력·다음 특수 공격 약화","공격력 400% 피해 · 보호막에 먼저 250% 추가","전열 보호막 16% · 종료 시 공격력 180%+방어력 250%","공격력 240% 보호막 · 매초 25% 회복 · 5초","공격력 170% 2회 · 적 체력 30% 이하면 총 510%","전열 피해 감소: 방어력 150% · 막은 피해 반사 · 5초"]]

static func info(id:int,star:int)->Dictionary:
	if star<1:return {}
	return {"name":NAMES[star-1][id],"cd":CDS[star-1][id],"description":DESCS[star-1][id]}

static func enabled(m)->bool:
	return int(m.battle.get("tier_skill_revision",0))==1

static func living(m)->Array:
	return m.battle.fighters.filter(func(f):return int(f.hp)>0)

static func init_encounter(m)->void:
	m.battle.skill_time=0.0;m.battle.skill_accumulator=0.0;m.battle.normal_time=0.0
	m.battle.enemy_ready=m.TICK;m.battle.enemy_delay=0.0
	m.battle.skill_effects=[];m.battle.skill_casts=[];m.battle.stun_left=0.0;m.battle.stun_immune_until=0.0
	for f in m.battle.fighters:
		f.shield=0;f.skill_ready=0.0 if int(f.id) in [2,3,8,14] else 3.0
		if int(f.id) in [6,7,12]:f.skill_ready=0.0
		f.skill_count=0;f.skill_damage=0;f.skill_healing=0;f.skill_shield=0
		f.skill_layers=[];f.base_shield=0;f.shield_previous=0;f.hot_used=0.0;f.hot_second=-1;f.imbue_ready=0.0
		if int(f.get("star",1))==1 and m.skill(f)=="shield":
			f.shield=roundi(int(f.max_hp)*m.START_SHIELD_RATIO);f.base_shield=f.shield;f.shield_previous=f.shield
	# Protect immediately on entering fight, not during the approach animation.

static func effect(m,kind:String,f:Dictionary,target:Dictionary,duration:float,value:float,extra:Dictionary={})->void:
	var e:Dictionary={"kind":kind,"source":int(f.uid),"target":int(target.get("uid",-1)),"until":float(m.battle.skill_time)+duration,"next":float(m.battle.skill_time)+1.0,"value":value}
	e.merge(extra)
	# Same named skill refreshes; different skills do not multiply debuffs.
	m.battle.skill_effects=m.battle.skill_effects.filter(func(v):return not(v.kind==kind and int(v.target)==int(e.target) and (not kind.begins_with("reduce_") or int(v.source)==int(f.uid))))
	m.battle.skill_effects.append(e)

static func source(m,uid:int)->Dictionary:
	for f in m.battle.fighters:
		if int(f.uid)==uid:return f
	return {}

static func sync_shield(f:Dictionary)->void:
	var lost:float=maxf(0,float(f.get("shield_previous",0))-float(f.shield))
	var base:float=minf(float(f.get("base_shield",0)),lost)
	f.base_shield=float(f.get("base_shield",0))-base;lost-=base
	for layer in f.get("skill_layers",[]):
		var take:float=minf(float(layer.left),lost);layer.left-=take;lost-=take
	# Tier1 utility can add shields between timed steps.
	if int(f.shield)>int(f.get("shield_previous",0)):f.base_shield+=int(f.shield)-int(f.get("shield_previous",0))
	f.shield_previous=f.shield

static func rebuild_shield(f:Dictionary)->void:
	var total:float=float(f.base_shield)
	for layer in f.skill_layers:total+=float(layer.left)
	f.shield=mini(roundi(float(f.max_hp)*.35),roundi(total));f.shield_previous=f.shield

static func shield(m,f:Dictionary,t:Dictionary,amount:float,duration:float,burst:float=0)->void:
	sync_shield(t)
	var key:String=str(int(f.id))+":"+str(int(f.star))
	t.skill_layers=t.skill_layers.filter(func(v):return v.key!=key)
	rebuild_shield(t)
	var added:float=maxf(0,minf(amount,float(t.max_hp)*.35-float(t.shield)))
	t.skill_layers.append({"key":key,"source":int(f.uid),"left":added,"until":float(m.battle.skill_time)+duration,"burst":burst})
	f.skill_shield+=roundi(added);rebuild_shield(t)
	feedback(m,f,t,"ward",roundi(added))

static func feedback(m,f:Dictionary,t:Dictionary,kind:String,amount:int)->void:
	if not m.battle.has("fx"):m.battle.fx={}
	if not m.battle.fx.has("support"):m.battle.fx.support=[]
	m.battle.fx.age=0.0
	m.battle.fx.support.append({"source":int(f.uid),"target":int(t.uid),"kind":kind,"amount":amount})

static func heal(m,f:Dictionary,t:Dictionary,amount:float,hot:bool=false)->void:
	if int(t.hp)<=0:return
	var limit:float=float(t.max_hp)*.30
	if hot:
		var sec:int=floori(float(m.battle.skill_time)+.0001)
		if int(t.hot_second)!=sec:t.hot_second=sec;t.hot_used=0.0
		limit=maxf(0,float(t.max_hp)*.05-float(t.hot_used))
	var actual:int=mini(int(t.max_hp)-int(t.hp),maxi(0,floori(minf(amount,limit))))
	t.hp+=actual;f.skill_healing+=actual
	if hot:t.hot_used+=actual
	feedback(m,f,t,"heal",actual)

static func hit(m,f:Dictionary,power:float,ignore:float=0,raw:bool=false)->void:
	var defense:float=0.0 if raw else enemy_stat(m,"defense")*(1.0-ignore)
	# Skill descriptions use literal ATK percentages. POWER only scales normal attacks.
	var amount:int=maxi(1,roundi(power*100.0/(100.0+maxf(0,defense))))
	var e:Dictionary=m.battle.enemy
	var blocked:int=mini(int(e.get("shield",0)),amount);e.shield=int(e.get("shield",0))-blocked
	var actual:int=mini(int(e.hp),amount-blocked);e.hp-=actual;f.skill_damage+=actual
	if not m.battle.has("fx"):m.battle.fx={}
	if not m.battle.fx.has("attacks"):m.battle.fx.attacks=[]
	m.battle.fx.attacks.append({"source":int(f.uid),"role":str(m.catalog.soldiers[int(f.id)].role),"amount":actual})
	m.battle.fx.outgoing=actual;m.battle.fx.age=0.0

static func enemy_stat(m,key:String)->float:
	var reduction:float=0
	for e in m.battle.skill_effects:
		if e.kind=="reduce_"+key and float(e.until)>float(m.battle.skill_time):reduction=maxf(reduction,float(e.value))
	return float(m.battle.enemy[key])-minf(float(m.battle.enemy[key])*.30,reduction)

static func weakest(m)->Dictionary:
	var a:Array=living(m)
	a.sort_custom(func(x,y):return float(x.hp)/float(x.max_hp)<float(y.hp)/float(y.max_hp))
	return a[0] if not a.is_empty() else {}

static func cast(m,f:Dictionary)->bool:
	var a:Array=living(m)
	if a.is_empty() or int(m.battle.enemy.hp)<=0:return false
	var front:Dictionary=a[0];var t:Dictionary=weakest(m)
	var id:int=int(f.id);var high:bool=int(f.star)==3
	if int(f.star)==1:
		if not cast_basic(m,f,front,t):return false
		record_cast(m,f);return true
	var atk:float=float(f.atk);var defense:float=float(f.def);var hp:float=float(f.max_hp)
	if id in [6,7,12] and int(t.hp)==int(t.max_hp):
		var bad:bool=a.any(func(v):return not v.get("debuffs",[]).is_empty())
		if not bad or id==6:return false
	match id:
		0:
			if high:hit(m,f,atk*3.4,.5)
			else:
				for n in 2:hit(m,f,atk*.9)
		1:
			if high:
				hit(m,f,atk*4.2)
				if float(m.battle.skill_time)>=float(m.battle.stun_immune_until):
					var duration:float=.5 if int(m.battle.index)==2 else 1.0
					m.battle.stun_left=duration;m.battle.stun_immune_until=float(m.battle.skill_time)+duration+3.0
			else:
				for n in 3:hit(m,f,atk*.8)
		2:
			if high:
				effect(m,"fog",f,{},5,atk*.45);effect(m,"reduce_atk",f,{},5,atk*.20)
			else:effect(m,"thorns",f,front,5,atk*.15)
		3:
			for v in (a if high else [front]):shield(m,f,v,hp*(.15 if high else .12),6 if high else 5)
		4:
			if high:effect(m,"imbue",f,{},5,atk*.55)
			else:
				hit(m,f,atk*1.2);effect(m,"reduce_atk",f,{},4,atk*.15)
		5:
			for n in (4 if high else 2):hit(m,f,atk*(.85 if high else .75))
		6:
			for v in (a if high else [t]):effect(m,"regen",f,v,5,hp*(.025 if high else .02))
		7:
			var low:bool=float(t.hp)/float(t.max_hp)<=.40
			heal(m,f,t,atk*((4.0 if low else 3.0) if high else (2.4 if low else 1.8)))
			if high:
				for v in a:
					if not v.get("debuffs",[]).is_empty():v.debuffs.pop_front()
		8:
			for v in (a if high else [front]):effect(m,"veil",f,v,5 if high else 4,defense*(1.3 if high else .8),{"cap":.35 if high else .25})
		9:
			hit(m,f,atk*(2.0 if high else 1.0))
			if high:
				effect(m,"reduce_atk",f,{},6,atk*.20);effect(m,"seal",f,{},6,atk)
			else:effect(m,"reduce_defense",f,{},5,atk*.12)
		10:
			if high:
				m.battle.enemy.shield=maxi(0,int(m.battle.enemy.get("shield",0))-roundi(atk*2.5));hit(m,f,atk*4.0)
			else:
				hit(m,f,atk*2.2);effect(m,"reduce_defense",f,{},4,atk*.10)
		11:
			if high:shield(m,f,front,hp*.16,5,atk*1.8+defense*2.5)
			else:
				hit(m,f,atk+defense*1.5);shield(m,f,front,hp*.06,4)
		12:
			if high:
				shield(m,f,t,atk*2.4,5);effect(m,"herb_hot",f,t,5,atk*.25)
			else:
				for v in a:
					if v.get("debuffs",[]).any(func(d):return d.get("kind","")=="poison"):t=v;break
				heal(m,f,t,atk*1.4)
				t.debuffs=t.get("debuffs",[]).filter(func(d):return d.get("kind","")!="poison")
		13:
			if high:
				var factor:float=2.55 if float(m.battle.enemy.hp)/float(m.battle.enemy.max_hp)<=.30 else 1.7
				for n in 2:hit(m,f,atk*factor)
			else:hit(m,f,atk*2.3,.2)
		14:
			effect(m,"mirror" if high else "parry",f,front,5 if high else 4,defense*(1.5 if high else 2.5),{"counter":atk+defense*1.5})
	record_cast(m,f)
	return true

static func record_cast(m,f:Dictionary)->void:
	f.skill_count+=1
	m.battle.skill_casts.append({"uid":int(f.uid),"id":int(f.id),"star":int(f.star),"time":float(m.battle.skill_time)})
	if m.battle.skill_casts.size()>120:m.battle.skill_casts.pop_front()

static func before_hurt(m,t:Dictionary,amount:int,special:bool=false)->int:
	var reduction:float=0;var reflected:float=0;var reflector:Dictionary={}
	for e in m.battle.skill_effects.duplicate():
		if float(e.until)<=float(m.battle.skill_time):continue
		var f:Dictionary=source(m,int(e.source))
		if f.is_empty():continue
		if special and e.kind=="seal":
			amount-=roundi(minf(float(amount)*.30,float(e.value)));m.battle.skill_effects.erase(e)
		if int(e.target)!=int(t.uid):continue
		match str(e.kind):
			"veil":reduction+=minf(float(amount)*float(e.cap),float(e.value))
			"mirror":
				reflected=minf(float(amount)*.35,float(e.value));reduction+=reflected;reflected*=float(e.get("reflect_ratio",1.0));reflector=f
			"parry":
				reduction+=minf(float(amount)*.50,float(e.value));hit(m,f,float(e.counter));m.battle.skill_effects.erase(e)
			"thorns":effect(m,"poison",f,{},float(e.get("poison_duration",4)),float(e.value))
	var blocked:int=mini(floori(amount*.60),roundi(reduction))
	if not reflector.is_empty():hit(m,reflector,minf(float(blocked),reflected),0,true)
	return maxi(0,amount-blocked)

static func normal_bonus(m,f:Dictionary)->int:
	if float(m.battle.skill_time)<float(f.imbue_ready):return 0
	var strongest:float=0
	for e in m.battle.skill_effects:
		if e.kind=="imbue" and float(e.until)>float(m.battle.skill_time):strongest=maxf(strongest,float(e.value))
	if strongest>0:f.imbue_ready=float(m.battle.skill_time)+1.0
	return roundi(strongest*100.0/(100.0+enemy_stat(m,"defense")))

static func end_check(m)->bool:
	if int(m.battle.enemy.hp)<=0:
		m.battle.phase="death";m.battle.phase_time=0.0;m.battle.cleared+=1;m.battle.reward+=int(m.battle.round)*2;return true
	return false

static func advance(m,dt:float)->void:
	m.battle.skill_accumulator+=dt
	while float(m.battle.skill_accumulator)>=.1-0.000001 and m.battle.phase=="fight":
		m.battle.skill_accumulator=maxf(0,float(m.battle.skill_accumulator)-.1)
		var now:float=float(m.battle.skill_time)
		for f in living(m):
			if int(f.get("star",1))>=1 and now+.00001>=float(f.skill_ready):
				if cast(m,f):f.skill_ready=now+float(CDS[int(f.star)-1][int(f.id)])
			if end_check(m):return
		m.battle.skill_time=now+.1
		for f in m.battle.fighters:
			sync_shield(f)
			for layer in f.skill_layers.duplicate():
				if float(layer.left)<=0 or float(layer.until)<=float(m.battle.skill_time)+.00001 or int(f.hp)<=0:
					if float(layer.burst)>0:hit(m,source(m,int(layer.source)),float(layer.burst))
					f.skill_layers.erase(layer)
			rebuild_shield(f)
		for e in m.battle.skill_effects.duplicate():
			if e.kind in ["poison","fog","regen","herb_hot"] and float(e.next)<=float(m.battle.skill_time)+.00001 and float(e.next)<=float(e.until)+.00001:
				var f:Dictionary=source(m,int(e.source));var t:Dictionary=source(m,int(e.target))
				if e.kind in ["poison","fog"]:hit(m,f,float(e.value))
				elif not t.is_empty():heal(m,f,t,float(e.value),true)
				e.next+=1.0
			if float(e.until)<=float(m.battle.skill_time)+.00001:m.battle.skill_effects.erase(e)
		if end_check(m):return
		# Stun delays the enemy's next attack by its exact duration; allies keep attacking.
		m.battle.normal_time+=.1
		m.battle.clock=fmod(float(m.battle.normal_time),m.TICK)
		m.battle.enemy_delay=float(m.battle.get("enemy_delay",0))+minf(.1,float(m.battle.stun_left))
		m.battle.stun_left=maxf(0,float(m.battle.stun_left)-.1)
		if float(m.battle.normal_time)>=m.TICK-.00001:
			m.battle.normal_time-=m.TICK;m.tick_utility()
		if m.battle.phase!="fight":return
		if float(m.battle.skill_time)+.00001>=float(m.battle.enemy_ready)+float(m.battle.enemy_delay):
			enemy_attack(m);m.battle.enemy_ready+=m.TICK
			if m.battle.phase!="fight":return
			if end_check(m):return

static func enemy_attack(m)->void:
	var a:Array=living(m)
	if a.is_empty():return
	var front:Dictionary=a[0]
	var enemy_atk:float=enemy_stat(m,"atk")
	if a.any(func(v):return m.skill(v)=="weaken"):enemy_atk=maxf(float(m.battle.enemy.atk)*.7,enemy_atk*.8)
	var incoming:int=m.damage(enemy_atk,float(front.def))
	incoming=before_hurt(m,front,incoming)
	m.battle.fx.hit_uid=int(front.uid);m.battle.fx.enemy_hit=true
	m.utility_hurt(front,incoming);front.hits+=1
	# Preserve tier1 front-line passives in mixed teams.
	if m.skill(front)=="thorns":m.battle.enemy.poison=mini(18,int(m.battle.enemy.poison)+3)
	var retaliation:int=0
	if m.skill(front)=="reflect":retaliation+=roundi(incoming*.25)
	if m.skill(front)=="counter" and int(front.hits)%3==0:retaliation+=m.damage(float(front.atk)*1.5,float(m.battle.enemy.defense))
	m.battle.enemy.hp=maxi(0,int(m.battle.enemy.hp)-retaliation)
	if m.skill(front)=="mend" and int(front.hp)>0:front.hp=mini(int(front.max_hp),int(front.hp)+roundi(incoming*.15))
	if int(front.hp)<=0:m.battle.fx.death_uid=int(front.uid)
	if living(m).is_empty():m.battle.phase="defeat";m.battle.phase_time=0.0

static func cast_basic(m,f:Dictionary,front:Dictionary,t:Dictionary)->bool:
	var atk:float=float(f.atk);var hp:float=float(f.max_hp);var defense:float=float(f.def)
	if int(f.id) in [6,7] and int(t.hp)==int(t.max_hp):return false
	if int(f.id)==8 and int(front.hp)==int(front.max_hp):return false
	match int(f.id):
		0:hit(m,f,atk);heal(m,f,f,hp*.03)
		1:hit(m,f,atk*1.5)
		2:effect(m,"thorns",f,front,4,atk*.08,{"poison_duration":3.0})
		3:shield(m,f,front,hp*.08,4)
		4:effect(m,"imbue",f,{},3,atk*.20)
		5:
			for n in 2:hit(m,f,atk*.60)
		6:effect(m,"regen",f,t,4,hp*.015)
		7:heal(m,f,t,atk*1.2)
		8:heal(m,f,front,hp*.08)
		9:hit(m,f,atk*.8);effect(m,"reduce_atk",f,{},4,atk*.08)
		10:hit(m,f,atk*1.5,.25)
		11:effect(m,"parry",f,front,4,defense*1.5,{"counter":atk*.6+defense})
		12:shield(m,f,front,atk*1.2,4)
		13:effect(m,"poison",f,{},4,atk*.15)
		14:effect(m,"mirror",f,front,3,defense*.8,{"reflect_ratio":.5})
	return true
