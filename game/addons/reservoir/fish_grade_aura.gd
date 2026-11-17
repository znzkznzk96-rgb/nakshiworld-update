extends RefCounted
# Presentation follows the same head-to-tail strips as the swimming body.
const FLOOR_ALPHA=0.04
const FEATHER=12.0
var outlines := {}
var outline := PackedVector2Array()
var wake := PackedVector2Array()
var stamps := PackedFloat64Array()
var wake_key := ""
const TILE_COUNT := 4
const GLINT_COUNTS := [0,0,7,9,16]
var atlas:Texture2D
var points=PackedVector2Array()
var uvs=PackedVector2Array()
var colors=PackedColorArray()
var indices=PackedInt32Array()
var last_samples:Array=[]
var masking_enabled=true
var cue_strength=0.0
var cue_rect=Rect2()
var last_visual_clock=-1.0
var region_weights:Array=[]
var surface:Node2D
var gpu_mask=false
class AuraSurface extends Node2D:
	var packet:Array=[]
	func _draw():
		if not packet.is_empty():RenderingServer.canvas_item_add_triangle_array(get_canvas_item(),packet[0],packet[1],packet[2],packet[3],PackedInt32Array(),PackedFloat32Array(),packet[4].get_rid())
func begin_frame():
	if is_instance_valid(surface):surface.packet=[];surface.hide();surface.queue_redraw()
func _surface(m)->Node2D:
	if is_instance_valid(surface):return surface
	surface=AuraSurface.new();surface.name="FishAuraSurface";surface.show_behind_parent=true
	var shader=Shader.new()
	shader.code="""shader_type canvas_item;
uniform vec4 cue_rect;
uniform vec4 hud_rect;
uniform float cue_strength=0.0;
uniform float enabled=1.0;
varying vec2 local_position;
varying vec4 aura_ink;
void vertex(){local_position=VERTEX;aura_ink=COLOR;}
float attenuation(vec4 r){vec2 d=max(max(r.xy-local_position,vec2(0.0)),local_position-r.xy-r.zw);return mix(0.04,1.0,smoothstep(2.0,12.0,length(d)));}
void fragment(){vec4 ink=texture(TEXTURE,UV)*aura_ink;float a=min(mix(1.0,attenuation(cue_rect),cue_strength),attenuation(hud_rect));COLOR=vec4(ink.rgb,ink.a*mix(1.0,a,enabled));}
"""
	var ink=ShaderMaterial.new();ink.shader=shader;surface.material=ink
	m.text_layer.add_child(surface)
	return surface

static func mask_alpha(p:Vector2,regions:Array)->float:
	var factor=1.0
	for region in regions:
		var r:Rect2=region
		if r.size.x<=0:continue
		var dx=maxf(maxf(r.position.x-p.x,0),p.x-r.end.x)
		var dy=maxf(maxf(r.position.y-p.y,0),p.y-r.end.y)
		factor=minf(factor,lerpf(FLOOR_ALPHA,1.0,smoothstep(2.0,FEATHER,Vector2(dx,dy).length())))
	return factor

func _atlas()->Texture2D:
	if atlas!=null:return atlas
	# Native pixel silhouettes: bubble, scale, fry and four-point glint.
	var tiles := [
		["..2332..",".31..23.","31....13","2.....12","2.....12","31....13",".322223.","..2332.."],
		["....2...","..2342..",".234432.","23433221",".232221.","..2211..","...11...","........"],
		["........","...2....","3.23432.","23234413","12233332","1..2211.","....1...","........"],
		["...1....","...2....","..232...",".234432.","..232...","...2....","...1....","........"]
	]
	var image := Image.create(8*TILE_COUNT,8,false,Image.FORMAT_RGBA8)
	var ink := [Color.TRANSPARENT,Color(0.34,0.48,0.62,0.82),Color(0.63,0.78,0.89),Color(0.91,0.97,1),Color.WHITE]
	for tile in tiles.size():
		for y in 8:
			for x in 8:
				var tone: String = tiles[tile][y][x]
				if tone != ".":
					image.set_pixel(tile*8+x,y,ink[int(tone)])
	atlas=ImageTexture.create_from_image(image)
	return atlas

