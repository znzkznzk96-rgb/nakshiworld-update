extends RefCounted
# Presentation only. Existing pre/fight timing and hook judgement are untouched.
const COLORS = [Color.WHITE,Color("9beaff"),Color("c4a0ff"),Color("ffd46d"),Color("ffa2db"),Color("ffb175")]
const TITLES = ["","레어 발견!","유니크 출현!","전설 출현!","신화 출현!","경고 · 주인 등장"]
const WARNINGS = ["","","특별한 기척","강력한 기척","심상치 않은 존재","거대한 기척이 다가온다"]
var debug := {}
func descriptor(grade: int,owner: bool=false) -> Dictionary:
	var level: int=5 if owner else clampi(grade,0,4)
	return {"level":level,"title":TITLES[level],"color":COLORS[level],"duration":3.0 if owner else 1.8,"size":20 if level>=2 else 15,"sparkle":level,"warning":WARNINGS[level]}
func motion(age: float,index: int,level: int,duration: float) -> Dictionary:
	var enter: float=clampf((age-index*.025)/.20,0,1)
	var leave: float=smoothstep(duration-.3,duration,age)
	var shake: float=sin(age*34+index*.6)*maxf(0,1-age/.28)*maxi(0,level-2)*.7
	return {"alpha":enter*(1-leave),"offset":Vector2(shake,10*pow(1-enter,3)-8*leave+sin(age*5-index*.4)*maxi(0,level-1)*.35)}
func title(m,d: Dictionary,age: float,y: float) -> void:
	var value: String=d.title
	var total: float=m._text_w(value,d.size)
	var x: float=135-total*.5
	for i in value.length():
		var glyph: String=value.substr(i,1)
		var width: float=m._text_w(glyph,d.size)
		var step: Dictionary=motion(age,i,d.level,d.duration)
		var shimmer: float=pow(maxf(0,sin(age*4-i*.68)),6)*(.12+float(d.level)*.055)
		var color: Color=(d.color as Color).lerp(Color.WHITE,shimmer)
		color.a=step.alpha
		if d.level>=3:
			var halo: Color=Color(color,color.a*(.08+shimmer*.5))
			for offset in [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1)]:
				m._text(glyph,Vector2(x,y)+step.offset+offset,d.size,halo,false,width+3,false)
		m._text(glyph,Vector2(x,y)+step.offset,d.size,color,false,width+3,true)
		x+=width
	debug={"title":value,"level":d.level,"age":age,"text_only":true,"bounds":Rect2(135-total*.5,y-22,total,30)}
func draw(m) -> void:
	if m.scene!="fish" or m.title_open or m.lesson_open or m.S.get("owner",false):return
	if m.S.phase not in ["pre","fight"] or m.S.get("judge","MISS")=="MISS":return
	var d: Dictionary=descriptor(int(m.S.get("grade",0)))
	var age: float=m.clock-float(m.S.get("encounter_at",m.clock- float(m.S.get("t",0))))
	if d.level==0 or age>=d.duration:return
	var y: float=clampf(m.top_y+166,m.top_y+135,m.get_viewport_rect().size.y-160)
	title(m,d,age,y)
	if d.level>=2:
		var a: float=smoothstep(.16,.36,age)*(1-smoothstep(d.duration-.3,d.duration,age))
		m._text(d.warning,Vector2(135,y+19),10,Color(d.color,a*.9),true,238,true)
func draw_owner(m,name: String) -> void:
	var d: Dictionary=descriptor(0,true)
	var age: float=float(m.S.get("t",0))
	var y: float=m.top_y+165
	title(m,d,age,y)
	var a: float=smoothstep(.15,.4,age)*(1-smoothstep(2.7,3.0,age))
	m._text(name,Vector2(135,y+22),15,Color("fff0d1",a),true,236,true)
	m._text(d.warning,Vector2(135,y+40),10,Color("ffbd83",a*.9),true,236,true)
