extends RefCounted
# REVIEW ONLY. Geometry is sampled from the approved native rod curve.
const COLORS = [Color.WHITE,Color("e9f8ff"),Color("59ceff"),Color("b875ff"),Color("ffca43"),Color("ff90e8")]
const WIDTHS = [0,4.5,8.0,15.0,26.0,38.0]
const COUNTS = [0,2,5,10,18,28]
var trail: Array=[]
var previous_time: float=-1
var debug: Dictionary={}
func tier(enhancement: int) -> int:return clampi(enhancement/2,0,5)
func color_at(level: int,u: float,time: float) -> Color:
	return Color.from_hsv(fposmod(u*.72-time*.13,1),.82,1) if level==5 else COLORS[level]
func normal_at(points: PackedVector2Array,index: int) -> Vector2:
	return (points[mini(index+1,points.size()-1)]-points[maxi(index-1,0)]).normalized().orthogonal()
func star(m,p: Vector2,size: float,col: Color) -> void:
	m.draw_rect(Rect2((p-Vector2(size,.65)).round(),Vector2(size*2,1.3)),col)
	m.draw_rect(Rect2((p-Vector2(.65,size)).round(),Vector2(1.3,size*2)),col)
	m.draw_rect(Rect2((p-Vector2(1.1,1.1)).round(),Vector2(2.2,2.2)),Color(1,1,1,col.a))
func back(m,points: PackedVector2Array,xf: Transform2D,enhancement: int,time: float,action: String,held: bool) -> void:
	var level: int=tier(enhancement)
	debug={"tier":level,"motes":COUNTS[level],"width":WIDTHS[level],"line_and_bobber_aura":false}
	if level==0:return
	var energy: float=1.2 if action=="cast" else (1.12 if action=="fight" and held else 1.0)
	if time<previous_time or (previous_time>=0 and time-previous_time>.2):trail.clear()
	# Keep curved world-space snapshots, so cast afterimages do not rotate with the next pose.
	if level>=3 and action in ["cast","fight"]:
		m.draw_set_transform(Vector2.ZERO)
		for k in trail.size():
			var alpha: float=float(k+1)/maxi(1,trail.size())*.12*float(level-2)*energy
			var old: PackedVector2Array=trail[k]
			for j in range(1,old.size(),2):
				m.draw_line(old[j-1],old[j],Color(color_at(level,j/40.0,time),alpha),.65+level*.16,false)
		if time>previous_time:
			var world:=PackedVector2Array()
			for p in points:world.append(xf*p)
			trail.append(world)
			if trail.size()>[0,0,0,3,6,10][level]:trail.pop_front()
	else:trail.clear()
	previous_time=time
	m.draw_set_transform_matrix(xf)
	for layer in 3:
		var width: float=WIDTHS[level]*(1.0-layer*.25)
		var alpha: float=(.035+level*.009)*(1+layer*.18)*energy
		for j in points.size()-1:
			m.draw_line(points[j],points[j+1],Color(color_at(level,j/40.0,time),alpha),width,false)
	# Traveling ribbons weave around the shaft; more layers and width at the top tiers.
	var ribbons: int=0 if level==1 else (1 if level<4 else (2 if level==4 else 3))
	for ribbon in ribbons:
		for j in points.size()-1:
			var u: float=j/40.0
			var v: float=(j+1)/40.0
			var amplitude: float=(1+level*1.55)*sin(u*PI)*energy
			var amplitude_next: float=(1+level*1.55)*sin(v*PI)*energy
			var phase: float=u*TAU*1.5-time*3+ribbon*TAU/maxi(1,ribbons)
			var phase_next: float=v*TAU*1.5-time*3+ribbon*TAU/maxi(1,ribbons)
			var a: Vector2=points[j]+normal_at(points,j)*sin(phase)*amplitude
			var b: Vector2=points[j+1]+normal_at(points,j+1)*sin(phase_next)*amplitude_next
			var alpha: float=(.28+level*.10)*(.55+.45*maxf(0,cos(phase)))
			m.draw_line(a,b,Color(color_at(level,u,time+ribbon*.4),alpha),1.0+level*.13,false)
	# High tiers have broad translucent aurora tongues, bounded to the shaft.
	if level>=4:
		for ribbon in (2 if level==4 else 3):
			for j in range(5,39):
				var u: float=j/40.0
				var v: float=(j+1)/40.0
				var side: float=-1 if ribbon%2 else 1
				var wave: float=.55+.45*sin(u*TAU*1.5-time*2+ribbon*2)
				var wave_next: float=.55+.45*sin(v*TAU*1.5-time*2+ribbon*2)
				var off: float=side*(4+level*2)*sin(u*PI)*wave
				var off_next: float=side*(4+level*2)*sin(v*PI)*wave_next
				var a: Vector2=points[j]+normal_at(points,j)*off
				var b: Vector2=points[j+1]+normal_at(points,j+1)*off_next
				var col: Color=color_at(level,u,time+ribbon*.7)
				m.draw_colored_polygon(PackedVector2Array([points[j],a,b,points[j+1]]),Color(col,.25 if level==4 else .31))
				m.draw_line(a,b,Color(col.lightened(.1),.8),1.2,false)
	# Deterministic particles do not consume the fishing RNG.
	for i in COUNTS[level]:
		var age: float=fposmod(time*(.42+i%3*.08)+i*.618,1)
		var u: float=fposmod(i*.381+time*.06,.94)+.03
		var j: int=clampi(int(u*40),0,40)
		var p: Vector2=points[j]+normal_at(points,j)*sin(i*2.4+age*3)*age*(3+level*2)
		p.y-=age*age*(3+level*1.6)
		var col:=Color(color_at(level,u,time),sin(age*PI)*(.55+level*.07))
		var size: float=1.2 if level<3 else (1.7 if i%4 else 2.8)
		if level>=4 and i%6==0:star(m,p,2+level*.45,col)
		else:m.draw_rect(Rect2((p-Vector2.ONE*size*.5).round(),Vector2.ONE*size),col)
func front(m,points: PackedVector2Array,enhancement: int,time: float) -> void:
	var level: int=tier(enhancement)
	if level==0:return
	for j in points.size()-1:
		var u: float=j/40.0
		var sweep: float=pow(maxf(0,sin(u*TAU-time*3.2)),10)
		if sweep>.08:m.draw_line(points[j],points[j+1],Color(color_at(level,u,time).lightened(.4),sweep*.7),1.0,false)
	if level>=3:
		var pulse: float=.7+.3*sin(time*3.1)
		star(m,points[-1],(2+level*.65)*pulse,Color(color_at(level,1,time),.65+.25*pulse))
	if level==5:
		for j in 3:
			var p: Vector2=points[-1]+Vector2.from_angle(time*.8+j*TAU/3)*9
			star(m,p,1.4,Color(color_at(level,j/3.0,time),.65))
