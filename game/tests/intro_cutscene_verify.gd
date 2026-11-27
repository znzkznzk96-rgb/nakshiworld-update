extends SceneTree
# 첫 실행 컷신: 5컷이 모두 오류 없이 돌고, 건너뛰기로 컷마다 넘어가며, 끝나면 finished가 한 번 온다.
var failures := []
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var intro: CanvasLayer = load("res://addons/reservoir/intro_cutscene.gd").new()
	var done := [0]
	intro.finished.connect(func(): done[0] += 1)
	root.add_child(intro)
	for c in 5:
		for i in 20: await process_frame
		if intro.idx != c: failures.append("cut%d not active (idx=%d)" % [c + 1, intro.idx])
		if not is_instance_valid(intro.cut) or intro.cut.get("t") == null: failures.append("cut%d not running" % [c + 1])
		elif float(intro.cut.get("t")) <= 0.0: failures.append("cut%d time not advancing" % [c + 1])
		if not intro._skip_visible(): failures.append("skip hidden in cut%d" % [c + 1])
		var ev := InputEventMouseButton.new(); ev.button_index = MOUSE_BUTTON_LEFT; ev.pressed = true; ev.position = intro.skip_rect.get_center()
		intro._on_input(ev)
	for i in 5: await process_frame
	if done[0] != 1: failures.append("finished count %d" % done[0])
	if is_instance_valid(intro) and not intro.is_queued_for_deletion(): failures.append("intro not freed")
	print("INTRO_CUTSCENE_VERIFY failures=", failures)
	quit()
