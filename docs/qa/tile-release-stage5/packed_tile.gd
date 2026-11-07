extends SceneTree
func _initialize() -> void:
	var path: String=OS.get_cmdline_user_args()[0]
	assert(ProjectSettings.load_resource_pack(path),"load exported v107 pack")
	var env=load("res://addons/reservoir/tile_environment.gd")
	assert(env.PLATE_PATH=="res://art/bg/tile_sea_approved_20261107.png")
	var bg=load(env.PLATE_PATH)
	assert(bg is Texture2D and bg.get_size()==Vector2(801,1962),"approved background exported at original dimensions")
	assert(not ResourceLoader.exists("res://art/bg/tile_sea_clean.png"),"deleted damaged legacy path excluded")
	for i in 20:
		var tex=load("res://art/fish/l2_%02d.png"%i)
		assert(tex is Texture2D and tex.get_size()==Vector2(96,64),"approved tile fish exported")
	var catalog=load("res://addons/reservoir/regional_catalog.gd")
	assert(catalog.NAMES.size()==60 and catalog.by_star(2,4)==[59] and catalog.by_star(3,0).is_empty(),"tile catalog and future boundary exported")
	var entry=load("res://addons/reservoir/region_shop.gd").new()
	assert(entry!=null,"regional unlock system exported")
	print("PACKED_TILE107_VERIFY failures=[]")
	quit()
