extends SceneTree

const W=384
const H=720
const IDS=["01","13","20"]
const LENGTHS=[158.0,126.0,188.0]
const COUNTS=[160,190,210,220]
const SPEEDS=[64.0,72.0,80.0,88.0]
var clips=[]
var specs=[]

func tint(tier:int,k:float)->Color:
	if tier==0:return Color("4fa3ff")
	if tier==1:return Color("b06cff")
	if tier==2:return Color("ffb340")
	return Color.from_hsv(fposmod(k*0.618,1.0),0.68,1.0)

func spark(im:Image,a:Vector2,b:Vector2,col:Color,alpha:float,wide:float,hot:bool=false):
	var lo=(a.min(b)-Vector2(5,5)).floor()
	var hi=(a.max(b)+Vector2(5,5)).ceil()
	var ab=b-a
	for yy in range(maxi(0,int(lo.y)),mini(H,int(hi.y)+1)):
		for xx in range(maxi(0,int(lo.x)),mini(W,int(hi.x)+1)):
			var q=Vector2(xx,yy)
			var u=clampf((q-a).dot(ab)/maxf(ab.length_squared(),1),0,1)
			var dist=q.distance_to(a+ab*u)
			var radius=wide*(1.0-u*0.7)
			var strength=0.0
			if dist<radius:strength=1.0
			elif dist<radius+1.5:strength=0.32
			elif dist<radius+3.0:strength=0.10
			if strength<=0:continue
			var c=col
			if hot and dist<0.7:c=col.lerp(Color.WHITE,0.85)
			c.a=clampf(alpha*strength,0,1)
			im.set_pixel(xx,yy,im.get_pixel(xx,yy).blend(c))

func gem(im:Image,pos:Vector2,size:float,col:Color,alpha:float):
	# Rhombus fragments, visibly different from streak or flame forms.
	for yy in range(-ceili(size),ceili(size)+1):
		var span=maxf(0.0,size-absf(yy))*0.55
		for xx in range(-ceili(span),ceili(span)+1):
			var x=roundi(pos.x)+xx;var y=roundi(pos.y)+yy
			if x<0 or x>=W or y<0 or y>=H:continue
			var c=col.lerp(Color.WHITE,0.75 if xx<=0 else 0.05);c.a=alpha
			im.set_pixel(x,y,im.get_pixel(x,y).blend(c))

