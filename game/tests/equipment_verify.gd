extends SceneTree
var failures: Array = []
func check(value: bool, label: String) -> void:
	if not value: failures.append(label);push_error(label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var m = load("res://main.gd").new()
	root.add_child(m);m.SET.sfx=0;m.SET.music=0
	await process_frame
	m.set_process(false)
	m.title_open = false
	m.gold = 100000;m.bag = [];m.rod_lv = 2;m.rod_owned = 2;m.bag_lv = 2
	m.parts_owned = ["float", "hook", "line", "reel"]
	m.rod_enh = [1, 2, 3, 0, 0, 0]
	m.equipment.restore(m, {})
	check(m.equipment.rods == [0, 1, 2], "legacy rods migrated")
	check(m.equipment.active_parts.size() == 4, "legacy active parts migrated")
	check(not m.equipment.sell(m, "rod:2"), "equipped rod cannot be sold")
	check(not m.equipment.sell(m, "part:float"), "equipped part cannot be sold")
	check(m.equipment.equip(m, "rod:2", false), "rod detaches")
	var before: int = m.gold
	check(m.equipment.sell(m, "rod:2"), "detached rod sale")
	check(m.gold == before + 900 and m.rod_enh[2] == 0, "sale value and enhancement reset")
	check(not m.equipment.sell(m, "rod:2") and m.gold == before + 900, "duplicate sale rejected")
	check(not m.V.commerce.quote(m.V, m, "rod:2").is_empty(), "sold rod can be repurchased")
	m.V._act(m, "rod:2")
	check(2 in m.equipment.rods and m.equipment.rod_equipped, "rod repurchase equips")
	check(m.equipment.equip(m, "part:hook", false), "part detaches")
	check(m.equipment.sell(m, "part:hook"), "detached part sells")
	check("hook" not in m.parts_owned and "hook" in m.equipment.unlocked_parts, "sale preserves unlock progress")
	m.V._act(m, "part:1")
	check("hook" in m.parts_owned and "hook" in m.equipment.active_parts, "part repurchase works")
	m.V.enhancement.phase = "working"
	check(not m.equipment.equip(m, "rod:2", false), "cannot detach while enhancing")
	check(not m.equipment.sell(m, "rod:1"), "cannot sell while enhancing")
	m.V.enhancement.phase = ""
	m.bag = [{"sp": 1, "w": 1.0, "price": 20}]
	check(not m.equipment.equip(m, "bag:2", false) and m.bag_lv == 2, "full container detach rejected")
	m.bag = []
	check(m.equipment.equip(m, "bag:2", false), "empty container detaches")
	check(m.equipment.sell(m, "bag:2"), "detached container sale")
	check(m.equipment.bag_progress == 2, "container progress retained")
	m.equipment.equip(m, "part:line", false)
	var saved: Dictionary = m.equipment.serialize().duplicate(true)
	m._save_game()
	m.parts_owned = [];m.equipment.rods = [];m.gold = 0;m.rod_enh = [0,0,0,0,0,0]
	m._load_game()
	check(m.equipment.serialize() == saved, "equipment save round trip")
	check("line" not in m.equipment.active_parts and "line" in m.parts_owned, "detached state persists")
	# A lost fish returns to idle rather than another casting button.
	m.scene = "fish";m.title_open = false;m.settings_open = false;m.market_open = false;m.tip_t = 0
	m.S = {"phase": "fail", "t": 2.19, "failText": "test"}
	m._process(0.05)
	check(m.S.phase == "idle", "failure automatically returns to idle")
	m.S = {"phase": "idle"};m.equipment.rod_equipped = false
	m.start_cast()
	check(m.S.phase == "idle", "cannot cast without a rod")
	# Every lesson can draw from idle/village without a current fish.
	m.scene = "village";m.S = {"phase": "idle"}
	for key in m.BOOK_KEYS:
		m.open_card(key, "book")
		for tick in range(0, 120):
			m.ui_clock = m.lesson_clock + tick * 0.1
			m.text_items = [];m.ui_commands = []
			m._draw_lesson_card(0.0)
			check(m.ui_commands.size() > 15, "lesson rendered: " + key)
		m.close_card(true)
	print("VERIFY failures=", failures)
	m.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
