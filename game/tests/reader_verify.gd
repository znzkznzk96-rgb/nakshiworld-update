extends SceneTree
var failures: Array=[]
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m=load("res://main.gd").new()
	m.SET.sfx=0;m.SET.music=0;m.title_open=false;root.add_child(m);await process_frame;m.set_process(false)
	var reader=load("res://addons/reservoir/topic_reader.gd")
	for letter in m.mailbox.letters:
		var remaining: Array=letter.body.duplicate()
		for group in m.mailbox.sections(letter):
			for line in group.body:
				check(line in remaining,"original mail item");remaining.erase(line)
			var rebuilt:=""
			for page in reader.pages(m,group.body):
				check(page.size()<=6,"bounded page")
				for line in page:
					rebuilt+=line;check(m._text_w(line,11)<=208,"wrapped width")
			check(rebuilt=="".join(group.body),"mail content preserved")
		check(remaining.is_empty(),"all mail items retained")
		m.mailbox.detail=letter.id
		for height in [480,540,600]:
			m.ui_commands=[];m.text_items=[];m.mailbox.draw(m,height)
			for item in m.text_items: check(item[1].y<height,"mail fits")
	for letter in m.mailbox.letters:
		for section in m.mailbox.sections(letter):
			for sheet in reader.pages(m,section.get("display",section.body)):
				check(sheet.size()<=6,"short visible page")
		var label=m._ui_wrap(letter.title,9,174,1)
		check("\n" not in label and m._text_w(label,9)<=174,"single-line mail label")
	check(m.mailbox.sections(m.mailbox.letters.filter(func(letter): return letter.id=="0.72")[0]).size()==3,"curated B three subjects")
	for tab in 5:
		m.guide.tab=tab
		for topic in 3:
			m.guide.topic=topic
			var pages=reader.pages(m,m.guide.content(m));var rebuilt:=""
			for page in pages:
				for line in page: rebuilt+=line
			check(rebuilt=="".join(m.guide.content(m)),"guide content preserved")
			for height in [480,540,600]:
				m.ui_commands=[];m.text_items=[];m.guide.draw(m,height)
				for item in m.text_items: check(item[1].y<height,"guide fits")
	m.guide.page=5;m.guide.press(m,m.guide.rects.tabs[0].get_center());check(m.guide.page==0,"tab resets page")
	m.mailbox.detail=m.mailbox.letters[0].id;m.mailbox.draw(m,540)
	m.mailbox.detail_page=5;m.mailbox.press(m,m.mailbox.rects.tabs[0].get_center());check(m.mailbox.detail_page==0,"mail tab resets page")
	print("READER_VERIFY failures=",failures)
	m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