func draw_tier(im:Image,tier:int,time:float,entries:Array):
	if tier==0:
		# Freely drifting angular blue motes: no sustained streams.
		for k in range(185):
			var e:Dictionary=entries[k]
			var age=fposmod(time-float(e.birth),3.0)
			if age>1.15:continue
			var u=age/1.15
			var dir:Vector2=e.dir
			var pos:Vector2=e.pos+dir*(age*55.0)
			var fade=minf(age*14.0,1.0)*pow(1.0-u,0.48)
			gem(im,pos,(5.8 if k%4==0 else 3.5)*(1.0-u*0.65),tint(0,k),fade)
			if k%3==0:spark(im,pos-dir*7.0,pos,tint(0,k),fade*0.75,1.2,true)
			if k%6==0:
				var flash=sin(PI*u)
				spark(im,pos-Vector2(5,0),pos+Vector2(5,0),Color("c9f1ff"),flash,0.8,true)
				spark(im,pos-Vector2(0,7),pos+Vector2(0,7),Color("c9f1ff"),flash,0.8,true)
	elif tier==1:
		# Separate violet gems and narrow short afterglows; no broad flame ribbons.
		for k in range(180):
			var e:Dictionary=entries[k]
			var age=fposmod(time-float(e.birth),3.0)
			if age>1.10:continue
			var u=age/1.10
			var dir:Vector2=e.dir
			var side=Vector2(-dir.y,dir.x)
			var pos:Vector2=e.pos+dir*(age*57.0)+side*sin(u*3.5+float(e.phase))*3.0
			var fade=minf(age*16.0,1.0)*pow(1.0-u,0.55)
			var col=Color("bd7aff")
			gem(im,pos,(5.0 if k%4==0 else 3.0)*(1.0-u*0.65),col,fade)
			if k%3==0:
				var tail=pos-dir*(8.0*(1.0-u))+side*2.0
				spark(im,tail,pos,col,fade*0.65,0.9,true)
			if k%8==0:
				var flash=sin(PI*u)
				spark(im,pos-Vector2(4,0),pos+Vector2(4,0),Color("edcbff"),flash,0.65,true)
				spark(im,pos-Vector2(0,5),pos+Vector2(0,5),Color("edcbff"),flash,0.65,true)
	elif tier==2:
		# Heavy solar eruptions: broad tapered fire, then detached embers.
		for k in range(18):
			var e:Dictionary=entries[k*11]
			var age=fposmod(time-float(k%3)*0.045,1.5)
			var dir:Vector2=e.dir
			if age<0.94:
				var u=age/0.94
				var pulse=pow(sin(PI*u),0.75)
				var start:Vector2=e.pos+dir*(u*6.0)
				flame(im,start,dir,12.0+34.0*pulse,4.0+6.0*pulse,float(e.phase)+time*3.0,pulse)
		for k in range(90):
			var e:Dictionary=entries[k*2]
			var age=fposmod(time-float(k%7)*0.03,1.5)
			if age<0.32 or age>1.25:continue
			var u=(age-0.32)/0.93
			var dir:Vector2=e.dir
			var pos:Vector2=e.pos+dir*(26.0+u*65.0)+Vector2(0,u*u*10.0)
			var fade=sin(PI*u)
			spark(im,pos-dir*(5.0*(1.0-u)+1.0),pos,Color("ffbc45"),fade,1.6*(1.0-u)+0.5,true)
	else:
		# Spatial tears open in empty water. Energy leaves the tear before it closes.
		for k in range(7):
			var e:Dictionary=entries[k*29]
			var age=fposmod(time-float(k%5)*0.30,3.0)
			if age>1.32:continue
			var u=age/1.32
			var dir:Vector2=e.dir
			var tangent=Vector2(-dir.y,dir.x).rotated(sin(float(e.phase))*0.35)
			var center:Vector2=e.pos+dir*25.0
			var opening=pow(sin(PI*u),0.65)
			var half=18.0+10.0*opening
			var gap=7.5*opening
			var polygon=PackedVector2Array([center-tangent*half,center-tangent*half*0.4+dir*(gap+2.0),center+tangent*half*0.3+dir*gap,center+tangent*half,center+tangent*half*0.35-dir*(gap+1.0),center-tangent*half*0.3-dir*gap])
			fill_poly(im,polygon,Color(0.015,0.01,0.08,opening*0.92))
			for j in range(polygon.size()):
				var a:Vector2=polygon[j];var b:Vector2=polygon[(j+1)%polygon.size()]
				var color=Color("69e9ff") if j<3 else Color("ce7dff")
				spark(im,a,b,color,opening,1.5,true)
			# Hairline fractures extend beyond the tips; not a circular enclosure.
			spark(im,center-tangent*half,center-tangent*(half+9.0)+dir*3.0,Color("b6caff"),opening*0.8,0.6,true)
			if u>0.18 and u<0.85:
				var burst=sin(PI*(u-0.18)/0.67)
				for branch in range(3):
					var ray=dir.rotated((branch-1)*0.48)
					var start=center+tangent*(branch-1)*9.0
					var reach=12.0+burst*42.0
					var mid=start+ray*reach*0.55+tangent*sin(time*8.0+branch)*8.0
					var end=start+ray*reach
					spark(im,start,mid,Color("b58cff"),burst*0.22,7.0,false)
					spark(im,start,mid,Color("85eaff"),burst*0.85,3.0,true)
					spark(im,mid,end,Color("f2c0ff"),burst,2.0,true)
			if u>0.35:
				var drift=(u-0.35)/0.65
				for shard in range(4):
					var pos=center+dir*(14.0+drift*62.0)+tangent*((shard-1.5)*9.0+sin(drift*4.0)*5.0)
					gem(im,pos,4.0*(1.0-drift)+1.0,Color("9cc8ff") if shard%2==0 else Color("e0a0ff"),sin(PI*drift)*0.9)

func fill_poly(im:Image,poly:PackedVector2Array,col:Color):
	var lo=poly[0];var hi=poly[0]
	for point in poly:lo=lo.min(point);hi=hi.max(point)
	for y in range(maxi(0,floori(lo.y)),mini(H,ceili(hi.y)+1)):
		for x in range(maxi(0,floori(lo.x)),mini(W,ceili(hi.x)+1)):
			if Geometry2D.is_point_in_polygon(Vector2(x,y),poly):im.set_pixel(x,y,im.get_pixel(x,y).blend(col))

func flame(im:Image,start:Vector2,dir:Vector2,length:float,width:float,phase:float,alpha:float):
	var side=Vector2(-dir.y,dir.x)
	var left=[];var right=[]
	for j in range(8):
		var u=j/7.0
		var center=start+dir*(u*length)+side*sin(u*5.2+phase)*(u*9.0)
		var thick=width*pow(1.0-u,0.8)*(0.65+0.35*sin(PI*u))
		left.append(center+side*thick);right.append(center-side*thick)
	var poly=PackedVector2Array(left)
	right.reverse();poly.append_array(PackedVector2Array(right))
	fill_poly(im,poly,Color(1.0,0.34,0.025,alpha*0.65))
	for j in range(1,7):
		var u=j/7.0
		var a=start+dir*((u-1.0/7.0)*length)+side*sin((u-1.0/7.0)*5.2+phase)*((u-1.0/7.0)*9.0)
		var b=start+dir*(u*length)+side*sin(u*5.2+phase)*(u*9.0)
		spark(im,a,b,Color("ffd052").lerp(Color("fff3bd"),u),alpha,width*0.45*(1.0-u)+0.8,true)

