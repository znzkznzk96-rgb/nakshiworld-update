extends SceneTree
# 헤드리스 검증: 정해 준 결과로 돌려서 signal 결과가 같은지, skip이 즉시 끝내는지 확인
func _init() -> void:
	var main = load("res://test_main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var want := [[0,1,2],[3,4,5],[6,5,4]]
	var got := []
	main.reels.spin_finished.connect(func(r): got.assign(r))
	var stops := []
	main.reels.reel_stopped.connect(func(c): stops.append(c))
	main.reels.runtime = 0.3; main.reels.reel_delay = 0.1
	main.reels.spin(want)
	await main.reels.spin_finished
	print("CHECK1 result_ok=", got == want, " stops=", stops)
	# 정지 위치: 각 릴 strip이 y=0이어야 결과 행이 창에 맞는다
	var ys := []
	for s in main.reels._strips: ys.append(s.position.y)
	print("CHECK2 strip_y=", ys)
	got.clear(); stops.clear()
	main.reels.runtime = 5.0
	main.reels.spin(want)
	await process_frame
	main.reels.skip()
	print("CHECK3 skip_ok=", got == want, " spinning=", main.reels.spinning, " stops=", stops)
	quit()
