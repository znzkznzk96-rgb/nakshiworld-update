extends SceneTree
func _initialize() -> void:
	var path: String=OS.get_cmdline_user_args()[0]
	assert(ProjectSettings.load_resource_pack(path),"load actual exported pack")
	assert(FileAccess.file_exists("res://art/angler_b/cat-atlas.png.b64.txt"),"cat asset data exported")
	var a=load("res://addons/reservoir/angler_scene.gd").new();a.setup()
	assert(a.cats.idle.size()==48 and a.cats.hop.size()==12 and a.cats.look.size()==12)
	assert(a.textures["face-neutral"].get_size()==Vector2(160,160))
	assert(a.rod_aura.tier(20)==10 and a.rod_aura.tier(2)==1,"actual enhancement aura exported")
	assert(a.rod_aura.COLORS[1].r>a.rod_aura.COLORS[1].b and a.rod_aura.COLORS[2].b>a.rod_aura.COLORS[2].r+.5,"silver blue distinct in actual pack")
	assert(load("res://addons/reservoir/personal_dex.gd")!=null,"personal dex exported")
	assert(absf(load("res://sfx/village/village.ogg").get_length()-27.0)<0.1,"original D loop exported")
	var expedition=load("res://addons/expedition/view.gd").new();expedition.setup()
	assert(expedition.data.catalog.soldiers.size()==15 and expedition.data.catalog.enemies.size()==22,"battle catalog exported")
	for texture in expedition.textures.values():
		if texture is Array:
			for frame in texture: assert(frame is Texture2D,"normal frame exported")
		else: assert(texture is Texture2D,"soldier boss soul and menu art exported")
	for key in ["menu","screens","route"]: assert(expedition.approved[key].get_size()==Vector2(1536,1024),"approved UI reference exported")
	assert(expedition.textures["10R"].get_width()==1920,"large final boss sheet exported")
	for asset in ["res://art/aquarium/tank_clean.png","res://art/ui/aquarium/manage.png","res://art/ui/aquarium/expand.png"]:
		assert(load(asset) is Texture2D,"aquarium asset exported")
	for name in ["heart","leaf","star","check","right","close","fish","plus","rod","soldier","soul0","soul1","soul2","soul3","soul4","region0","region1","region2","region3","region4","region5"]:
		var texture=load("res://art/ui/codex/%s.png"%name)
		assert(texture is Texture2D and texture.get_size()==Vector2(32,32),"codex PixelLab asset exported: "+name)
	assert(load("res://art/ui/capture_robot_b/motions.png").get_size()==Vector2(1440,240),"B robot motion atlas exported")
	for asset in ["sleep","capture","success","full","workshop","speed","storage","precision"]:
		assert(load("res://art/ui/capture_robot_b/%s.png"%asset) is Texture2D,"robot status art exported")
	for key in expedition.management.SKILLS:
		var icon=load("res://art/ui/soldier_skills/%s.png"%key)
		assert(icon is Texture2D and icon.get_size()==Vector2(64,64),"PixelLab skill icon exported: "+key)
	for id in 15:
		var spec:Dictionary=expedition.data.catalog.soldiers[id]
		assert(expedition.frame_count(id,2)==(13 if spec.id=="puffer" else 15),"tier2 frames packed")
		assert(expedition.textures[spec.id+"_tier2"] is Texture2D,"tier2 atlas packed")
	print("PACKED_ANGLER_VERIFY failures=[]")
	quit()
