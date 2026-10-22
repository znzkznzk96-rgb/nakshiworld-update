extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;m.title_open=false;root.add_child(m);await process_frame;m.set_process(false)
	var e=m.environment
	check(e.texture.get_size()==Vector2(803,1959),"immutable approved plate dimensions")
	check(e.layers.size()==12,"independent bounded environment layers")
	for size in [Vector2i(270,660),Vector2i(270,540),Vector2i(270,480),Vector2i(360,660)]:
		root.size=size;await process_frame;m.active_region=0;m._layout()
		check(is_equal_approx(m.bg_node.scale.x,m.bg_node.scale.y),"uniform plate scale "+str(size))
		check(m.SURF==roundi(e.point(Vector2(0,e.DECK_Y)).y),"deck coordinate "+str(size))
		check(m.PY+57==m.SURF and m.CATY+32==m.SURF,"actor feet on deck")
		check(m.WATER>m.SURF and m.uw_bot>m.WATER+45,"playable underwater height")
	e.set_hour(12);check(is_zero_approx(e.night_strength()),"day emissives off")
	e.set_hour(22);check(is_equal_approx(e.night_strength(),1.0),"night emissives on")
	e.set_hour(6.5);check(e.night_strength()>0.2 and e.night_strength()<0.8,"dawn smoothly fades")
	e.set_hour(18.5);check(e.night_strength()>0.2 and e.night_strength()<0.8,"dusk smoothly fades")
	var saved: float=e.day_seconds;e.update(0.25);check(is_equal_approx(e.day_seconds,saved+0.25),"existing game clock")
	seed(196);var expected:=randf();seed(196);e.update(1.0);check(randf()==expected,"animation does not perturb catch RNG")
	for i in 11:
		for t in [0.0,12.0,60.0,1200.0]:
			var p: Vector2=e.layers.bubbles.bubble_position(i,t)
			check(p.y>e.WATER_Y and p.y<e.SAND_Y and p.x>200 and p.x<740,"bubble stays in water")
	check(e.layers.sand_fish.burial(12)==0 and e.layers.sand_fish.burial(35)==1 and e.layers.sand_fish.burial(50)==0,"buries and returns")
	check(e.layers.clouds.cloud_x(0,30)>e.layers.clouds.cloud_x(0,0),"cloud drift")
	m.active_region=1;m._layout();check(not m.bg_node.visible and not e.moon.visible,"valley hides reservoir plate/moon")
	for kind in e.layers:check(not e.layers[kind].visible,"valley hides "+kind)
	m.active_region=0;m._layout();e.show_scene(false)
	for kind in e.layers:check(not e.layers[kind].visible,"menus hide "+kind)
	print("RESERVOIR_LAYERS_VERIFY failures=",failures)
	m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
