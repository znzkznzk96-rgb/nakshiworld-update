extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m=load("res://main.gd").new();m.SET.music=0;m.SET.sfx=0;m.title_open=false;root.add_child(m)
	await process_frame;m.set_process(false)
	var preview=m.V.bundle_preview
	var gold=m.gold;var bag=m.bag.duplicate(true);var unlocked=m.region_shop.unlocked.duplicate()
	for height in [480,540,600]:
		preview.draw(m,height)
		var grid: Rect2=preview.rects["fish:5"]
		check(grid.end.y<preview.rects.register.position.y-38,"grid clear of reward and button")
		preview.press(m,preview.rects.sub.get_center());check(preview.tab==1,"sub tab works")
		preview.draw(m,height);preview.press(m,preview.rects.register.get_center())
		check(preview.selected==0,"registration preview opens detail")
		preview.draw(m,height);preview.press(m,preview.rects.detail_close.get_center())
		check(preview.selected==-1,"detail closes")
	for i in 8:
		preview.draw(m,540);preview.press(m,preview.rects.next.get_center())
	check(preview.region==5,"region navigation bounded")
	preview.draw(m,540);preview.press(m,preview.rects.dex.get_center())
	check(preview.legacy_dex,"existing fish records remain accessible")
	m.V._act(m,"bundles");check(not preview.legacy_dex,"return from records to bundles")
	check(m.gold==gold and m.bag==bag and m.region_shop.unlocked==unlocked,"preview never spends or unlocks")
	m.audio_feedback.dispose();await create_timer(0.1).timeout;m.queue_free();await process_frame
	print("BUNDLE_PREVIEW_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
