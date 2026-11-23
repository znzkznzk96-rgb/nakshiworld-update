extends SceneTree
# 헤드리스 검증
func _init() -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 7
	# 1) 등급별 결과 생성이 항상 그 등급의 줄 하나만 만든다
	var bad := 0
	for g in 7:
		for i in 300:
			var info := SlotMachine.evaluate(SlotMachine.make_grid(g, rng))
			if info.top != g or info.lines.size() != 1: bad += 1
	print("CHECK1 grid_bad=", bad, " of 2100")
	var jp := SlotMachine.evaluate(SlotMachine.make_grid(6, rng, true))
	print("CHECK2 jackpot=", jp.jackpot, " lines=", jp.lines.size())
	# 2) 한 판 진행이 끝나고 결과 정보가 나온다 (SS, SSS)
	var main = load("res://test_main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for g in [0, 5, 6]:
		var got := {}
		main.machine.finished.connect(func(i): got.assign(i), CONNECT_ONE_SHOT)
		main.pull(g)
		await main.machine.finished
		print("CHECK3 grade=", g, " top=", got.get("top"), " busy=", main.machine.busy)
	# 4) 효과음 신호: 한 판에 레버·회전·릴 정지 3번·당첨·등장이 순서대로 나온다
	var names: Array = []
	main.machine.sfx.connect(func(n): names.append(n))
	main.pull(3)
	await main.machine.finished
	print("CHECK4 sfx=", names)
	quit()