func _sprite(m,p:Vector2,size:Vector2,col:Color,kind:int,regions:Array):
	if col.a<=0.002:return
	var rect=Rect2(p-size*0.5,size)
	if gpu_mask:
		var at=rect.position+Vector2(0,m.oy)
		var first=points.size()
		points.append_array(PackedVector2Array([at,at+Vector2(size.x,0),at+size,at+Vector2(0,size.y)]))
		colors.append_array(PackedColorArray([col,col,col,col]))
		var left=float(kind)/TILE_COUNT;var right=float(kind+1)/TILE_COUNT
		uvs.append_array(PackedVector2Array([Vector2(left,0),Vector2(right,0),Vector2(right,1),Vector2(left,1)]))
		indices.append_array(PackedInt32Array([first,first+1,first+2,first,first+2,first+3]))
		return
	var near=false
	for r in regions:
		if (r as Rect2).grow(FEATHER).intersects(rect):near=true
	var steps=3 if near and masking_enabled and not gpu_mask else 1
	for y in steps:
		for x in steps:
			var a=Vector2(float(x)/steps,float(y)/steps)
			var b=a+Vector2.ONE/steps
			var coords=[a,Vector2(b.x,a.y),b,Vector2(a.x,b.y)]
			var first=points.size()
			for uv in coords:
				var at=rect.position+uv*size
				var ink=col
				if near and masking_enabled and not gpu_mask:
					var attenuation=1.0
					for z in regions.size():attenuation=minf(attenuation,lerpf(1.0,mask_alpha(at,[regions[z]]),float(region_weights[z])))
					ink.a*=attenuation
				colors.append(ink)
				points.append(at+Vector2(0,0 if m.ui_demo else m.oy))
				uvs.append(Vector2((kind+uv.x)/TILE_COUNT,uv.y))
			indices.append_array(PackedInt32Array([first,first+1,first+2,first,first+2,first+3]))

# Read each sprite once. Quantiles keep tall decorative fins from lifting the
# whole aura away from the denser body pixels.
func _outline(texture:Texture2D) -> PackedVector2Array:
	var key := texture.get_instance_id()
	if outlines.has(key): return outlines[key]
	var image := texture.get_image()
	var profile := PackedVector2Array()
	var bounds := image.get_used_rect()
	for x in image.get_width():
		var rows := PackedInt32Array()
		for y in range(bounds.position.y,bounds.end.y):
			if image.get_pixel(x,y).a > 0.4: rows.append(y)
		if rows.is_empty(): profile.append(Vector2(0.5,0.5))
		else:
			var last := rows.size()-1
			profile.append((Vector2(rows[roundi(last*0.12)],rows[roundi(last*0.88)]+1)-Vector2.ONE*bounds.position.y)/maxf(1,bounds.size.y))
	outlines[key]=profile
	return profile

func _remember(t:float,tail:Vector2,key:String,length:float):
	if key!=wake_key or (not stamps.is_empty() and (t<stamps[-1] or t-stamps[-1]>0.25 or wake[-1].distance_to(tail)>length*1.5)):
		stamps.clear()
		wake.clear()
	wake_key=key
	if stamps.is_empty() or t-stamps[-1]>=0.022:
		stamps.append(t)
		wake.append(tail)
		if stamps.size()>22:
			stamps.remove_at(0)
			wake.remove_at(0)

func _past(t:float,tail:Vector2) -> Vector2:
	if stamps.is_empty(): return tail
	for i in range(stamps.size()-1,0,-1):
		if stamps[i-1]<=t:
			return wake[i-1].lerp(wake[i],clampf(inverse_lerp(stamps[i-1],stamps[i],t),0,1))
	return wake[0]

