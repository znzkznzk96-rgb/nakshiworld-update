extends RefCounted
# Approved B rig, native draw transforms. Rendering only; no save or battle mutations.
const ROOT_PATH = "res://art/angler_b/"
const CAST = [[0,98,94,-43,0],[.22,101,72,-90,10],[.50,79,47,-160,1],[.59,79,47,-160,0],[.69,100,66,-80,-25],[.76,103,88,-35,-30],[.83,101,96,-31,13],[.91,97,94,-46,-6],[1,98,94,-43,0]]
const BODY = [[0,0],[.22,-3],[.5,-7],[.59,-7],[.76,8],[.84,5],[.93,-1],[1,0]]
const SKINS = [["54431c","b88a22","f5dc58","f0bb26","77502c"],["252c32","374f56","87b3b4","88504e","56343b"],["525d61","d3dfd8","fff8e4","c47456","864e3d"],["213c4a","426a7a","8fbcc3","d6a74e","71502e"],["112622","184e3e","349977","65c7a3","614826"],["2c2047","8056a9","dba7ec","7bd8cb","4b355e"]]
var textures: Dictionary = {}
var cats: Dictionary = {"idle":[],"look":[],"hop":[]}
var root := Transform2D.IDENTITY
var upper := Transform2D.IDENTITY
var tint := Color.WHITE
var tip := Vector2.ZERO
var crank := 0.0
var last_clock := -1.0
var debug := {}

func setup() -> void:
	for n in ["lower","torso","upper","fore","hand","face-neutral","face-blink","face-focus","face-brace","face-cast","face-strain","face-surprise","face-joy","face-smile","face-sad"]:
		textures[n] = load_png_data(n)
	var atlas: Texture2D=load_png_data("cat-atlas")
	var n: int=0
	for kind in ["idle","look","hop"]:
		for i in (48 if kind=="idle" else 12):
			var frame:=AtlasTexture.new();frame.atlas=atlas;frame.region=Rect2((n%8)*256,floori(n/8.0)*256,256,256);frame.filter_clip=true;cats[kind].append(frame);n+=1

func load_png_data(n: String) -> Texture2D:
	var encoded: String=FileAccess.get_file_as_string(ROOT_PATH+n+".png.b64.txt")
	var image:=Image.new()
	var error: Error=image.load_png_from_buffer(Marshalls.base64_to_raw(encoded))
	assert(error==OK,"Approved PNG data: "+n)
	return ImageTexture.create_from_image(image)

func offset_xf(p: Vector2) -> Transform2D: return Transform2D(0,p)
func scale_xy(x: float,y: float) -> Transform2D: return Transform2D(Vector2(x,0),Vector2(0,y),Vector2.ZERO)
func sm(x: float) -> float:
	x=clampf(x,0,1);return x*x*(3-2*x)
func tex(m,n: String,xf: Transform2D) -> void:
	m.draw_set_transform_matrix(root*xf);m.draw_texture(textures[n],Vector2.ZERO,tint)
func segment(m,n: String,sa: Vector2,sb: Vector2,a: Vector2,b: Vector2,xf: Transform2D) -> void:
	var d: Vector2=b-a
	tex(m,n,xf*offset_xf(a)*Transform2D(d.angle(),Vector2.ZERO)*scale_xy(d.length()/sa.distance_to(sb),1)*Transform2D(-(sb-sa).angle(),Vector2.ZERO)*offset_xf(-sa))
func solve(s: Vector2,g: Vector2,hand_angle: float,l1: float,l2: float) -> Dictionary:
	var w: Vector2=g-Vector2.from_angle(hand_angle)*6
	var d: Vector2=w-s
	var length: float=d.length()
	var safe: float=clampf(length,absf(l1-l2)+.001,l1+l2-.001)
	var a: float=d.angle()+acos(clampf((l1*l1+safe*safe-l2*l2)/(2*l1*safe),-1,1))
	return {"s":s,"e":s+Vector2.from_angle(a)*l1,"w":w,"g":g,"a":hand_angle,"error":absf(length-safe)}
