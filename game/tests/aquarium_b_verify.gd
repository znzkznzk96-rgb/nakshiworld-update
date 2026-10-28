extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func fish(i: int) -> Dictionary:
	return {"sp":i%20,"star":0,"grade":i%5,"len":23.5,"w":.01,"price":100,"shoulder":false}
func run() -> void:
	var m=load("res://main.gd").new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
	m.title_open=false;m.lesson_open=false;m.scene="village";m.trans={};m.S={"phase":"idle"};m.V.open_shop(m,"aqua")
	var v=m.V;var a=v.aquarium
	for h in [480,660]:
		for count in [0,4,20]:
			m.aqua_lv=4;m.aqua=[]
			for i in 20: m.aqua.append(fish(i) if i<count else null)
			var before: Array=m.aqua.duplicate(true);var rate: float=m.aqua_rate()
			for t in [0,17,72]:
				m.ui_clock=t;m.text_items=[];v.draw_shop(m,h)
				check(a.fish_rects.size()==count,"only owned fish displayed")
				for f in a.fish_rects: check(a.swim_bounds.grow(1).encloses(f[0]),"swimming sprite stays inside glass")
				for row in v.rects.rows:check(v.rects.panel.encloses(row[0]),"all interaction areas inside panel")
				check(m.aqua==before and m.aqua_rate()==rate,"rendering preserves specimens and income")
				check(v.rects.panel.end.y<=h-34,"comfortable bottom UI margin")
				check(a.room_bounds==Rect2(13,m.top_y+159,244,h-m.top_y-312),"tank rectangle unchanged from v0.88")
				check(not v.rects.rows.any(func(row):return row[1]=="aexpand"),"maximum capacity cannot expand")
	m.ui_commands=[];a.effects_enabled=false;v.draw_shop(m,660)
	var plain: int=m.ui_commands.size()
	m.ui_commands=[];a.effects_enabled=true;v.draw_shop(m,660)
	check(m.ui_commands.size()>plain+50,"plants light and bubbles are separate draw layers")
	check(a.icon_cache.has("manage") and a.icon_cache.has("expand"),"both PixelLab button icons load")
	m.aqua_lv=2;m.aqua=[]
	for i in 10:m.aqua.append(fish(i) if i<4 else null)
	m.gold=0;v.draw_shop(m,660)
	var expand: Array=v.rects.rows.filter(func(row):return row[1]=="aexpand")[0]
	m.press(expand[0].get_center());v.commerce.confirm(v,m);check(m.aqua_lv==2 and m.gold==0,"unaffordable expansion keeps level and money")
	v.commerce.pending={};m.gold=10000;m.development_preview=false;v.draw_shop(m,660);m.press(expand[0].get_center());check(not v.commerce.pending.is_empty(),"expansion opens purchase confirmation");v.commerce.confirm(v,m)
	check(m.aqua_lv==3 and m.gold==7600 and m.aqua_count()==4,"expansion uses existing cost and keeps fish")
	m._load_game();check(m.aqua_lv==3 and m.aqua_count()==4,"expansion and specimens persist")
	m.development_preview=true;v.draw_shop(m,660)
	var hit: Array=a.fish_rects[0];a.act(v,m,"afish:%d"%hit[1]);m.text_items=[];v.draw_shop(m,660)
	check(m.text_items.any(func(it):return m.FISH_NAME[int(m.aqua[hit[1]].sp)] in str(it[2])),"selected specimen name visible")
	var manage: Array=v.rects.rows.filter(func(row):return row[1]=="amanage")[0]
	m.press(manage[0].get_center());check(v.aqua_manage,"new manage button opens existing transfer view")
	v.draw_shop(m,480);check(a.fish_rects.is_empty() and a.viewport.size.y>0,"manage has no stale fish hitboxes")
	print("AQUARIUM_B_VERIFY failures=",failures)
	m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
