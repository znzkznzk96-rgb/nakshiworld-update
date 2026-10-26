extends SceneTree
var failures: Array = []
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m = load("res://main.gd").new()
	m.SET.sfx=0;m.SET.music=0;m.title_open=false;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false
	# 2x demonstration speed: airborne does not instruct tap; only landing does.
	for elapsed in [1.7,2.1,2.9,3.39]:
		var frame = m.lesson_frame("jump",elapsed)
		check(frame.beh == "jump" and "탭" not in frame.cue, "airborne release at %f" % elapsed)
	check(m.lesson_frame("jump",3.41).cue == "착수! 지금 탭", "landing starts tap window")
	check(m.lesson_frame("jump",6.61).cue == "다시 감기", "landing window ends")
	check("손 떼기" in m.lesson_frame("tell",1.2).cue, "release during crouch telegraph")
	check("지금 감기" in m.lesson_frame("skim",2.81).cue, "skim stopped bonus")
	check(m.lesson_frame("jump",5.5).beh == "land", "landing remains slow for reading")
	check(m.measurement_tick(12.5)=="12.5" and m.measurement_tick(50)=="50", "numeric ruler labels")
	for sp in m.FISH_NAME.size():
		var u: Rect2 = Rect2(m.fish_used[sp])
		check(m.measurement_width(sp) * u.size.y / u.size.x <= 130.01, "proportional fish fits measurement area")
	m.S={"phase":"idle","sp":3}
	check(m.measurement_max_cm(3)==20.0,"loach fixed 20cm ruler")
	check(m.measurement_x(10.0)==135.0,"10cm loach occupies half ruler")
	for sp in 20: check(m.species_max_cm(sp)<=150.0,"reservoir cap")
	m.mailbox.read_ids=[];m.mailbox.deleted_ids=[]
	var ids: Array=[]
	for letter in m.mailbox.visible_letters():
		check(letter.id not in ids,"unique mail "+letter.id);ids.append(letter.id)
	check(ids[0]=="0.77" and "0.76" in ids and "0.75" in ids and "0.72" in ids and "0.71" in ids and "0.70" in ids and "0.69" in ids and "0.61" in ids and "0.63" in ids,"release mail backfill")
	m.mailbox.read_ids=["0.64"];m.mailbox.deleted_ids=["0.63"];m._save_game()
	m.mailbox.read_ids=[];m.mailbox.deleted_ids=[];m._load_game()
	check("0.64" in m.mailbox.read_ids and "0.63" in m.mailbox.deleted_ids,"mail state persists")
	check(m.mailbox.visible_letters().all(func(l): return l.id != "0.63"),"deleted mail stays deleted")
	for tab in 5:
		m.guide.tab=tab
		for topic in 3:
			m.guide.topic=topic;m.ui_commands=[];m.text_items=[];m.guide.draw(m,540)
			check(m.guide.content(m).size()>0,"guide content")
			for item in m.text_items: check(item[1].y < 540,"guide fits short viewport")
	m.guide.opened=true;m.S={"phase":"fight","dist":31.0};m._process(0.05)
	check(m.S.dist==31.0,"guide pauses fight")
	m.guide.draw_button(m);m.mailbox.draw_button(m)
	check(not m.guide.button.intersects(m.mailbox.button),"separate icon touch targets")
	print("GUIDE_VERIFY failures=",failures)
	m.S={"phase":"idle"};m.scene="village";m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
