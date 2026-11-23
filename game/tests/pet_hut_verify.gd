extends SceneTree
# 펫 오두막: 마을 배치·열기·저장 연결 검증 (실행: godot --headless --path game --script tests/pet_hut_verify.gd)
var failures: Array=[]
var total := 0
func check(ok: bool,label: String) -> void:
	total += 1
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;m.title_open=false;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false;m.scene="village"
	var V=m.V
	check(V.BUILD.size()==8 and V.BUILD[7][1]=="pet" and V.MAP_W>=V.BUILD[7][2].end.x+40,"건물 8개, 오두막이 지도 안에 있음")
	check(V.tex.has("pet") and V.tex.pet.get_size()==Vector2(140,125),"오두막 그림 로드")
	for i in 7: check(not V.BUILD[i][2].intersects(V.BUILD[7][2]),"기존 건물과 겹치지 않음 %d" % i)
	# 건물을 눌러 열기
	V.camera_x=1530.0;V.zoom=1.0
	m.pearl=45;m.pet_hut={"c":{"b_hamster":2,"ss_golem":1},"e":["b_hamster"],"l":"b_hamster","f":10,"s":0.0,"t":Time.get_unix_time_from_system()}
	V.open_shop(m,"pet")
	await process_frame
	check(V.shop=="pet" and V.hut!=null and is_instance_valid(V.hut),"펫 오두막 창 열림")
	check(V.hut.pearl_total==45 and V.hut.frags==10 and V.hut.equipped==["b_hamster"],"저장 상태 불러옴")
	# 창 안에서 동작 → 게임 진주·저장 상태 반영
	V.hut.tab="box";V.hut.queue_redraw();V.draw_shop(m,540.0);await process_frame
	V.hut.press(V.hut.rects["bx:ss_golem"].get_center());await process_frame
	V.hut.press(V.hut.rects["bx_equip"].get_center())
	check(V.hut.equipped==["b_hamster","ss_golem"] and m.pet_hut.get("e",[])==["b_hamster","ss_golem"],"장착이 즉시 게임 저장 데이터에 반영")
	V.hut.pearl_total=60;V.hut.state_changed.emit()
	check(m.pearl==60,"진주가 게임 진주와 동기화")
	# 닫기
	V.hut.closed.emit();await process_frame
	check(V.shop=="" and V.hut==null,"닫으면 마을로 돌아옴")
	# 비어 있는 상태(새 게임)로 열어도 문제없음
	m.pet_hut={};V.open_shop(m,"pet");await process_frame
	V.draw_shop(m,540.0);V.hut.queue_redraw();await process_frame
	check(V.hut.equipped.is_empty() and V.hut.counts.is_empty() and V.hut.get_leader()=="","새 게임은 빈 상태")
	for t in ["pets","box","gacha","plans"]:
		V.hut.tab=t;V.hut.queue_redraw();await process_frame
	V.hut.closed.emit();await process_frame
	# 오프라인 진주: 12시간 상한, 시계를 과거로 돌리면 쌓이지 않음
	var now: float=Time.get_unix_time_from_system()
	var u=load("res://addons/reservoir/pet_hut/pet_hut_ui.gd").new()
	var base={"c":{"ss_golem":1},"e":["ss_golem"],"l":"ss_golem","f":0,"s":0.0}
	u.restore(base.merged({"t":now-7200.0}),now);check(absf(u.stored-3.2)<0.01,"2시간 오프라인 = 시간당 1.6 × 2")
	u.restore(base.merged({"t":now-100.0*3600.0}),now);check(absf(u.stored-19.2)<0.01,"오프라인은 12시간까지만")
	u.restore(base.merged({"t":now+5000.0}),now);check(u.stored==0.0,"시계를 과거로 돌리면 쌓이지 않음")
	u.restore({"c":{"nope":3,"d_chick":-2},"e":["nope","d_chick"],"l":"x","f":-5,"s":-1.0,"t":now},now);check(u.counts.get("nope",0)==0 and u.equipped.is_empty() and u.frags==0 and u.stored==0.0,"잘못된 저장값 정리")
	u.free()
	# 저장 파일에 포함됨
	m.progress_loaded=true;m.pet_hut={"c":{"d_chick":1}}
	var ok: bool=m._save_game()
	var txt:=FileAccess.get_file_as_string("user://save.json")
	check(ok and txt.find("pet_hut")>=0,"세이브에 pet_hut 저장")
	print("통과 %d/%d, 실패 %d" % [total-failures.size(),total,failures.size()])
	quit(0 if failures.is_empty() else 1)
