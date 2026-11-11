extends SceneTree
func _initialize()->void:
	assert(ProjectSettings.load_resource_pack(OS.get_cmdline_user_args()[0]))
	assert(FileAccess.file_exists("res://art/rift/catalog.json"),"approved metadata included in PCK")
	var art=load("res://addons/reservoir/rift_art.gd").new();art.setup()
	assert(art.catalog.size()==20)
	for i in 3:assert(load("res://art/rift/rock_%d.png"%i).get_size()==Vector2(128,128),"floating rock exported")
	assert(load("res://art/rift/glow_mask.png").get_size()==Vector2(1080,2640),"thin crack mask packed")
	assert(load("res://art/rift/boat.png").get_size()==Vector2(360,450),"separate transparent boat packed")
	var p=load("res://addons/reservoir/regional_progress.gd").new()
	assert(p.bundle_targets(3,0).size()==6 and p.reward_gold(3,1)==3015000 and p.reward_gold(3,2)==9045000,"rift bundles and next-fee rewards packed")
	assert(load(art.BACKGROUND).get_size()==Vector2(1080,2640))
	for sp in range(60,80):
		assert(art.texture(sp) is Texture2D)
		assert(art.source_rect(sp,0).size.x>0)
	assert(load("res://addons/reservoir/regional_catalog.gd").NAMES.size()==60,"no speculative gameplay")
	print("PACKED_RIFT_ART_VERIFY failures=[] species=20")
	quit()
