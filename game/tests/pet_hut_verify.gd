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
	# 대표 펫 능력
	check(PetEffects.leader({"e":["a","b"],"l":"b"})=="b" and PetEffects.leader({"e":["a","b"],"l":"z"})=="a" and PetEffects.leader({})=="","대표 결정(없으면 첫 장착)")
	m.pet_hut={"e":["a_fennec","sss_lunar"],"l":"a_fennec"}
	check(absf(m.pet_fx("bite_wait")-0.08)<0.0001 and m.pet_fx("income_all")==0.0,"대표 1마리 능력만 적용(사막여우)")
	m.pet_hut={"e":["a_fennec","sss_lunar"],"l":"sss_lunar"}
	check(absf(m.pet_fx("income_all")-0.10)<0.0001 and m.pet_fx("bite_wait")==0.0,"대표를 바꾸면 능력도 바뀜")
	m.pet_hut={}
	check(m.pet_fx("bite_wait")==0.0 and m.pet_fx("tension")==0.0,"펫이 없으면 효과 없음")
	m.aqua=[{"sp":1,"star":0,"grade":0,"len":10.0,"w":0.1,"price":300},{"sp":2,"star":1,"grade":0,"len":10.0,"w":0.1,"price":300},{"sp":3,"star":2,"grade":0,"len":10.0,"w":0.1,"price":300}]
	var base_rate: float=m.aqua_rate()
	m.pet_hut={"e":["sss_lunar"],"l":"sss_lunar"};check(absf(m.aqua_rate()/base_rate-1.10)<0.001,"달의 여인: 전시 수입 +10%")
	m.pet_hut={"e":["s_fairy"],"l":"s_fairy"};check(absf(m.aqua_rate()/base_rate-(3.0+0.16)/3.0)<0.001,"숲 요정: ★1~2 수입 +8%")
	m.pet_hut={"e":["d_chick"],"l":"d_chick"};check(absf(m.aqua_rate()/base_rate-(3.0+0.02)/3.0)<0.001,"병아리: ★1 수입 +2%")
	check(PetEffects.boost_int(100,0.15,0.9)==115 and PetEffects.boost_int(10,0.05,0.4)==11 and PetEffects.boost_int(10,0.05,0.6)==10,"비늘조각 증가 계산")
	m.pet_hut={"e":["sss_demon"],"l":"sss_demon"};m.apply_pet_effects();check(absf(m.expedition.data.pet_atk-0.15)<0.0001,"악마: 용병 공격력 +15%")
	m.pet_hut={};m.apply_pet_effects();check(m.expedition.data.pet_atk==0.0,"대표 없으면 공격력 보너스 없음")
	m.region_shop.selected_bait=0;m.bait=5000;m.pet_hut={"e":["a_otter"],"l":"a_otter"}
	for i in 2000: m.region_shop.take_bait(m)
	var used: int=5000-m.bait;check(used>1700 and used<1900,"수달: 미끼 약 10%% 절약 (사용 %d/2000)" % used)
	m.bait=5000;m.pet_hut={}
	for i in 200: m.region_shop.take_bait(m)
	check(m.bait==4800,"펫이 없으면 절약 없음")
	m.S={"star":1,"grade":0,"tensionMul":1.0,"line":0,"locMul":1.0}
	m.pet_hut={};var full: float=m.shock_amount(1.0)
	m.S={"star":1,"grade":0,"tensionMul":1.0,"line":0,"locMul":1.0};m.pet_hut={"e":["a_owl"],"l":"a_owl"}
	var first: float=m.shock_amount(1.0);var second: float=m.shock_amount(1.0)
	check(absf(first/full-0.6)<0.001 and absf(second/full-1.0)<0.001,"부엉이: 첫 큰 충격만 -40%")
	m.pet_hut={}
	# 나머지 능력
	m.pet_hut={"e":["ss_golem"],"l":"ss_golem"}
	check(PetEffects.amp_count(m.pet_hut,0.02)==3 and PetEffects.amp_count(m.pet_hut,0.10)==2 and PetEffects.amp_count(m.pet_hut,0.5)==1,"골렘: 포획 증폭 ×3/×2/없음")
	m.pet_hut={"e":["s_wisp"],"l":"s_wisp"};check(PetEffects.amp_count(m.pet_hut,0.07)==2 and PetEffects.amp_count(m.pet_hut,0.09)==1,"도깨비불: ×2만")
	m.pet_hut={"e":["sss_demon"],"l":"sss_demon"};m.apply_pet_effects();check(absf(m.expedition.data.pet_boss-0.10)<0.0001,"악마: 보스 +10% 설정")
	m.pet_hut={"e":["ss_knight"],"l":"ss_knight"};m.apply_pet_effects();check(m.expedition.data.pet_cut==2 and absf(m.expedition.data.pet_atk-0.10)<0.0001,"기사: 첫 피해 -2·공격 +10%")
	m.pet_hut={};m.apply_pet_effects();check(m.expedition.data.pet_cut==0 and m.expedition.data.pet_boss==0.0,"대표 없으면 용병 효과 없음")
	var w0:=0.0;var w1:=0.0;var w2:=0.0;var w3:=0.0
	m.TUT.done=true
	m.pet_hut={"e":["ss_storm"],"l":"ss_storm"}
	for i in 60:
		m.pet_missed=false;m.bait=50;m.start_wait();w0+=m.S.biteAt-m.clock
		m.pet_missed=true;m.bait=50;m.start_wait();w1+=m.S.biteAt-m.clock
	check(w1/w0<0.85,"바람 정령: 놓친 직후 입질 대기 감소 (%.2f)" % (w1/w0))
	m.pet_hut={"e":["d_frog"],"l":"d_frog"}
	for i in 60:
		m.pet_missed=false;m.bait=50;m.start_wait();w3+=m.S.biteAt-m.clock
		m.pet_missed=true;m.bait=50;m.start_wait();w2+=m.S.biteAt-m.clock
	check(absf((w3-w2)/60.0-0.2)<0.12 and w2<w3,"개구리: 놓친 뒤 약 0.2초 단축 (%.2f)" % ((w3-w2)/60.0))
	m.pet_missed=false;m.pet_hut={}
	m.fail("테스트");check(m.pet_missed,"놓치면 pet_missed 켜짐")
	m.pet_hut={"e":["sss_apostle"],"l":"sss_apostle"};var up:=0;var hyp:=0
	for i in 300:
		m.pet_missed=false;m.bait=50;m.start_wait();m.S.star=1;m.S.grade=1;m.S.owner=false;m.S.len=10.0;m.start_catch();if int(m.S.grade)==2: up+=1
	for i in 300:
		m.pet_missed=false;m.bait=50;m.start_wait();m.S.star=1;m.S.grade=1;m.start_fight();if float(m.S.hypno)>0.0: hyp+=1
	check(up>90 and up<150,"사도: 승급 약 40%% (%d/300)" % up)
	check(hyp>45 and hyp<105,"사도: 최면 약 25%% (%d/300)" % hyp)
	m.bait=50;m.start_wait();m.S.star=1;m.S.grade=4;m.S.len=10.0;m.start_catch();check(int(m.S.grade)==4,"신화는 승급 안 함")
	m.bait=50;m.start_wait();m.S.star=4;m.S.grade=1;m.start_fight();check(float(m.S.hypno)==0.0,"★5는 최면 제외")
	m.pet_hut={"e":["s_tome"],"l":"s_tome"};var s0: int=m.souls
	for i in 300:
		m.bait=50;m.start_wait();m.S.star=1;m.S.grade=1;m.S.len=10.0;m.start_catch()
	check(m.souls-s0>15 and m.souls-s0<50,"마도서: 수동 성공 시 약 10%% +1 (%d/300)" % (m.souls-s0))
	m.pet_hut={}
	# 저장 파일에 포함됨
	m.progress_loaded=true;m.pet_hut={"c":{"d_chick":1}}
	var ok: bool=m._save_game()
	var txt:=FileAccess.get_file_as_string("user://save.json")
	check(ok and txt.find("pet_hut")>=0,"세이브에 pet_hut 저장")
	print("통과 %d/%d, 실패 %d" % [total-failures.size(),total,failures.size()])
	quit(0 if failures.is_empty() else 1)
