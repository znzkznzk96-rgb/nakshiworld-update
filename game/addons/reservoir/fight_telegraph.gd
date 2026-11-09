extends RefCounted
# Presentation-only cues except the explicitly approved 0.35 fight-second spike warning.
const CORAL := Color("ff716a")
const LIME := Color("cdff54")
const VIOLET := Color("de9aff")
const BORDER := Color("101522")
const EMPTY := Color("29303d")
const SIZE := 13
const SPIKE_WARNING := 0.35
const PERFECT_WINDOW := 0.25
const WARNINGS := {"tell":"right","turn":"left","nose":"down","rise":"up"}
var behavior := ""
var duration := 1.0
var started := 0.0
var previous_reel := false
var reel_until := -1.0
var reel_used := true
var cancel_until := -1.0
var flash_until := -1.0
var success_count := 0
var icon_bounds := Rect2()
var mask_cache := {}

func reset() -> void:
	behavior="";duration=1;started=0;previous_reel=false;reel_until=-1;reel_used=true;cancel_until=-1;flash_until=-1;icon_bounds=Rect2()

func can_reel(m) -> bool:
	if float(m.S.get("spikeWarn",0))>0 or float(m.S.get("spike",0))>0: return false
	match str(m.S.get("beh","")):
		"swim","rest","charge": return true
		"circle": return sin(float(m.S.get("circA",0)))>0
		"thrash": return sin(float(m.S.get("thT",0))*(9.0+4.0*float(m.S.get("F",0))))<=0.4
		"sulk": return float(m.S.get("holdT",0))<0.45
	return false

func note_behavior(m) -> void:
	var next: String=str(m.S.get("beh",""))
	if next==behavior: return
	var old: String=behavior
	behavior=next;duration=maxf(0.001,float(m.S.get("bt",1)));started=m.clock
	if old=="tell" and next=="swim": cancel_until=m.clock+0.12
	# A chained warning never opens a misleading reeling ring.
	if next in ["swim","rest"] and old not in ["","swim","rest","charge"]:
		reel_until=m.clock+PERFECT_WINDOW;reel_used=false
	if next=="charge": reel_until=-1;reel_used=true
	previous_reel=can_reel(m)

func observe(m) -> void:
	note_behavior(m)
	var now: bool=can_reel(m)
	if now and not previous_reel and str(m.S.get("beh",""))!="charge":
		reel_until=m.clock+PERFECT_WINDOW;reel_used=false
	previous_reel=now

func ring(m) -> Dictionary:
	if not can_reel(m) or str(m.S.get("beh",""))=="charge": return {}
	if float(m.S.get("landUntil",0))>0 and m.clock<=float(m.S.landUntil) and not bool(m.S.get("jumpUsed",false)):
		return {"until":float(m.S.landUntil),"length":0.5,"kind":"landing"}
	if float(m.S.get("skimEnd",0))>0 and m.clock<=float(m.S.skimEnd) and not bool(m.S.get("skimUsed",false)):
		return {"until":float(m.S.skimEnd),"length":0.4,"kind":"skim"}
	if not reel_used and m.clock<=reel_until: return {"until":reel_until,"length":PERFECT_WINDOW,"kind":"resume"}
	return {}

func on_press(m, fresh: bool) -> bool:
	if not fresh or str(m.S.get("phase",""))!="fight": return false
	var window: Dictionary=ring(m)
	if window.is_empty() or reel_used and flash_until>=m.clock: return false
	# Landing/skim retain their existing reward windows; this adds no new reward.
	reel_used=true;reel_until=-1;flash_until=m.clock+0.16;success_count+=1
	m.audio_feedback.sound(m,"record",-19.0,1.3)
	return true

