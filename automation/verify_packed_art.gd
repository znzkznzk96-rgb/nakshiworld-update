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
	print("PACKED_ANGLER_VERIFY failures=[]")
	quit()