func arm(m,p: Dictionary,xf: Transform2D) -> void:
	segment(m,"upper",Vector2(66,81),Vector2(75,92),p.s,p.e,xf)
	segment(m,"fore",Vector2(76,94),Vector2(92,94),p.e,p.w,xf)
	tex(m,"hand",xf*offset_xf(p.g)*Transform2D(p.a,Vector2.ZERO)*offset_xf(Vector2(-98,-94)))
func rod_point(origin: Vector2,angle: float,bend: float,s: float) -> Vector2:
	var p: Vector2=origin
	var remaining: float=clampf(s,0,1)
	for j in 40:
		if remaining<=.0000001: break
		var ds: float=minf(.025,remaining)
		var u: float=clampf((j*.025+ds*.5-.16)/.84,0,1)
		p+=Vector2.from_angle(deg_to_rad(angle+bend*u*u))*98*ds;remaining-=ds
	return p
func chair(m) -> void:
	m.draw_set_transform(Vector2(m.PX-50,m.SURF-285+m.oy))
	var rects: Array=[[135,551,5,17,"4c392c"],[136,552,2,15,"aa7a47"],[157,551,5,17,"4c392c"],[158,552,2,15,"aa7a47"],[138,560,21,3,"6c4b2f"],[139,560,19,1,"b58a50"],[131,548,35,5,"4b3527"],[132,547,33,3,"bc8f52"],[133,547,31,1,"d9b577"]]
	# Positions use approved 540px review coordinates, projected to the 270px game.
	for r in rects: m.draw_rect(Rect2(float(r[0])*.5,float(r[1])*.5,float(r[2])*.5,float(r[3])*.5),Color(r[4])*tint)
	m.draw_set_transform(Vector2(0,m.oy))
func cat(m,kind: String,local: float) -> void:
	var action: String="idle"
	var frame: int=int(fposmod(m.cat_t,3.6)/3.6*48)%48
	var air: float=0.0
	if kind=="cast": action="look";frame=clampi(int(clampf((local-.85),0,1)*12),0,11)
	if kind=="success":
		action="hop";frame=clampi(int(clampf(local/1.1,0,1)*12),0,11)
		air=sin(clampf((local-.2)/.65,0,1)*PI) if local<.85 else 0.0
	var image: Texture2D=cats[action][frame]
	var p: Vector2=Vector2(m.CATX-.5,m.SURF-36.0*247/256.0)
	var size: Vector2=Vector2(36,36)
	m.draw_set_transform(Vector2(0,m.oy))
	var shadow_width: float=lerpf(17,10,air)
	m.draw_rect(Rect2(p.x+20-shadow_width*.5,m.SURF,shadow_width,1),Color(.11,.13,.1,lerpf(.25,.09,air)))
	for off in [Vector2(-.4,0),Vector2(.4,0),Vector2(0,-.35),Vector2(0,.5)]:
		var c:=Color("674a35");c.a=.55 if off.y<0 else .88
		m.draw_texture_rect(image,Rect2(p+off,size),false,c*tint)
	m.draw_texture_rect(image,Rect2(p,size),false,tint)
	debug.cat_action=action;debug.cat_frame=frame;debug.cat_air=air