func sample(m) -> Dictionary:
	if str(m.S.get("phase",""))!="fight": return {}
	var b: String=str(m.S.get("beh",""))
	var bt: float=float(m.S.get("bt",0))
	if float(m.S.get("spikeWarn",0))>0:
		return cue("bolt",CORAL,1.0-float(m.S.spikeWarn)/SPIKE_WARNING,"down")
	if float(m.S.get("spike",0))>0: return {}
	if WARNINGS.has(b):
		return cue(WARNINGS[b],LIME if b=="turn" else CORAL,1.0-bt/maxf(duration,0.001),WARNINGS[b])
	if b=="clone":
		# One group mark, never a mark over just the real fish.
		return cue("clones",VIOLET,float(m.S.get("cloneT",0))/0.3,"right") if float(m.S.get("cloneT",0))<0.3 else {}
	if m.clock<cancel_until: return cue("cancel",Color("bec9d5"),1.0-(cancel_until-m.clock)/0.12,"right")
	if b=="sulk": return cue("clamp",LIME if can_reel(m) else CORAL,clampf(float(m.S.get("holdT",0))/0.45,0,1),"down")
	if b=="circle": return cue("cycle",LIME if can_reel(m) else CORAL,fposmod(float(m.S.get("circA",0)),PI)/PI,"radial")
	if b=="thrash":
		var a: float=float(m.S.get("thT",0))*(9.0+4.0*float(m.S.get("F",0)))
		return cue("zigzag",LIME if can_reel(m) else CORAL,(sin(a)+1.0)*0.5,"right")
	if b=="skim": return cue("wave",CORAL,1.0-bt/maxf(duration,0.001),"right")
	var window: Dictionary=ring(m)
	if not window.is_empty(): return cue("ring",LIME,1.0-(float(window.until)-m.clock)/float(window.length),"radial")
	return {}

func cue(shape: String, color: Color, progress: float, direction: String) -> Dictionary:
	return {"shape":shape,"color":color,"progress":clampf(progress,0,1),"direction":direction}

func contains(shape: String, x: int, y: int) -> bool:
	var p:=Vector2(x,y)
	var center:=Vector2(6,6)
	match shape:
		"left": return contains("right",12-x,y)
		"up": return contains("right",12-y,x)
		"down": return contains("right",y,12-x)
		"right": return (x>=1 and x<=6 and y>=4 and y<=8) or (x>=6 and x<=11 and absi(y-6)<=11-x)
		"wave": return (y<9 and contains("right",x,y+2)) or (y>=10 and y<=11 and x>=1 and x<=11 and (x+y)%4<2)
		"bolt": return Geometry2D.is_point_in_polygon(p,PackedVector2Array([Vector2(5,0),Vector2(10,0),Vector2(7,5),Vector2(11,5),Vector2(3,12),Vector2(5,7),Vector2(1,7)]))
		"ring": return p.distance_to(center)>=3.5 and p.distance_to(center)<=5.7
		"cycle": return (p.distance_to(center)>=3.6 and p.distance_to(center)<=5.6 and not (y in [5,6,7])) or (x>=9 and y>=4 and y<=7 and x+y<=16) or (x<=3 and y>=5 and y<=8 and x+y>=8)
		"clamp": return x>=1 and x<=11 and (y in [2,3,9,10] or (y in [4,8] and x%3!=0))
		"zigzag":
			for i in 3:
				var a:=Vector2(i*4,7);var b:=Vector2(i*4+2,3);var c:=Vector2(i*4+4,7)
				if Geometry2D.get_closest_point_to_segment(p,a,b).distance_to(p)<=1.4 or Geometry2D.get_closest_point_to_segment(p,b,c).distance_to(p)<=1.4: return true
		"clones":
			for i in 3:
				var yy:int=y-i*4
				var xx:int=x-(2 if i==1 else 0)
				if yy in [0,2] and (xx>=3 and xx<=7 or xx==10): return true
				if yy==1 and xx>=2 and xx<=10: return true
	return false

