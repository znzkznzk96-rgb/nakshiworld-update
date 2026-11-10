extends RefCounted
# Presentation only. This reads combat state, never advances combat or uses RNG.
const HOLD:=0.70
const PREPARE:=0.15
const COLORS=[Color("65dcff"),Color("ffe269"),Color("cb9aff"),Color("b8f29a"),Color("ff9de1")]
var icons:Dictionary={}

func clock(model)->float:
	var b:Dictionary=model.battle
	var tail:float=float(b.get("phase_time",0)) if str(b.get("phase","")) in ["death","defeat"] else 0.0
	return float(b.get("skill_time",0))+float(b.get("skill_accumulator",0))+tail

func color_for(model,id:int)->Color:
	var elements:Array=model.catalog.soldiers[id].get("elements",[0])
	return COLORS[clampi(int(elements[0]),0,4)]

func eligible(model,f:Dictionary)->bool:
	if int(f.get("star",0))<1 or int(f.get("hp",0))<=0 or int(model.battle.enemy.hp)<=0:return false
	var alive:Array=model.battle.fighters.filter(func(v):return int(v.hp)>0)
	if alive.is_empty():return false
	var full:bool=alive.all(func(v):return int(v.hp)==int(v.max_hp))
	var id:int=int(f.id)
	if int(f.star)==1:
		if id in [6,7] and full:return false
		if id==8 and int(alive[0].hp)==int(alive[0].max_hp):return false
	elif id in [6,7,12] and full:
		var bad:bool=alive.any(func(v):return not v.get("debuffs",[]).is_empty())
		if not bad or id==6:return false
	return true

func cue(model,f:Dictionary)->Dictionary:
	var b:Dictionary=model.battle
	if not model.TIER_SKILLS.enabled(model) or int(f.get("hp",0))<=0:return {}
	if str(b.get("phase","")) not in ["fight","death"]:return {}
	var uid:int=int(f.uid);var latest:float=-100.0
	for event in b.get("skill_casts",[]):
		if int(event.uid)==uid:latest=maxf(latest,float(event.time))
	for event in b.get("skill_popups",b.get("fx",{}).get("attacks",[])):
		if event.has("skill_at") and int(event.source)==uid:latest=maxf(latest,float(event.skill_at))
	# A cast is executed at the beginning of a .1-second simulation step.
	var age:float=maxf(0,clock(model)-latest-.1)
	if latest>=0 and age<HOLD:return {"kind":"cast","age":age,"color":color_for(model,int(f.id))}
	if str(b.phase)!="fight" or not eligible(model,f):return {}
	var left:float=maxf(0,float(f.get("skill_ready",0))-float(b.skill_time))+maxf(0,.1-float(b.get("skill_accumulator",0)))
	if left<=PREPARE:return {"kind":"prepare","age":0.0,"color":color_for(model,int(f.id)),"progress":1.0-left/PREPARE}
	return {}

func texture(id:int,star:int)->Texture2D:
	var key:String="%d_%02d"%[clampi(star,1,3),id]
	if not icons.has(key):icons[key]=load("res://art/ui/soldier_skills/tiered/t%s.tres"%key)
	return icons[key]

func badge(m,id:int,star:int,rect:Rect2,color:Color,alpha:float=1.0)->void:
	m._ui_rect(rect.grow(1),Color(color,alpha))
	m._ui_rect(rect,Color(.055,.08,.13,alpha))
	m._ui_texture_rect(texture(id,star),rect.grow(-1),false,Color(1,1,1,alpha))

func draw_caster(m,model,f:Dictionary,center:Vector2,size:float,data:Dictionary)->void:
	if data.is_empty():return
	var alpha:float=1.0
	if data.kind=="cast":alpha=1.0-smoothstep(.5,HOLD,float(data.age))
	var rect:Rect2=Rect2((center-Vector2.ONE*size*.5).round(),Vector2.ONE*size)
	badge(m,int(f.id),int(f.get("star",1)),rect,data.color,alpha)
	if data.kind=="prepare":
		m._ui_rect(Rect2(rect.position+Vector2(1,size-2),Vector2((size-2)*float(data.progress),1)),data.color)
	elif float(data.age)<.18:
		var a:float=(1.0-float(data.age)/.18)*.9
		for v in [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1)]:
			m._ui_rect(Rect2((center+v*(size*.5+3)).round(),Vector2(1,1)),Color(1,1,1,a))

func damage_events(b:Dictionary)->Array:
	var events:Array=b.get("fx",{}).get("attacks",[])
	if not b.has("skill_popups"):return skill_events(events)
	var mixed:Array=events.filter(func(v):return not v.has("skill_at"))
	mixed.append_array(b.skill_popups)
	return skill_events(mixed)

func skill_events(events:Array)->Array:
	var result:Array=[];var indices:Dictionary={}
	for event in events:
		if not event.has("skill_at"):result.append(event);continue
		var key:String="%d:%.4f"%[int(event.source),float(event.skill_at)]
		if indices.has(key):result[indices[key]].amount+=int(event.amount)
		else:indices[key]=result.size();result.append(event.duplicate(true))
	return result

# Pure screen layout: expired labels cannot reserve slots or move active ones.
func damage_layout(model,room:Rect2,enemy_center:float)->Array:
	var normal:Array=[];var skills:Array=[]
	var b:Dictionary=model.battle
	for event in damage_events(b):
		var slot:int=-1
		for i in b.fighters.size():
			if int(b.fighters[i].uid)==int(event.source):slot=i;break
		if slot<0 or int(event.amount)<=0:continue
		var skill:bool=event.has("skill_at")
		var age:float=maxf(0,clock(model)-float(event.skill_at)-.1) if skill else float(b.get("fx",{}).get("age",99))-slot*.10
		if age<0 or age>.75:continue
		var item:Dictionary={"event":event,"age":age,"skill":skill}
		if skill:skills.append(item)
		else:normal.append(item)
	skills.sort_custom(func(a,b):return a.age<b.age)
	normal.sort_custom(func(a,b):return a.age<b.age)
	var selected:Array=skills.slice(0,2 if not normal.is_empty() else 3)
	selected.append_array(normal.slice(0,3-selected.size()))
	var used:Array=[];var rows:Dictionary={false:0,true:0}
	for item in selected:
		var width:float=56 if item.skill else 44
		var x:float=minf(enemy_center-34,room.end.x-104) if item.skill else room.end.x-width-3
		x=clampf(x,room.position.x+3,room.end.x-width-3)
		var row:int=rows[item.skill];rows[item.skill]+=1
		var rect:Rect2=Rect2(x,room.position.y+1+row*16,width,14)
		# Include the complete upward drift and outline in the reserved rectangle.
		rect.position.y=clampf(rect.position.y,room.position.y+1,room.end.y-15)
		for other in used:
			if rect.grow(1).intersects(other):rect.position.y=other.end.y+2
		rect.position.y=minf(rect.position.y,room.end.y-15)
		item["rect"]=rect;used.append(rect);item["at"]=rect.position+Vector2(34 if item.skill else 25,11)
	return selected
