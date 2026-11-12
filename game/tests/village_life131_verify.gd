extends SceneTree
var failures: Array = []
func check(ok: bool, label: String) -> void:
	if not ok and label not in failures: failures.append(label);push_error(label)
func actor() -> Dictionary:
	return {"x":350.0,"state":0,"wait":0.0,"speed":32.0,"velocity":0.0,"step":0.0,"lane":0.0,"group":2,"pause_at":600.0,"paused":false,"reward_t":0.0}
func _initialize() -> void:
	var now = load("res://addons/reservoir/visitors.gd").new()
	var before = load("res://tests/visitor_motion131_baseline.gd").new()
	# Decoration must not change the passenger timeline that drives aquarium payouts.
	var expected: Array = []
	var r := actor();seed(131)
	for frame in 6000:
		before.update(r, 1.0 / 30.0)
		expected.append([r.x,r.state,r.wait,r.velocity,r.step])
	r = actor();seed(131);now.motion_rng.seed = 12
	var lane_min := 100.0;var lane_max := -100.0
	for frame in 6000:
		now.update(r, 1.0 / 30.0)
		check([r.x,r.state,r.wait,r.velocity,r.step] == expected[frame], "passenger economic timeline preserved")
		if r.x > 370:
			lane_min = minf(lane_min, r.lane);lane_max = maxf(lane_max, r.lane)
	check(lane_max - lane_min > 3.0, "passenger Y changes over route")
	for index in 32:
		r = actor();r.state=3;r.x=470.0;r.local_min=370.0;r.local_max=570.0;r.local_dir=1.0
		var min_y := 100.0;var max_y := -100.0
		for frame in 1800:
			var last: float=r.lane;var waiting: bool=r.wait>0
			now.update(r, 1.0 / 30.0)
			check(r.x>=370 and r.x<=570,"local stays within walk area")
			check(r.lane>=-7.001 and r.lane<=3.001,"local lane inside dirt path")
			check(absf(float(r.lane)-last)<=0.061,"no vertical teleport or jitter")
			if waiting: check(r.lane==last,"standing residents do not drift")
			min_y=minf(min_y,r.lane);max_y=maxf(max_y,r.lane)
		check(max_y-min_y>2.0,"each local explores different Y destinations")
	var v = load("res://village.gd").new()
	for x in [100.0,191.0,270.0]:
		check(v.visitor_y({"x":x})==22.0,"boarding deck height preserved")
	for x in [370.0,900.0,1500.0]:
		check(v.visitor_y({"x":x})==14.0,"village people raised inside path")
	print("VILLAGE_LIFE131_VERIFY failures=",failures," timeline_frames=6000 local_frames=57600")
	quit(0 if failures.is_empty() else 1)