func draw(m) -> Vector2:
	if textures.is_empty(): setup()
	tint=m.environment.actor_tint() if m.active_region==0 else Color.WHITE
	var phase: String=m.S.phase
	var local: float=float(m.S.get("t",0.0))
	var kind: String="idle"
	var tension: float=0.0
	var held: bool=false
	if phase=="cast": kind="cast";local=local/1.45*1.9
	elif phase=="fight": kind="fight";local=m.fclock;held=m.holding;tension=clampf(float(m.S.tension)/100,0,1)
	elif phase=="pre": kind="capture"
	elif phase=="catch":
		if local<float(m.S.netEnd):kind="capture";local=local/float(m.S.netEnd)*1.8
		else:kind="success";local-=float(m.S.netEnd)
	elif phase=="fail": kind="failure"
	elif phase=="result":kind="success" if m.S.get("ok",false) else "failure";local=m.result_t+1.2
	else:local=m.clock
	var dt: float=0.0 if last_clock<0 else clampf(m.clock-last_clock,0,.1)
	last_clock=m.clock
	if kind=="fight" and held:crank+=dt*11
	root=Transform2D(Vector2(.5,0),Vector2(0,.5),Vector2(m.PX-33,m.SURF-93+m.oy))
	chair(m)
	# Celebrate during the visible end of the lift, before the existing measurement overlay.
	if phase=="catch" and float(m.S.t)>=float(m.S.netEnd)-1.1 and float(m.S.t)<float(m.S.netEnd):
		cat(m,"success",float(m.S.t)-float(m.S.netEnd)+1.1)
	else:cat(m,kind,local)
	var strength: float=.25 if kind=="cast" else (.8 if kind=="fight" else 1.0)
	var breath: float=(.5+.5*sin(m.clock*TAU/3.2))*strength
	var head_y: float=-.6*(.5+.5*sin(m.clock*TAU/3.2-.22))*strength
	var pull: float=tension if kind in ["fight","capture"] else 0.0
	var shift: float=-roundf(pull*2)
	var near:=Vector2(98-pull*4,94-pull*2)
	var angle: float=-43-pull*9
	var bend: float=0.0
	var body_angle: float=0.0
	var body_y: float=0.0
	if kind=="cast":
		var u: float=clampf(local/1.9,0,1);var i: int=0
		while i<CAST.size()-2 and u>float(CAST[i+1][0]):i+=1
		var a: Array=CAST[i];var b: Array=CAST[i+1];var v: float=sm((u-float(a[0]))/(float(b[0])-float(a[0])))
		near=Vector2(float(a[1]),float(a[2])).lerp(Vector2(float(b[1]),float(b[2])),v);angle=lerpf(a[3],b[3],v);bend=lerpf(a[4],b[4],v)
		i=0
		while i<BODY.size()-2 and u>float(BODY[i+1][0]):i+=1
		body_angle=lerpf(BODY[i][1],BODY[i+1][1],sm((u-float(BODY[i][0]))/(float(BODY[i+1][0])-float(BODY[i][0]))))
	elif kind=="fight":
		bend=lerpf(7,44,tension);body_angle=(-3+tension*4 if held else -6+tension*8)+sin(local*3.1)*(.7+1.8*tension);body_y=sin(local*3.1)*.4*tension
	elif kind=="capture":angle-=sm(local/1.8)*10;near.y-=sm(local/1.8)*2;bend=5
	elif kind=="success":body_angle=-2*sin(PI*clampf(local/1.2,0,1))
	elif kind=="failure":body_angle=6*sm(local/.5)*(1-sm((local-1.05)/.65));body_y=1.1*sm(local/.5)*(1-sm((local-1.05)/.65))
	var direction: Vector2=Vector2.from_angle(deg_to_rad(angle))
	var far: Vector2=near+direction*12
	var reel_center: Vector2=near+Vector2(-2,5)
	var reel_hand: Vector2=reel_center+Vector2(cos(crank),sin(crank))*3.3
	var grip: Vector2=reel_hand if kind=="fight" and held else near+Vector2(0,4) if kind=="fight" else near
	var hand_angle: float=deg_to_rad(angle+43) if kind=="cast" else 0.0
	var front: Dictionary=solve(Vector2(66,80),grip,hand_angle,17,19)
	var rear: Dictionary=solve(Vector2(78,80),far,hand_angle,16,19)
	upper=offset_xf(Vector2(123,151+body_y))*Transform2D(deg_to_rad(body_angle),Vector2.ZERO)*offset_xf(Vector2(-123,-151))
	var arm_xf: Transform2D=upper*offset_xf(Vector2(48+shift,48-.8*breath))
	tex(m,"lower",offset_xf(Vector2(48,48)));arm(m,rear,arm_xf)
	tex(m,"torso",upper*offset_xf(Vector2(123+shift,148))*scale_xy(1+.006*breath,1+.035*breath)*offset_xf(Vector2(-75,-100)))
	var face: String="neutral"
	if kind=="cast":face="cast" if local/1.9>.34 and local/1.9<.79 else "focus"
	elif kind=="fight":face="strain" if tension>.77 else "focus" if held else "brace"
	elif kind=="success":face="joy" if local<.45 else "smile"
	elif kind=="failure":face="sad"
	elif kind=="capture":face="surprise"
	elif fposmod(local,3.4)>3.16:face="blink"
	tex(m,"face-"+face,upper*offset_xf(Vector2(48+shift,48+head_y)))
	var rod_xf: Transform2D=root*arm_xf
	m.draw_set_transform_matrix(rod_xf)
	var skin: Array=SKINS[clampi(m.rod_lv,0,5)]
	if m.equipment.rod_equipped:
		for style in [[skin[0],3.6],[skin[1],2.0],[skin[2],.8]]:
			var pts:=PackedVector2Array([near-direction*12])
			for j in 41:pts.append(rod_point(near,angle,bend,j/40.0))
			m.draw_polyline(pts,Color(style[0])*tint,float(style[1]),false)
		for j in 5:
			var pp: Vector2=rod_point(near,angle,bend,.18+j*.17)
			m.draw_circle(pp,1.8,Color(skin[3])*tint)
		m.draw_line(near-direction*13,near-direction*2,Color(skin[4])*tint,4,false)
		if kind!="cast":m.draw_rect(Rect2(reel_center-Vector2(4,3),Vector2(8,7)),Color(skin[0])*tint);m.draw_line(reel_center,reel_hand,Color(skin[2])*tint,1,false)
	arm(m,front,arm_xf)
	tip=rod_xf*rod_point(near,angle,bend,1)
	m.draw_set_transform(Vector2(0,m.oy))
	debug.merge({"kind":kind,"expression":face,"front_error":front.error,"rear_error":rear.error,"tip":tip,"rod":m.rod_lv,"held":held},true)
	return tip-Vector2(0,m.oy)
