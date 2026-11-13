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
		var expected_size:=Vector2(48,40) if name.begins_with("region") else Vector2(32,32)
		if not (texture is Texture2D) or texture.get_size()!=expected_size:
			push_error("Packed codex asset missing or wrong size: "+name+" expected "+str(expected_size))
			quit(1);return
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
		assert(expedition.frame_count(id,3)==(13 if spec.id=="puffer" else 15),"tier3 frames packed")
		assert(expedition.textures[spec.id+"_tier3"] is Texture2D,"tier3 atlas packed")
	var gift108=load("res://addons/reservoir/valley_gift108.gd")
	assert(gift108.ID=="valley-once-20261107-108" and gift108.GOLD_AMOUNT==1000000,"one-time valley gift script exported")
	var expected_version: String=OS.get_cmdline_user_args()[1]
	if load("res://addons/reservoir/release_notes.gd").LETTERS[0].id!=expected_version:
		push_error("Packed release mail does not match "+expected_version);quit(1);return
	var decor=load("res://addons/reservoir/tile_scenery.gd").new()
	for name in ["cloud-00","cloud-01","cloud-02","cloud-03","mist","support","arch-vine","floor-ribbon","floor-broad","wall-ribbon","bubble-cluster","water-specks"]:
		assert(load("res://art/atmosphere/tile/"+name+".png") is Texture2D,"tile scenery packed: "+name)
	for i in 9: assert(decor.read_image("res://art/atmosphere/tile/gull-flight-%02d.png"%i).get_size()==Vector2i(80,80),"imported gull decoded in actual PCK")
	for shader in ["tile_cloud_family","tile_mist_soft","tile_support_depth","tile_dream_tone"]:assert(load("res://addons/reservoir/"+shader+".gdshader") is Shader,"tile shader packed")
	decor.free()
	print("PACKED_ANGLER_VERIFY failures=[]")
	quit()
