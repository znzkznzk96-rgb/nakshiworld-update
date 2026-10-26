extends SceneTree
func _initialize() -> void:
	var failures: Array=[];var helper=load("res://addons/expedition/opaque_body.gd")
	var items: Array=[]
	for i in range(1,19):
		for j in 7: items.append(["normal%02d_%d.png"%[i,j],128])
	for id in ["3R","5R","7R","10R"]: items.append(["boss%s.png"%id,320 if id=="10R" else 224])
	for item in items:
		var path: String="res://art/expedition/prepared/"+item[0]
		if not ResourceLoader.exists(path): failures.append("missing "+path);continue
		var original=load("res://art/expedition/"+item[0])
		var expected: Image=helper.prepare(original,item[1],false).get_image()
		var actual: Texture2D=helper.prepare(original,item[1])
		var image: Image=actual.get_image();image.convert(Image.FORMAT_RGBA8)
		if image.get_data()!=expected.get_data(): failures.append("pixels changed "+path)
		if actual.resource_path!=path: failures.append("runtime fallback "+path)
	print("STARTUP_ASSETS_VERIFY failures=",JSON.stringify(failures));quit(0 if failures.is_empty() else 1)
