extends SceneTree
var failures: Array = []
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	seed(62)
	var m = load("res://main.gd").new()
	root.add_child(m)
	await process_frame
	m.set_process(false)
	var actions: = ["swim", "rest", "tell", "turn", "run", "charge", "dive", "thrash", "circle", "skim", "jump"]
	for grade in 5:
		for action in actions:
			m.S = {"phase": "fight", "grade": grade, "beh": action}
			m.aura = {"g": grade, "pts": [Vector2(160, 350), Vector2(145, 350), Vector2(130, 350)], "nrms": [Vector2.UP, Vector2.UP, Vector2.UP], "c": Vector2(145, 350), "hw": 6.0, "L": 30.0, "face": 1.0}
			m.parts.clear();m.spawn_acc = 0.0;m.water_spawn_acc = 0.0;m.reveal_pending = false
			for frame in 600:
				m._fx_update(1.0 / 60.0, frame * 1000.0 / 60.0)
				check(m.parts.size() <= 90, "budget grade=%d action=%s" % [grade, action])
				for p in m.parts: check(p.p.is_finite() and p.v.is_finite(), "finite particle")
			if grade == 0 and action != "jump": check(m.parts.size() > 0, "normal-grade water " + action)
	m.aura = {}
	check(m._fight_particle_visible({"kind": "drop", "p": Vector2(150, m.WATER - 12)}), "airborne splash retained")
	check(not m._fight_particle_visible({"kind": "bubble", "p": Vector2(150, m.WATER - 12)}), "bubble stays underwater")
	m.S = {"phase": "idle"};m.parts.clear()
	m._fx_update(1.0, 0.0)
	check(m.parts.is_empty(), "no idle fight particles")
	print("VISUAL_VERIFY failures=", failures)
	m.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