func _initialize():
	for idx in range(3):
		var seq=[]
		var original=Image.load_from_file("res://fish/%s/00.png"%IDS[idx])
		var ref=original.get_used_rect()
		var scale=LENGTHS[idx]/ref.size.x
		var bounds=[]
		for frame in range(16):
			var img=Image.load_from_file("res://fish/%s/%02d.png"%[IDS[idx],frame])
			img.convert(Image.FORMAT_RGBA8)
			img.resize(roundi(img.get_width()*scale),roundi(img.get_height()*scale),Image.INTERPOLATE_NEAREST)
			seq.append(img)
		clips.append(seq)
		var first:Image=seq[0]
		var box=first.get_used_rect()
		var origin=Vector2((W-box.size.x)/2-box.position.x,idx*240+112-box.position.y-box.size.y/2)
		var rng=RandomNumberGenerator.new();rng.seed=2026111100+idx
		var emitters=[]
		for k in range(220):
			var sx=rng.randi_range(box.position.x+roundi(box.size.x*0.12),box.end.x-roundi(box.size.x*0.12)-1)
			var top=-1;var bottom=-1
			for yy in range(first.get_height()):
				if first.get_pixel(sx,yy).a>0.1:
					if top<0:top=yy
					bottom=yy
			if top<0:continue
			var side=-1.0 if rng.randf()<0.5 else 1.0
			var pos=origin+Vector2(sx,(top-4) if side<0 else (bottom+4))
			var vel=Vector2(rng.randf_range(-0.9,0.9),side*rng.randf_range(0.75,1.10)).normalized()
			emitters.append({"pos":pos,"dir":vel,"birth":rng.randf()*3.0,"life":rng.randf_range(0.75,1.10),"speed":rng.randf_range(0.65,1.15),"kind":rng.randi_range(0,9),"phase":rng.randf()*TAU})
		specs.append({"origin":origin,"box":box,"emitters":emitters,"scale":scale})
	for tier in [2,3]:
		DirAccess.make_dir_recursive_absolute("res://output/%d"%tier)
		for frame in range(48):
			var time=frame/16.0
			var aura=Image.create(W,H,false,Image.FORMAT_RGBA8);aura.fill(Color.TRANSPARENT)
			var board=Image.create(W,H,false,Image.FORMAT_RGBA8);board.fill(Color("10283d"))
			for y in range(H):
				var c=Color("10283d").lerp(Color("0a172a"),float(y%240)/240)
				for x in range(W):board.set_pixel(x,y,c)
			for idx in range(3):
				var ss:Dictionary=specs[idx]
				var entries:Array=ss.emitters
				draw_tier(aura,tier,time,entries)
				# Clear entire body-column envelope: there is no opaque central slab.
				var fish:Image=clips[idx][frame%16]
				var origin:Vector2=ss.origin
				for x in range(fish.get_width()):
					var top=-1;var bottom=-1
					for y in range(fish.get_height()):
						if fish.get_pixel(x,y).a>0.1:
							if top<0:top=y
							bottom=y
					if top<0:continue
					for yy in range(top-2,bottom+3):
						var dx=roundi(origin.x)+x;var dy=roundi(origin.y)+yy
						if dx>=0 and dx<W and dy>=0 and dy<H:aura.set_pixel(dx,dy,Color.TRANSPARENT)
			board.blend_rect(aura,Rect2i(0,0,W,H),Vector2i.ZERO)
			for idx in range(3):
				board.blend_rect(clips[idx][frame%16],Rect2i(Vector2i.ZERO,clips[idx][frame%16].get_size()),Vector2i(specs[idx].origin))
			board.save_png("res://output/%d/frame-%02d.png"%[tier,frame])
			if frame in [0,12,24,36]:aura.save_png("res://output/%d/alpha-%02d.png"%[tier,frame])
		print("TIER_DONE ",tier)
	var meta={"prototype":true,"engine":Engine.get_version_info().string,"frames":48,"fps":16,"seconds":3,"tiers":["rare","unique","legendary","mythic"],"fish":["01","13","20"],"revision":5,"emitter_counts":[185,180,76,66],"cycles_seconds":[3,1.5,1,1.5],"mechanisms":["independent drifting motes","separate violet gems and slim short afterglows","synchronized gold eruption and embers","branching jets and delayed prismatic shards"],"fixed_fish_scales":[specs[0].scale,specs[1].scale,specs[2].scale],"body_envelope_transparent":true,"no_closed_ring":true,"paid_generations":0,"game_applied":false}
	FileAccess.open("res://output/SPEC.json",FileAccess.WRITE).store_string(JSON.stringify(meta,"\t"))
	quit()