func mask(shape: String) -> Array:
	if mask_cache.has(shape): return mask_cache[shape]
	var points:Array=[]
	for y in SIZE:
		for x in SIZE:
			if contains(shape,x,y): points.append(Vector2i(x,y))
	mask_cache[shape]=points
	return points

func filled(p: Vector2i, progress: float, direction: String) -> bool:
	if progress<=0: return false
	if progress>=1: return true
	match direction:
		"left": return float(12-p.x)/12.0<=progress
		"up": return float(12-p.y)/12.0<=progress
		"down": return float(p.y)/12.0<=progress
		"radial": return fposmod(atan2(p.y-6,p.x-6)+PI*0.5,TAU)/TAU<=progress
	return float(p.x)/12.0<=progress

func paint(m, data: Dictionary, origin: Vector2) -> void:
	if data.is_empty(): return
	var shape: String=data.shape
	if shape=="cancel":
		for p in [Vector2(1,1),Vector2(10,2),Vector2(2,10),Vector2(10,10)]:
			m._fish_effect_rect(Rect2(origin+p,Vector2.ONE),Color(data.color,1.0-float(data.progress)))
		return
	var points:Array=mask(shape)
	var color: Color=data.color
	for p in points:
		var pos:=Vector2(p)
		if shape=="clamp": pos.y+=roundf(float(data.progress)*2)*(1 if pos.y<6 else -1)
		m._fish_effect_rect(Rect2(origin+pos-Vector2.ONE,Vector2(3,3)),BORDER)
	for p in points:
		var at:=Vector2i(p)
		var edge: bool=not contains(shape,at.x-1,at.y) or not contains(shape,at.x+1,at.y) or not contains(shape,at.x,at.y-1) or not contains(shape,at.x,at.y+1)
		var active:bool=filled(at,float(data.progress),data.direction)
		var ink:Color=color
		if shape=="cycle":
			ink=LIME if at.y<6 else CORAL
			active=(at.y<6 if color==LIME else at.y>=6) and filled(at,float(data.progress),"right")
		var c:Color=ink if active else ink.darkened(0.76)
		if edge:
			var outer:bool=shape not in ["ring","cycle"] or Vector2(at).distance_to(Vector2(6,6))>=5.0
			if active:c=ink.lerp(Color.WHITE,0.35)
			elif outer:c=ink.lerp(Color.WHITE,0.12).darkened(0.15)
		var pos:=Vector2(at)
		if shape=="clamp": pos.y+=roundf(float(data.progress)*2)*(1 if pos.y<6 else -1)
		m._fish_effect_rect(Rect2(origin+pos,Vector2.ONE),c)

func draw(m, center: Vector2, body_length: float, group: bool=false) -> void:
	icon_bounds=Rect2()
	var data: Dictionary=sample(m)
	var half_height: float=4 if group else float(m.aura.get("hw",4))
	var head_x: float=center.x if group else float(m.fish_mouth.x)
	var hud:Vector2=m.S.get("tensionHud",m._tension_anchor(center,m._fight_fish_scale(float(m.S.get("lf",1))),body_length))
	var desired_y:float=minf(center.y-half_height-22,hud.y-18)
	if group:desired_y=minf(desired_y,center.y-36*clampf(float(m.S.get("cloneT",0))/.3,0,1)-half_height-22)
	var anchor:=Vector2(clampf(head_x-6,3,m.VW-16),clampf(desired_y,m.top_y+72-m.oy,m.uw_bot-20)).round()
	var hud_rect:=Rect2(hud,Vector2(44,8)).grow(2)
	if hud_rect.intersects(Rect2(anchor-Vector2.ONE,Vector2(15,15))):
		anchor.x=hud_rect.end.x+2 if hud_rect.end.x+17<m.VW else hud_rect.position.x-17
		anchor.x=clampf(anchor.x,2,m.VW-16)
	if not data.is_empty():
		icon_bounds=Rect2(anchor-Vector2.ONE,Vector2(15,15));paint(m,data,anchor)
		if data.shape in ["right","left","up","down","bolt"]:
			# Fixed small procedural pixels: no random calls and no obscuring spray.
			var progress:float=data.progress
			for i in 3:
				var off:float=10+(1.0-progress)*7+i*3
				var pt:Vector2=center+Vector2(-off,-2+i*2)
				if data.shape=="down": pt=center+Vector2(-4+i*4,8+(1-progress)*7)
				elif data.shape=="up": pt=center+Vector2(-4+i*4,-8-(1-progress)*7)
				m._fish_effect_rect(Rect2(pt.round(),Vector2.ONE),Color(data.color,0.7))
	if flash_until>m.clock:
		var point:Vector2=m.fish_mouth.round()
		var alpha:float=clampf((flash_until-m.clock)/0.16,0,1)
		m._fish_effect_rect(Rect2(point-Vector2(4,0),Vector2(9,1)),Color(1,1,1,alpha))
		m._fish_effect_rect(Rect2(point-Vector2(0,4),Vector2(1,9)),Color(1,1,1,alpha))