func landing_pose(elapsed: float,end: float,rod_tip: Vector2,water: float) -> Dictionary:
	var u: float=sm(elapsed/end)
	var mouth: Vector2=Vector2(104,water+9).lerp(rod_tip+Vector2(2,15),u)
	# Pendulum about the mouth; limited to 17 degrees so the head always stays up.
	var angle: float=-PI*.5+sin(elapsed*8.0)*(.12+.17*u)
	return {"mouth":mouth,"angle":angle}

func landing(m,t: float,rod_tip: Vector2) -> void:
	if float(m.S.t)>=float(m.S.netEnd):return
	var elapsed: float=float(m.S.t)
	var geometry: Dictionary=landing_pose(elapsed,float(m.S.netEnd),rod_tip,m.WATER)
	var lf: Dictionary=m.S.get("lastF",{})
	var scale: float=float(lf.get("scale",.65))
	var pose: Dictionary=m.pose_for("swim",m.S.star,0).duplicate()
	pose.tilt=geometry.angle;pose.amp=.023;pose.curl=0;pose.tailAmp=.8
	m._shadow_fish(geometry.mouth,m.S.star,m.S.grade,t,"hanging",false,scale,pose,elapsed*TAU*1.8,m.S.sp,1.0,1.0)
	m._line(rod_tip,m.fish_mouth,Color(1,1,1,.8))
	var length: float=m._fish_display_length(m.S.star,scale,false,m.S.sp)
	# Detached drops use the tail's earlier emission position plus gravity.
	for i in 7:
		var age: float=fposmod(elapsed+i*.097,.68)
		if age>elapsed:continue
		var past: Dictionary=landing_pose(elapsed-age,float(m.S.netEnd),rod_tip,m.WATER)
		var tail: Vector2=past.mouth-Vector2.from_angle(past.angle)*length
		var drop: Vector2=tail+Vector2(sin(i*2.1)*age*7,14*age+94*age*age)
		if drop.y>=m.WATER:continue
		var color:=Color(.72,.91,1,(1-age/.68)*.88)
		m.draw_line(drop-Vector2(0,1+age*3),drop,color,1,false)
	debug.landing_mouth=m.fish_mouth;debug.landing_tail=m.aura.pts[-1]