# Sample the moving top/bottom edge; beyond the tail continue its tangent.
func _edge(quads:Array,u:float,upper:bool) -> Vector2:
	var strip := clampi(floori(u*quads.size()),0,quads.size()-1)
	var v:PackedVector2Array = quads[strip][0]
	var f := u*quads.size()-strip
	var a := v[0].lerp(v[1],f)
	var b := v[3].lerp(v[2],f)
	if outline.is_empty(): return a if (a.y < b.y) == upper else b
	var uv:PackedVector2Array=quads[strip][1]
	var x:=clampi(floori(lerpf(uv[0].x,uv[1].x,f)*outline.size()),0,outline.size()-1)
	var limits:=outline[x]
	return a.lerp(b,limits.x if (a.y < b.y) == upper else limits.y)

func _emit(m,p:Vector2,size:Vector2,color:Color,kind:int,regions:Array):
	last_samples.append(p)
	_sprite(m,p,size,color,kind,regions)

# Detached bubbles rise in the water while the fish continues swimming.
func _water_particles(m,grade:int,quads:Array,tail:Vector2,forward:Vector2,unit:float,t:float,history:bool,regions:Array):
	var count:int=[0,10,15,12,15][grade]
	var tint:Color=[Color.WHITE,Color("08ddff"),Color("b039ff"),Color("ffba09"),Color("14ffd7")][grade]
	for k in count:
		var speed:=0.67+0.16*sin(k*3.87)
		var age:=fposmod(t*speed+k*0.618,1.0)
		var upper:=k%2==0
		var anchor:=fposmod(k*0.3819+0.08,1.0)
		var at:=_edge(quads,anchor,upper)
		var offset:=Vector2(sin(k*1.9+age*4.0)*1.9,(-1.0 if upper else 1.0)*2.0-age*age*(8.0+4.0*sin(k)))*unit
		at+=offset-forward*(age*age*(6.0+3.0*cos(k))*unit)
		if history: at+=(_past(t-age*0.32,tail)-tail)*age
		var radius:float=(3.0+2.4*fposmod(k*0.43,1.0)+0.9*age)*unit
		var alpha:=pow(maxf(0.0,sin(PI*age)),0.55)
		_emit(m,at,Vector2.ONE*radius,Color(tint,alpha*0.97),0,regions)
		if grade == 1 and k % 3 == 0:
			var wake_at := at - forward * (3.0 + age * 12.0) * unit
			var bubble_size := (5.0 + 3.0 * age) * unit
			_emit(m,wake_at,Vector2.ONE*bubble_size,Color(Color("24edff"),alpha),0,regions)
			var small_at := wake_at - forward * bubble_size * 0.7 + Vector2.UP * age * 4.0 * unit
			_emit(m,small_at,Vector2.ONE*bubble_size*0.49,Color(Color("85ffe3"),alpha),0,regions)
		if grade>=2 and k%2==0:
			# A detached scale flashes only while its broad face turns to the light.
			var flip:=absf(sin(t*3.7+k*2.31))
			var scale_at:=at-forward*2.8*unit+Vector2(0,2.2*unit)
			var metal:Color=[Color.WHITE,Color.WHITE,Color("c02aff"),Color("ff9700"),Color.from_hsv(fposmod(0.47+k*0.16+t*0.08,1),0.92,1)][grade]
			_emit(m,scale_at,Vector2(1.8+4.8*flip,4.8)*unit,Color(metal.lerp(Color.WHITE,pow(flip,8)*0.25),alpha),1,regions)