# Encyclopedia uses a private model but the exact same sample()/paint() as play.
class LessonModel extends RefCounted:
	var S:Dictionary={}
	var clock:float=0
var demo_event := ""
var demo_last:Dictionary={}
func reset_demo() -> void:
	reset();demo_event="";demo_last={}

func lesson_descriptor(key:String, frame:Dictionary) -> Dictionary:
	var model:=LessonModel.new()
	var b:String=frame.beh
	var k:float=frame.k
	model.S={"phase":"fight","beh":"rest" if b=="land" else ("swim" if b=="spike_warn" else b),"bt":1.0-k,"spike":0.25 if b=="spike" else 0.0,"spikeWarn":SPIKE_WARNING*(1.0-k) if b=="spike_warn" else 0.0,"F":0.0,"holdT":0.6*k,"circA":k*TAU,"thT":float(frame.motion_time),"cloneT":minf(.31,k*1.2),"jumpUsed":false,"skimUsed":false}
	duration=1;reel_until=-1;reel_used=true;cancel_until=-1
	var opportunity:bool=false
	if b=="land":
		model.clock=k*.5;model.S.landUntil=.5;opportunity=true
	elif key=="skim" and b=="rest":
		model.clock=k*.4;model.S.skimEnd=.4;opportunity=true
	elif b=="rest" and key in ["rest","tell","dive","spike"]:
		model.clock=k*PERFECT_WINDOW;reel_until=PERFECT_WINDOW;reel_used=false;opportunity=true
	var data:Dictionary=sample(model)
	var offset:float=float(frame.step_duration)*.65
	var age:float=float(frame.step_elapsed)-offset
	var success:bool=opportunity and age>=0
	var flash:float=clampf(1.0-age/.32,0,1) if success else 0.0
	if success:data={}
	return {"cue":data,"flash":flash,"success":success,"event":"%s:%d:%d"%[key,int(frame.loop),int(frame.index)],"behavior":b}

func draw_lesson(m,key:String,frame:Dictionary,origin:Vector2,mouth:Vector2) -> void:
	demo_last=lesson_descriptor(key,frame)
	icon_bounds=Rect2(origin-Vector2.ONE,Vector2(15,15)) if not demo_last.cue.is_empty() else Rect2()
	paint(m,demo_last.cue,origin)
	if float(demo_last.flash)>0:
		var a:float=demo_last.flash
		m._ui_rect(Rect2(mouth.round()-Vector2(4,0),Vector2(9,1)),Color(1,1,1,a))
		m._ui_rect(Rect2(mouth.round()-Vector2(0,4),Vector2(1,9)),Color(1,1,1,a))
		if demo_event!=str(demo_last.event):
			demo_event=demo_last.event;m.audio_feedback.sound(m,"record",-19.0,1.3)
