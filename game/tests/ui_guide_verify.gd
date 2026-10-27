extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m=load("res://main.gd").new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
	m.title_open=false;m.trans={};m.scene="village";m.TUT.done=true;m.lesson_open=false;m.market_open=false;m.settings_open=false;m.V.shop=""
	for height in [480,660]:
		root.content_scale_size=Vector2i(270,height);root.size=Vector2i(540,height*2);await process_frame
		m._draw_menu(height-m.bot_pad-99);m.mailbox.draw_button(m);m.guide.draw_button(m)
		check(not m.mailbox.button.intersects(m.ui_rects.menu) and not m.guide.button.intersects(m.mailbox.button),"bottom tool hitboxes separated")
		check(m.mailbox.button.position.y>m.top_y+100 and m.guide.button.end.y<height-m.bot_pad-57,"tools outside header and navigation")
		m.mailbox.opened=false;m.guide.opened=false;m.press(m.mailbox.button.get_center());check(m.mailbox.opened,"mail opens at new position")
		m.mailbox.opened=false;m.press(m.guide.button.get_center());check(m.guide.opened,"guide opens at new position");m.guide.opened=false
	var Reader=load("res://addons/reservoir/topic_reader.gd")
	for letter in m.mailbox.letters:
		m.mailbox.detail=letter.id;m.mailbox.full_text=false;m.mailbox.detail_page=0;m.mailbox.draw(m,480)
		check(m.mailbox.rects.has("toggle") and m.mailbox.rects.has("back"),"all letters have detail and return controls")
		m.mailbox.press(m,m.mailbox.rects.toggle.get_center());check(m.mailbox.full_text,"summary opens original detail")
		var pages: Array=Reader.pages(m,letter.body);var rebuilt:=""
		for p in pages.size():
			m.mailbox.detail_page=p;m.text_items=[];m.mailbox.draw(m,480)
			for line in pages[p]:
				rebuilt+=line
				check(m.text_items.any(func(it):return str(it[2])==str(line)),"every original paragraph is rendered")
			check(m.mailbox.rects.back.end.y<=460,"footer fits small screen")
		check(rebuilt=="".join(letter.body),"archive exact text preserved")
		m.mailbox.press(m,m.mailbox.rects.toggle.get_center());check(not m.mailbox.full_text and m.mailbox.detail_page==0,"return to summary resets page")
		if letter.id=="0.78":
			m.mailbox.draw(m,480);check(m.mailbox.rects.gift.position.y>=m.mailbox.rects.toggle.end.y,"gift does not overlap navigation")
	m.mailbox.detail="0.78";m.mailbox.draw(m,480);m.testing_grants=[];m.development_preview=false
	m.mailbox.press(m,m.mailbox.rects.gift.get_center());var gold: int=m.gold
	m.mailbox.press(m,m.mailbox.rects.gift.get_center());check(m.gold==gold and not m.testing_grants.is_empty(),"mail gift remains one-time through real handler");m.development_preview=true
	var contents:=""
	for t in m.guide.TABS.size():
		m.guide.tab=t
		for topic in m.guide.TOPICS[t].size():
			m.guide.topic=topic;contents+=" ".join(m.guide.content(m));m.guide.draw(m,480)
			for i in m.guide.rects.tabs.size():
				for j in range(i+1,m.guide.rects.tabs.size()): check(not m.guide.rects.tabs[i].intersects(m.guide.rects.tabs[j]),"guide category targets do not overlap")
	for word in ["유니크 +2%","전설 +3%","신화 +5%","어혼 주머니","병사 합성","35%","유니크 20%","가방 → 인벤토리"]:check(word in contents,"current guide covers "+word)
	check("_aquarium_life" not in FileAccess.get_file_as_string("res://village.gd"),"exterior overlay renderer removed")
	print("UI_GUIDE_VERIFY failures=",failures)
	m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
