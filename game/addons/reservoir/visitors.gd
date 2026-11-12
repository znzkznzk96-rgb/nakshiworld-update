extends RefCounted
const GROUPS: = ["boy", "girl", "young_man", "young_woman", "man", "woman", "grandpa", "grandma"]
const HEIGHT: = [27, 26, 36, 35, 38, 36, 34, 33]
const PACE: = [34, 33, 34, 33, 30, 30, 24, 23]
const STRIDE: = [20, 20, 28, 27, 27, 26, 23, 22]
const TOP: = [Color("487657"), Color("a54f42"), Color("48658a"), Color("b58e4d"), Color("87639a"), Color("579c9a"), Color("b66f8e"), Color("d3c3a0")]
const BOTTOM: = [Color("394b64"), Color("554536"), Color("4d644c"), Color("776254"), Color("4c394a"), Color("687780")]
var roster: = []
var history: = []
var textures: = []
var shader: Shader
var serial: = 0
var motion_rng := RandomNumberGenerator.new()
func setup() -> void :
	motion_rng.randomize()
	shader = Shader.new()
	shader.code = "shader_type canvas_item;\n uniform vec4 top_color: source_color;\n uniform vec4 lower_color: source_color;\n uniform sampler2D idle_head: filter_nearest;\n uniform vec2 head_shift;\n uniform float head_end;\n uniform float idle_head_end;\n uniform float stable_head;\n uniform float outfit;\n uniform float hair_light;\n uniform float skin_tone;\n void fragment(){\n vec4 c=texture(TEXTURE,UV);\n vec2 hu=UV+head_shift;\n if(stable_head>.5 && UV.y<head_end)c=texture(idle_head,hu);\n float near_alpha=0.0;\n for(int i=0;i<4;i++){\n vec2 off=vec2(i==0 ? -1.0 : (i==1 ? 1.0 : 0.0),i==2 ? -1.0 : (i==3 ? 1.0 : 0.0))*TEXTURE_PIXEL_SIZE;\n vec2 q=UV+off;\n float a=texture(TEXTURE,q).a;\n if(stable_head>.5 && q.y<head_end)a=texture(idle_head,q+head_shift).a;\n near_alpha=max(near_alpha,a);\n }\n if(c.a<.1 && near_alpha>.5)c=vec4(.025,.022,.02,.95);\n vec3 rgb=c.rgb;\n float hi=max(rgb.r,max(rgb.g,rgb.b));float lo=min(rgb.r,min(rgb.g,rgb.b));\n if(c.a>0.1 && hi>0.18){\n  if(rgb.g>rgb.r*0.90 && rgb.g>rgb.b*1.15){\n   vec3 dye=top_color.rgb;\n   \n   if(outfit>1.5 && outfit<2.5 && abs(UV.x-0.5)<0.10)dye*=0.63;\n   if(outfit>2.5 && UV.y>0.56 && abs(UV.x-0.5)<0.15)dye=vec3(0.79,0.74,0.58);\n   rgb=dye*(hi>.65 ? 1.0 : (hi>.4 ? .75 : .48));\n  }else if(rgb.b>rgb.r*1.18 && rgb.b>rgb.g*1.05){rgb=lower_color.rgb*(hi>.65 ? 1.0 : (hi>.4 ? .75 : .48));}\n  else if(UV.y<0.52 && hi<0.52 && rgb.r>rgb.g*1.08 && rgb.g>rgb.b*1.05){rgb*=mix(0.65,1.5,hair_light/3.0);}\n  else if(rgb.r>rgb.g*1.08 && rgb.g>rgb.b*1.05 && hi>0.5){rgb*=skin_tone;}\n }\n COLOR=vec4(clamp(rgb,0.0,1.0),c.a);\n }"






































	var info: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/refresh56/coherent/manifest.json"))
	for g in GROUPS:
		var frames = []
		for i in 8: frames.append(load("res://art/refresh56/coherent/%s_walk_%d.png" % [g, i]))
		textures.append({"idle": load("res://art/refresh56/coherent/%s_idle.png" % g), "walk": frames, "frames": info[g]})
func create(m, index: int = 0) -> Dictionary:
	if roster.is_empty(): roster = range(8);roster.shuffle()
	var group: int = roster.pop_back()
	var top: = 0; var bottom: = 0; var outfit: = 0; var skin: = 0; var hair: = 0; var signature: = ""
	for attempt in 100:
		top = randi() % TOP.size();bottom = randi() % BOTTOM.size();outfit = randi() % 4;skin = randi() % 4;hair = randi() % 4
		signature = "%d:%d:%d:%d:%d:%d" % [group, top, bottom, outfit, skin, hair]
		if signature not in history: break
	history.append(signature)
	if history.size() > 128: history.pop_front()
	var sprite: = Sprite2D.new()
	sprite.texture = textures[group].idle
	sprite.centered = false;sprite.offset = Vector2(-32, -60);sprite.z_index = 1
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat: = ShaderMaterial.new();mat.shader = shader
	mat.set_shader_parameter("top_color", TOP[top]);mat.set_shader_parameter("lower_color", BOTTOM[bottom]);mat.set_shader_parameter("outfit", float(outfit));mat.set_shader_parameter("skin_tone", 1.0 - skin * 0.065);mat.set_shader_parameter("hair_light", float(hair))
	mat.set_shader_parameter("idle_head", textures[group].idle)
	mat.set_shader_parameter("stable_head", 1.0)
	sprite.material = mat;m.add_child(sprite);sprite.hide()
	serial += 1
	return {"id": serial, "group": group, "signature": signature, "sprite": sprite, "x": 100.0 - index * 8, "state": 0, "wait": index * 0.45, "speed": PACE[group] * randf_range(0.94, 1.06), "velocity": 0.0, "step": 0.0, "lane": randf_range(-2, 2), "height": float(textures[group].frames[0].height) * (0.78 if group < 2 else 1.0), "pause_at": randf_range(420, 850), "paused": false, "skin": skin, "hair": hair, "top": top, "bottom": bottom, "outfit": outfit, "reward_t": 0.0, "reward": 0}
