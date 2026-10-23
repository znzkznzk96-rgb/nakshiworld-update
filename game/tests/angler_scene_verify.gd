extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok:failures.append(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var a=load("res://addons/reservoir/angler_scene.gd").new();a.setup()
	check(a.cats.idle.size()==48 and a.cats.look.size()==12 and a.cats.hop.size()==12,"new cat frame counts")
	for kind in ["look","hop"]:
		check(a.cats[kind][0].get_image().get_data()==a.cats.look[0].get_image().get_data(),kind+" same neutral start")
		check(a.cats[kind][11].get_image().get_data()==a.cats.look[0].get_image().get_data(),kind+" same neutral return")
	var max_error: float=0.0
	for i in 161:
		var u: float=i/160.0;var n: int=0
		while n<a.CAST.size()-2 and u>float(a.CAST[n+1][0]):n+=1
		var x: Array=a.CAST[n];var y: Array=a.CAST[n+1];var f: float=a.sm((u-float(x[0]))/(float(y[0])-float(x[0])))
		var near: Vector2=Vector2(x[1],x[2]).lerp(Vector2(y[1],y[2]),f)
		var angle: float=lerpf(x[3],y[3],f);var far: Vector2=near+Vector2.from_angle(deg_to_rad(angle))*12
		var front: Dictionary=a.solve(Vector2(66,80),near,deg_to_rad(angle+43),17,19)
		var rear: Dictionary=a.solve(Vector2(78,80),far,deg_to_rad(angle+43),16,19)
		max_error=maxf(max_error,maxf(front.error,rear.error));check(a.rod_point(near,angle,15,1).is_finite(),"finite curved tip")
	check(max_error<.0001,"161 casting positions remain reachable")
	check(a.SKINS.size()==6,"six shared-motion rod skins")
	for face in ["neutral","blink","focus","strain","joy","sad"]:check(a.textures["face-"+face]!=null,"face "+face)
	print("ANGLER_SCENE_VERIFY failures=",failures," max_reach_error=",max_error)
	quit(0 if failures.is_empty() else 1)
