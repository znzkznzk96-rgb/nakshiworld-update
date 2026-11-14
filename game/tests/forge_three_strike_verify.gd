extends SceneTree

var failures: Array[String] = []
var checks: int = 0

class ForgeHost extends RefCounted:
	var forge_seen: bool = false
	var forge_pending: Dictionary = {"rod": 0, "old": 1, "next": 2, "success": true, "protected": false}
	var sound_events: Array[String] = []
	var buzz_events: int = 0
	var saves: int = 0
	func play(n: String, _vol: float = 0.0, _pitch: float = 1.0) -> void:
		sound_events.append(n)
	func buzz(_pattern) -> void:
		buzz_events += 1
	func _save_game() -> bool:
		saves += 1
		return true

func check(test: bool, label: String) -> void:
	checks += 1
	if not test:
		failures.append(label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var model = load("res://addons/reservoir/enhancement.gd")
	for win in [true, false]:
		var e = model.new()
		var h = ForgeHost.new()
		e.record = {"rod": 0, "old": 1, "next": 2 if win else 1, "success": win, "protected": false}
		h.forge_pending = e.record.duplicate()
		e.phase = "working"
		e.elapsed = 0.0
		e.strikes = 0
		check(e.HIT_AT.size() == 3 and e.HIT_AT[0] < e.HIT_AT[1] and e.HIT_AT[1] < e.HIT_AT[2], "three ordered impact timestamps")
		check(absf(e.WORK_TIME + e.REVEAL_TIME - 3.52) < 0.01, "approximately 3.5 seconds to user confirmation")
		e.process(h, 0.57)
		check(e.strikes == 0 and h.sound_events.size() == 0, "no premature hammer")
		e.process(h, 0.02)
		check(e.strikes == 1 and h.sound_events == ["hammer"], "first strike once")
		e.process(h, 0.82)
		check(e.strikes == 2 and h.sound_events == ["hammer", "hammer"], "second strike once")
		e.process(h, 0.82)
		check(e.strikes == 3 and h.sound_events == ["hammer", "hammer", "hammer"], "third strike once")
		e.process(h, 0.30)
		check(e.phase == "working" and e.elapsed >= 2.5, "post-impact hold before reveal")
		e.process(h, 0.18)
		check(e.phase == "result" and e.elapsed == 0.0, "result transitions once at work time")
		check(h.sound_events == ["hammer", "hammer", "hammer", "catch" if win else "snap"], "outcome sound only after three blows")
		check(h.saves == 1 and h.forge_seen, "result flag saved once")
		e.process(h, 0.81)
		check(e.phase == "result", "result survives until confirmation")
		e.process(h, 5.0)
		check(h.sound_events.size() == 4 and h.saves == 1, "outcome sound and save not repeated")
		e.act(null, h, "forge_done")
		check(e.phase == "" and h.forge_pending.is_empty(), "confirm dismisses without reroll")
		check(h.saves == 2, "dismiss persisted")
	# Skip must not synthesize or reroll when first animation has not been seen.
	var first = model.new()
	var first_h = ForgeHost.new()
	first.phase = "working"
	first.record = {"rod": 0, "old": 0, "next": 1, "success": true, "protected": false}
	first.act(null, first_h, "forge_skip")
	check(first.phase == "working" and first_h.sound_events.is_empty(), "first enhancement cannot be skipped")
	# A previously seen animation can jump to a previously determined outcome exactly once.
	first_h.forge_seen = true
	first.act(null, first_h, "forge_skip")
	check(first.phase == "result" and first_h.sound_events == ["catch"], "repeat skip enters result once")
	first.act(null, first_h, "forge_skip")
	check(first_h.sound_events == ["catch"], "double skip does not replay outcome")
	first.act(null, first_h, "forge_done")
	check(first.phase == "result", "cannot confirm result during reveal")
	first.process(first_h, first.REVEAL_TIME)
	first.act(null, first_h, "forge_done")
	check(first.phase == "", "confirm after reveal allowed")
	print("FORGE_THREE_STRIKE checks=", checks)
	print("FORGE_THREE_STRIKE_VERIFY failures=", failures)
	quit(0 if failures.is_empty() else 1)
