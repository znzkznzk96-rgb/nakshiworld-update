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
		for k in range(125):
			var e:Dictionary=entries[k]
			var age=fposmod(time-float(e.birth),3.0)
			if age>1.05:continue
			var u=age/1.05
			var dir:Vector2=e.dir
			var pos:Vector2=e.pos+dir*(age*55.0)
			var fade=minf(age*14.0,1.0)*pow(1.0-u,0.65)
			gem(im,pos,(3.8 if k%4==0 else 2.4)*(1.0-u*0.65),tint(0,k),fade)
			if k%4==0:spark(im,pos-dir*5.0,pos,tint(0,k),fade*0.55,1.0,true)
	elif tier==1:
		# Broad S-shaped fire tongues, continuously unfurling and curling outward.
		for k in range(52):
			var e:Dictionary=entries[k*3]
			var age=fposmod(time-float(e.birth),1.5)
			if age>0.95:continue
			var u=age/0.95
			var dir:Vector2=e.dir
			var side=Vector2(-dir.y,dir.x)
			var base:Vector2=e.pos+dir*(u*26.0)
			var last=base
			var fade=sin(PI*u)*0.95
			for j in range(1,7):
				var f=j/6.0
				var point=base+dir*(f*38.0)+side*sin(f*5.5-time*5.0+float(e.phase))*(10.0*f)
				var col=Color("7438bd").lerp(Color("e6a4ff"),f)
				spark(im,last,point,col,fade*(1.0-f*0.25),6.0*(1.0-f)+1.0,j>4)
				last=point
	elif tier==2:
		# Synchronized golden eruptions, with a readable flash then flying embers.
		for k in range(76):
			var e:Dictionary=entries[k*2]
			var age=fposmod(time-float(k%5)*0.022,1.0)
			var dir:Vector2=e.dir
			var pos:Vector2=e.pos+dir*(age*90.0)
			var col=Color("ffb340")
			if age<0.40:
				var fade=sin(PI*age/0.40)
				var length=18.0+age*52.0
				spark(im,pos-dir*length,pos,col,fade,4.0*(1.0-age),true)
			if age>0.14 and age<0.86:
				var fade=sin(PI*(age-0.14)/0.72)
				gem(im,pos+Vector2(0,age*age*14.0),3.0*(1.0-age*0.5),col,fade)
				if k%6==0:
					spark(im,pos-Vector2(4,0),pos+Vector2(4,0),Color("ffe5a3"),fade,0.7,true)
					spark(im,pos-Vector2(0,6),pos+Vector2(0,6),Color("ffe5a3"),fade,0.7,true)
	else:
		# Multi-stage prismatic detonation: branching jets, delayed echoes and shards.
		for k in range(66):
			var e:Dictionary=entries[k*3]
			var age=fposmod(time-float(k%3)*0.15,1.5)
			var dir:Vector2=e.dir
			var side=Vector2(-dir.y,dir.x)
			var col=tint(3,k*0.19)
			var start:Vector2=e.pos
			if age<0.58:
				var u=age/0.58
				var fade=sin(PI*u)
				var base=start+dir*(u*60.0)
				var last=base-dir*22.0
				for j in range(1,5):
					var point=base+dir*(j*7.0-22.0)+side*(sin(j*2.3+float(e.phase))*8.0*(1.0-u))
					spark(im,last,point,col,fade,3.0*(1.0-u)+1.0,true)
					if j==2 and k%3==0:spark(im,point,point+dir*12.0+side*12.0,col,fade*0.8,1.8,true)
					last=point
			if age>0.22 and age<1.25:
				var u=(age-0.22)/1.03
				var pos=start+dir*(16.0+u*75.0)+side*sin(u*3.0+float(e.phase))*5.0
				gem(im,pos,5.0*(1.0-u)+1.0,col,sin(PI*u)*0.9)

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
	for tier in range(4):
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
	var meta={"prototype":true,"engine":Engine.get_version_info().string,"frames":48,"fps":16,"seconds":3,"tiers":["rare","unique","legendary","mythic"],"fish":["01","13","20"],"revision":2,"emitter_counts":[125,52,76,66],"cycles_seconds":[3,1.5,1,1.5],"mechanisms":["independent drifting motes","curling flame tongues","synchronized gold eruption and embers","branching jets and delayed prismatic shards"],"fixed_fish_scales":[specs[0].scale,specs[1].scale,specs[2].scale],"body_envelope_transparent":true,"no_closed_ring":true,"paid_generations":0,"game_applied":false}
	FileAccess.open("res://output/SPEC.json",FileAccess.WRITE).store_string(JSON.stringify(meta,"\t"))
	quit()
