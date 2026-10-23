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
	print("PACKED_ANGLER_VERIFY failures=[]")
	quit()
