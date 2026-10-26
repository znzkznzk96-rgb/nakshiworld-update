extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func prepare(m,behavior: String,press: bool) -> void:
	m.active_region=0;m.start_wait();m.S.star=1;m.S.sp=6;m.S.grade=0;m.start_fight()
	m.S.tut=false;m.S.lesson="";m.S.beh=behavior;m.S.bt=10.0;m.S.dist=20.0;m.S.tension=20.0;m.S.slack=0.0;m.S.chaos=0.0;m.S.noise=1.0;m.S.jumpT=0.4;m.holding=press
func run() -> void:
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.development_preview=true;m.TUT.done=true;m.title_open=false
	prepare(m,"swim",false)
	seed(1023)
	for region in 2:
		m.active_region=region
		for sp in 20:
			for star in 5:
				var pool: Array=m.early_action_pool(region,sp+region*20,star)
				check(pool.size()<=2 if star<4 else pool.size()<=3,"bounded species pool")
				for grade in 5:
					m.S.sp=sp+region*20;m.S.star=star;m.S.grade=grade
					for i in 12:
						m.next_behavior()
						check(m.S.beh in pool or m.S.beh in ["swim","rest"],"grade cannot add hidden move")
						if m.S.beh in pool: check(m.S.bt>=0.8 and m.S.bt<=1.1,"readable warning")
						check(not m.S.fakeTell and not m.S.fakeRest and not m.S.chain,"no early fake/chain")
	for pair in [["tell","run",0.9],["turn","charge",1.5],["rise","jump",1.2],["nose","dive",1.05]]:
		prepare(m,pair[0],false);m.S.bt=0.0;m.update_fight(0.01)
		check(m.S.beh==pair[1] and m.S.bt>=pair[2],"warning transitions to longer action "+pair[0])
	prepare(m,"jump",false);m.S.bt=0;m.update_fight(.01)
	check(m.S.beh=="rest" and is_equal_approx(m.S.landUntil-m.clock,.5),"landing window never overlaps attack")
	for behavior in ["run","dive","jump"]:
		prepare(m,behavior,true);m.update_fight(.1);var bad: float=m.S.tension
		prepare(m,behavior,false);m.update_fight(.1)
		check(bad>20 and m.S.tension<20,"wrong reeling raises danger; release recovers "+behavior)
	prepare(m,"charge",true);m.update_fight(.1);check(m.S.tension<20 and m.S.slack==0,"correct charge reeling stays safe")
	prepare(m,"run",false)
	for i in 180: m.update_fight(1.0/60)
	check(m.S.phase=="fight","release survives long run")
	var prev:=1.0
	for v in 101:
		var col: Color=m.tension_line_color(v);check(col.g<=prev+.0001,"continuous danger color");prev=col.g
	check(m.tension_line_color(65).g<.3 and m.tension_line_color(85).g<.1,"red visible before critical")
	check(m.pose_for("tell",0,0).curl<m.pose_for("turn",0,0).curl-.4,"warning silhouettes distinct")
	print("ACTION_READABILITY_VERIFY failures=",failures)
	m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
