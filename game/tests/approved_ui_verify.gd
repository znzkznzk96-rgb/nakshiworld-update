extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false
	var v=m.expedition;var d=v.data
	check(m.MENU.map(func(x):return x[0])==["village","bag","book","explore","alchemy","gear"],"approved six menu order")
	check(v.textures.explore is AtlasTexture and v.textures.alchemy is AtlasTexture,"approved icon reference reused, no SVG substitute")
	check(v.approved.menu.get_size()==Vector2(1536,1024) and v.approved.route.get_size()==Vector2(1536,1024),"approved reference dimensions")
	check(v.CARD_REGIONS.size()==10 and v.ROOM_REGIONS.size()==10,"ten distinct approved room regions")
	d.restore({});d.add_unit(0);d.add_unit(3);d.add_unit(6);d.team=[1,2,3]
	v.open(m,"explore");v.rects={"slot:1":Rect2(0,0,20,20)};v.press(m,Vector2(10,10))
	check(v.choosing_slot==1 and d.team==[1,2,3],"slot tap opens roster without silently removing soldier")
	v.rects={"unit:3":Rect2(0,0,20,20)};v.press(m,Vector2(10,10))
	check(d.team==[1,3,2] and v.choosing_slot==-1,"selecting existing soldier swaps position")
	v.choosing_slot=0;v.rects={"remove_slot":Rect2(0,0,20,20)};v.press(m,Vector2(10,10));check(d.team==[3,2],"explicit remove slot")
	v.choosing_slot=2;v.rects={"unit:1":Rect2(0,0,20,20)};v.press(m,Vector2(10,10));check(d.team==[3,2,1],"fill empty slot")
	v.open(m,"alchemy");v.rects={"roster":Rect2(0,0,20,20)};v.press(m,Vector2(10,10));check(v.tab==2,"soldier inventory remains accessible")
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("APPROVED_UI_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
