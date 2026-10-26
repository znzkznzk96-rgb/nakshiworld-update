extends SceneTree
func _initialize() -> void:
	var helper=load("res://addons/expedition/opaque_body.gd")
	DirAccess.make_dir_recursive_absolute("res://art/expedition/prepared")
	var items: Array=[]
	for i in range(1,19):
		for j in 7: items.append(["normal%02d_%d.png"%[i,j],128])
	for id in ["3R","5R","7R","10R"]: items.append(["boss%s.png"%id,320 if id=="10R" else 224])
	for item in items:
		var source=load("res://art/expedition/"+item[0])
		var result: Texture2D=helper.prepare(source,item[1],false)
		if result.get_image().save_png("res://art/expedition/prepared/"+item[0])!=OK:
			push_error("Bake failed: "+item[0]);quit(1);return
	print("EXPEDITION_BAKE files=",items.size());quit()
