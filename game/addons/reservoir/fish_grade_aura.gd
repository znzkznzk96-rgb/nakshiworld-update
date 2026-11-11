extends RefCounted
# Selected R3/R4/R7 rarity presentation; no simulation RNG or save state.
const FLOOR_ALPHA=0.04
const FEATHER=12.0
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
	var image=Image.create(96,32,false,Image.FORMAT_RGBA8);image.fill(Color.TRANSPARENT)
	for y in 32:
		for x in 32:
			var q=Vector2(x-15.5,y-15.5)
			var d=q.length()/6.5
			var a=0.95 if d<0.55 else 0.54 if d<1 else 0.18 if d<1.6 else 0.045 if d<2.3 else 0.0
			image.set_pixel(x,y,Color(1,1,1,a))
			var diamond=absf(q.x)*1.8+absf(q.y)
			image.set_pixel(x+32,y,Color(1,1,1,1.0 if diamond<12 else 0.0))
			var glint=(absf(q.x)<1.2 and absf(q.y)<11) or (absf(q.y)<1.2 and absf(q.x)<8)
			image.set_pixel(x+64,y,Color(1,1,1,1.0 if glint else 0.0))
	atlas=ImageTexture.create_from_image(image)
	return atlas

static func hash01(k:int,salt:int)->float:
	return fposmod(sin(float(k*127+salt*311))*43758.5453,1.0)

func _sprite(m,p:Vector2,size:Vector2,col:Color,kind:int,regions:Array):
	if col.a<=0.002:return
	var rect=Rect2(p-size*0.5,size)
	if gpu_mask:
		var at=rect.position+Vector2(0,m.oy)
		var first=points.size()
		points.append_array(PackedVector2Array([at,at+Vector2(size.x,0),at+size,at+Vector2(0,size.y)]))
		colors.append_array(PackedColorArray([col,col,col,col]))
		var left=float(kind)/3.0;var right=float(kind+1)/3.0
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
				uvs.append(Vector2((kind+uv.x)/3.0,uv.y))
			indices.append_array(PackedInt32Array([first,first+1,first+2,first,first+2,first+3]))

func _mote(m,p:Vector2,radius:float,col:Color,alpha:float,regions:Array):
	var ink=col;ink.a=alpha
	_sprite(m,p,Vector2.ONE*radius*4.9,ink,0,regions)
	ink=col.lerp(Color.WHITE,0.55);ink.a=alpha*0.65
	_sprite(m,p,Vector2.ONE*radius*1.5,ink,0,regions)

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
	var length:float=float(m.aura.get("L",60))
	var scale=clampf(length/156.0,0.45,1.0)
	var n:int=roundi([0,185,180,185,150][grade]*clampf(length/126.0,0.40,1.0))
	for k in n:
		var unit=hash01(k,1)
		var strip=clampi(int(unit*quads.size()),0,quads.size()-1)
		var v:PackedVector2Array=quads[strip][0]
		var side=-1.0 if hash01(k,2)<0.5 else 1.0
		var fraction=hash01(k,3)
		var edge:Vector2=v[0].lerp(v[1],fraction) if side<0 else v[3].lerp(v[2],fraction)
		var axis:Vector2=((v[0]+v[3])*0.5).lerp((v[1]+v[2])*0.5,fraction)
		var dir=(edge-axis).normalized()+Vector2((hash01(k,4)-0.5)*0.8,0)
		dir=dir.normalized()
		var across=Vector2(-dir.y,dir.x)
		var start=edge+dir*3.0
		var age=fposmod(t/1000.0-hash01(k,5)*3.0,3.0)
		var phase=hash01(k,6)*TAU
		var life=[0,1.15,1.10,1.50,1.8][grade]
		if age>=life:continue
		var u=age/life
		var base=start+dir*(u*[0,55,57,54,60][grade]*scale)
		last_samples.append([base,age,k])
		if grade<=2:
			var ink=Color("4fa3ff") if grade==1 else Color("bd7aff")
			var fade=minf(age*16,1)*pow(1-u,0.48 if grade==1 else 0.55)
			if grade==2:base+=across*sin(u*3.5+phase)*3.0
			var radius=(5.8 if grade==1 else 5.0) if k%4==0 else (3.5 if grade==1 else 3.0)
			radius*=1-u*0.65
			_sprite(m,base,Vector2(radius*1.2,radius*2.0),Color(ink,fade),1,regions)
			_sprite(m,base-Vector2(radius*0.12,radius*0.20),Vector2(radius*0.45,radius*0.85),Color(ink.lerp(Color.WHITE,0.7),fade),1,regions)
			if k%3==0:_mote(m,base-dir*3,1.5,ink,fade*0.5,regions)
			if k%(6 if grade==1 else 8)==0:_sprite(m,base,Vector2(9,13),Color(ink.lerp(Color.WHITE,0.8),sin(PI*u)),2,regions)
		elif grade==3:
			base+=Vector2(0,-u*14*scale)
			var fade=pow(sin(PI*u),0.65)
			for j in 5:
				var behind=j/4.0
				var p=base-dir*(behind*16*scale)+across*sin(u*4+phase-behind)*(3+u*5)*scale
				_mote(m,p,(4.6+sin(phase)*1.2)*(1-u*0.35)*(1-behind*0.25),Color("ffb93e").lerp(Color("fff1b0"),1-behind),fade*(1-behind*0.4),regions)
			if k%5==0:_sprite(m,base,Vector2(8,12),Color("fff3c2",pow(sin(PI*u),2)),2,regions)
		else:
			base+=Vector2(0,-u*10*scale)
			var fade=pow(sin(PI*u),0.65)
			for layer in 3:
				for j in 8:
					var trail=j/7.0
					var p=base-dir*(trail*23+layer*4)*scale+across*(sin(u*4+phase-trail*2)*7+layer*2.8)*scale
					var ink=Color.from_hsv(fposmod(k*0.145+trail*0.10+u*0.08,1),0.70,1).lerp(Color.WHITE,0.12)
					_mote(m,p,(2.9-trail*0.9)*(1-u*0.25),ink,fade*(1.0 if layer==0 else 0.45 if layer==1 else 0.18)*(1-trail*0.35),regions)
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