func update(r: Dictionary, dt: float) -> void :
	var old: float = r.x
	if r.wait > 0: r.wait = maxf(0, r.wait - dt);r.velocity = 0
	elif r.state == 1: r.state = 2;r.velocity = 0
	elif r.state == 3:
		if not r.has("local_goal") or absf(float(r.local_goal) - r.x) < 2.0:
			r.local_goal = motion_rng.randf_range(float(r.local_min), float(r.local_max))
			r.target_lane = motion_rng.randf_range(-7.0, 3.0)
			r.local_dir = 1.0 if float(r.local_goal) > r.x else -1.0
			r.wait = motion_rng.randf_range(0.8, 2.4)
			r.velocity = 0.0
		if r.wait <= 0:
			var dir: float = float(r.local_dir)
			r.velocity = move_toward(float(r.velocity), float(r.speed) * dir, float(r.speed) * 4 * dt)
			r.x = move_toward(r.x, float(r.local_goal), absf(r.velocity) * dt)
	else:
		var signum: = 1.0 if r.state == 0 else -1.0
		r.velocity = move_toward(float(r.velocity), float(r.speed) * signum, float(r.speed) * 4 * dt)
		r.x += r.velocity * dt
		if r.state == 0 and not r.paused and r.x >= r.pause_at:
			r.paused = true
			if randf() < 0.3: r.wait = randf_range(0.8, 2.2);r.velocity = 0
		if r.state == 0 and r.x >= 1140: r.x = 1140.0;r.state = 1;r.wait = randf_range(7, 12);r.velocity = 0
	if r.x < 350.0:
		r.lane = move_toward(float(r.lane), 0.0, dt * 7.0)
	elif absf(r.x - old) > 0.001:
		if r.state != 3:
			r.lane_distance = float(r.get("lane_distance", 90.0)) + absf(r.x - old)
			if r.lane_distance > 75.0:
				r.target_lane = motion_rng.randf_range(-7.0, 3.0);r.lane_distance = 0.0
		r.lane = move_toward(float(r.lane), float(r.get("target_lane", 0.0)), dt * 1.8)
	r.reward_t = maxf(0.0, float(r.reward_t) - dt)
	r.step += absf(r.x - old) / STRIDE[r.group] * 8.0
func sync(v, m, r: Dictionary, o: Vector2) -> void :
	var sprite: Sprite2D = r.sprite
	sprite.visible = m.scene == "village" and v._visible(r.x, 30) and not (r.get("from_ferry",false) and r.velocity==0 and r.wait>0 and r.x<=136.0+v.ground.BOARDING_OFFSET)
	if not sprite.visible: return
	var group: int = r.group
	var walking: bool = absf(r.velocity) > 0.1 and r.wait <= 0
	var frame: int = int(r.step) % 8
	sprite.texture = textures[group].walk[frame] if walking else textures[group].idle
	var info: Dictionary = textures[group].frames[frame + 1 if walking else 0]
	var right: bool = float(r.velocity) > 0 if absf(r.velocity) > 0.1 else (float(r.local_dir) > 0 if r.state == 3 else r.state == 0)
	sprite.flip_h = right != bool(info.right)
	var idle: Dictionary = textures[group].frames[0]
	sprite.material.set_shader_parameter("head_shift", Vector2(float(idle.head_x) - float(info.head_x), float(idle.head_y) - float(info.head_y)) / 64.0)
	sprite.material.set_shader_parameter("head_end", (float(info.head_y) + 14) / 64.0)
	var center: float = info.center
	sprite.offset = Vector2( - (64 - center) if sprite.flip_h else - center, - float(info.foot))
	var target: Vector2 = o + Vector2(r.x, v.visitor_y(r) + r.lane)
	var anchor: = Vector2(135, v.map_y)
	sprite.position = (anchor + (target - anchor) * v.zoom).round()
	sprite.scale = Vector2.ONE * v.zoom * (0.78 if group < 2 else 1.0)
	sprite.z_index = 30 + roundi(v.visitor_y(r) + r.lane)
func hide_all(res: Array) -> void :
	for r in res:
		if r.has("sprite") and is_instance_valid(r.sprite): r.sprite.hide()
func remove(r: Dictionary) -> void :
	if is_instance_valid(r.sprite): r.sprite.queue_free()