# Offset the individual pulses so the school shimmers without flashing as a unit.
func _glints(m,grade:int,quads:Array,tail:Vector2,forward:Vector2,unit:float,t:float,history:bool,regions:Array):
	for k: int in GLINT_COUNTS[grade]:
		var phase := fposmod(t*(0.82+0.12*cos(k*2.13))+k*0.618,1.0)
		var pulse := pow(maxf(0.0,sin(PI*phase)),2.5)
		var upper := k%2==0
		var anchor := fposmod(k*0.382+0.18,1.0)
		var at := _edge(quads,anchor,upper)
		var drift := (3.2+4.5*fposmod(k*0.73,1.0)+phase*4.0)*unit
		at += Vector2(0,-drift if upper else drift)-forward*phase*phase*unit*(5.0+k%5)
		if history: at+=(_past(t-phase*0.27,tail)-tail)*phase
		var tint := Color("dc42ff")
		if grade==3: tint=Color("ffcc0a")
		elif grade==4: tint=Color.from_hsv(fposmod(0.42+k*0.173,1.0),0.89,1)
		var radius := (3.0+5.2*pulse)*unit
		_emit(m,at,Vector2.ONE*radius,Color(tint.lerp(Color.WHITE,pulse*0.16),pulse),3,regions)

func queue(m,quads:Array,grade:int,t:float):
	points.clear();uvs.clear();colors.clear();indices.clear();last_samples.clear()
	gpu_mask=not m.ui_demo and is_instance_valid(m.text_layer)
	if grade<=0 or quads.is_empty():return
	var context:Dictionary=m.aura_cue_context
	var regions:Array=[]
	region_weights.clear()
	if not m.ui_demo and str(m.S.get("phase",""))=="fight" and not context.is_empty():
		var layout:Dictionary=m.fight_telegraph.layout(m,context.center,float(m.aura.L),bool(context.group),context.hud)
		var visual_dt=clampf(float(m.clock)-last_visual_clock,0.0,0.05) if last_visual_clock>=0 else 0.0
		last_visual_clock=float(m.clock)
		if layout.bounds.size.x>0:
			cue_rect=layout.bounds.grow(2);cue_strength=1.0
		else:cue_strength=maxf(0.0,cue_strength-visual_dt/0.16)
		if cue_strength>0:
			regions.append(cue_rect);region_weights.append(cue_strength)
		regions.append(layout.hud);region_weights.append(1.0)
	outline = _outline(m.aura.tex) if m.aura.has("tex") and not m.ui_demo else PackedVector2Array()
	var head := (_edge(quads,0,true)+_edge(quads,0,false))*0.5
	var tail := (_edge(quads,1,true)+_edge(quads,1,false))*0.5
	var length := maxf(12.0,head.distance_to(tail))
	var unit := clampf(length/42.0,0.75,2.0)
	var forward := (head-tail).normalized()
	var seconds := t*0.001
	var remember_motion:bool=not m.ui_demo and not context.get("group",false)
	if remember_motion: _remember(seconds,tail,str(m.aura.get("tex"))+str(grade),length)
	var beat := float(m.aura.get("swim_phase",seconds*TAU))
	var surge := 1.0 if str(m.aura.get("behavior","")) in ["run","charge","turn","thrash"] else 0.0
	_water_particles(m,grade,quads,tail,forward,unit,seconds,remember_motion,regions)
	_glints(m,grade,quads,tail,forward,unit,seconds,remember_motion,regions)
	for side in 2:
		var upper := side == 0
		var normal := Vector2.UP if upper else Vector2.DOWN
		var flow := fposmod(seconds*0.77 + side*0.43,1.0)
		match grade:
			1:
				for k in 2:
					var age := fposmod(seconds*0.85+k*0.51+side*0.83,1.0)
					var at := _edge(quads,0.08+0.88*age,upper)
					at += normal*(1.0+age*2.0)*unit + Vector2(0,-age*age*5)*unit
					if remember_motion: at+=(_past(seconds-age*0.29,tail)-tail)*smoothstep(0.2,0.9,age)
					var radius := (4.4+2.3*age)*unit
					_emit(m,at,Vector2.ONE*radius,Color(Color("36efff"),pow(sin(PI*age),0.65)),0,regions)
			2:
				var u := 0.50+0.46*sin(seconds*2.6+side*PI)
				var at := _edge(quads,u,upper)+normal*(2.4+2.0*sin(PI*u))*unit
				if remember_motion: at+=(_past(seconds-0.08,tail)-tail)*u*0.36
				var flip := absf(cos(seconds*4.4+side*2.1))
				_emit(m,at,Vector2(2+8*flip,8)*unit,Color("b431ff").lerp(Color("f489ff"),pow(flip,5)),1,regions)
			3:
				for k in 5:
					var u := flow-k*0.045
					if u >= 0:
						var at := _edge(quads,u,upper)+normal*(1.1+sin(PI*u))*unit
						_emit(m,at,Vector2(5.8-k*0.65,3.4)*unit,Color(Color("ffe43d").lerp(Color("ff8a00"),k/5.0),sin(PI*flow)*(1-k*0.16)),1,regions)
			4:
				for k in 3:
					var u := fposmod(flow+k/3.0,1.0)
					var pearl := Color.from_hsv(fposmod(u*0.42+side*0.3+seconds*0.12,1.0),0.83,1)
					_emit(m,_edge(quads,u,upper)+normal*1.6*unit,Vector2(4,2.8)*unit,Color(pearl,sin(PI*u)*0.86),1,regions)
	if grade == 3:
		for k in 6:
			var age := fposmod(beat/TAU*0.5-k*0.158,1.0)
			var travel := (1.0-pow(1.0-age,2))*length*(0.63+surge*0.24)
			var at := tail-forward*travel + Vector2(0,(k-2.5)*sin(age*PI*0.85)*3.45-sin(age*TAU)*2.5)*unit
			if remember_motion: at+=(_past(seconds-0.24*age,tail)-tail)*age*0.55
			var flip := absf(cos(age*9+k))
			_emit(m,at,Vector2(3+7*flip,7.5)*unit,Color(Color("ff8800").lerp(Color("ffe53d"),flip),sin(PI*age)),1,regions)
	elif grade == 4:
		for k in 5:
			var orbit := seconds*(1.65+0.09*k)+k*TAU/5.0
			var at := tail-forward*length*(0.13+0.33*cos(orbit)+k*0.078)
			at.y += sin(orbit)*(7+k*0.8+surge*4)*unit
			if remember_motion: at+=(_past(seconds-0.10-k*0.05,tail)-tail)*0.65
			var hue := fposmod(0.48+k*0.23+0.09*sin(orbit),1.0)
			var pearl := Color.from_hsv(hue,0.88,1).lerp(Color.WHITE,pow(absf(cos(orbit)),8)*0.22)
			var size := Vector2(10.5+1.8*cos(beat+k)+k*0.4,6.8+k*0.24)*unit
			if forward.x<0: size.x=-size.x
			_emit(m,at,size,pearl,2,regions)
	if not indices.is_empty():
		if gpu_mask:
			var target=_surface(m)
			target.packet=[indices.duplicate(),points.duplicate(),colors.duplicate(),uvs.duplicate(),_atlas()]
			var material:ShaderMaterial=target.material
			var offset=Vector2(0,m.oy)
			var cue=Rect2(cue_rect.position+offset,cue_rect.size)
			var hud=Rect2()
			if not regions.is_empty():hud=regions[-1];hud.position+=offset
			material.set_shader_parameter("cue_rect",Vector4(cue.position.x,cue.position.y,cue.size.x,cue.size.y))
			material.set_shader_parameter("hud_rect",Vector4(hud.position.x,hud.position.y,hud.size.x,hud.size.y))
			material.set_shader_parameter("cue_strength",cue_strength if not regions.is_empty() else 0.0)
			material.set_shader_parameter("enabled",1.0 if masking_enabled and not regions.is_empty() else 0.0)
			target.show();target.queue_redraw()
		else:m.ui_commands.append(["triangles",indices.duplicate(),points.duplicate(),colors.duplicate(),uvs.duplicate(),_atlas()])
