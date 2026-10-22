extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;m.title_open=false;root.add_child(m);await process_frame;m.set_process(false)
	m.bag=[{"sp":7,"grade":0,"w":0.022},{"sp":7,"grade":0,"w":0.026},{"sp":7,"grade":1,"w":0.031},{"sp":0,"grade":0,"w":0.05},{"sp":0,"grade":1,"w":0.055},{"sp":5,"grade":1,"w":0.052},{"sp":1,"grade":2,"w":0.18}]
	var demo=preload("res://tests/previews/inventory_concepts.gd").new()
	var before: Array=m.bag.duplicate(true)
	var groups: Array=demo.groups(m.bag)
	check(groups.size()==6 and groups[0].indices==[0,1] and groups[1].grade==1,"same species grouped by grade without merging specimens")
	check(groups[0].min_weight==0.022 and groups[0].max_weight==0.026,"weight range preserves individual variation")
	for variant in ["A","B"]:
		for height in [480,540,660]:
			demo.draw(m,height,variant)
			check(demo.regions.size()==6,"all six groups visible")
			for row in demo.regions:
				check(row.name_y+10<=row.weight_y,"name and weight have separate lines")
				check(row.rect.end.y<height-30,"cards stay above footer")
	check(m.bag==before,"proposals never alter inventory")
	var p=m.V.bundle_preview
	m.progression.bundle_values={"0:1":750,"0:2":1001}
	check(p.reward_amount(m,0,1)==900 and p.reward_amount(m,0,2)==1502,"reward display matches actual settlement rounding")
	for kind in [1,2]:
		p.region=0;p.tab=kind;p.draw(m,540)
		check(m.text_items.all(func(it):return "%" not in str(it[2]) and "판매가" not in str(it[2])),"no internal formulas in reward panel")
		if kind==2:
			var card: Rect2=p.rects["fish:0"]
			check(card.get_center().x==135 and card.position.y>200,"owner card centered in content area")
	print("INVENTORY_LAYOUT_VERIFY failures=",failures)
	m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
