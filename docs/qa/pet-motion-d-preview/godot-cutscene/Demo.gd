extends Node2D

const GRADES := ["D", "C", "B", "A", "S", "SS", "SSS"]
@onready var cutscene = $Cutscene
var _index := 6

func _ready() -> void:
	if "--smoke" in OS.get_cmdline_user_args():
		_smoke()
		return
	_play_current()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_7:
		_index = event.keycode - KEY_1
	elif event.keycode != KEY_SPACE:
		return
	_play_current()

func _play_current() -> void:
	cutscene.play(GRADES[_index], preload("res://Pet.png"))

func _smoke() -> void:
	var initial := Engine.time_scale
	for expected in GRADES:
		cutscene.play(expected, preload("res://Pet.png"))
		var observed = await cutscene.finished
		if observed != expected or not is_equal_approx(Engine.time_scale, initial):
			push_error("Grade or time-scale mismatch: %s" % expected)
			get_tree().quit(1)
			return
		print("PASS ", expected)
	cutscene.play("SSS")
	await get_tree().create_timer(2.28, false, false, true).timeout
	var observed_slowdown: bool = Engine.time_scale < initial
	cutscene.cancel()
	if not observed_slowdown or not is_equal_approx(Engine.time_scale, initial) or cutscene.camera.enabled:
		push_error("Cutscene cancellation leaked presentation state")
		get_tree().quit(1)
		return
	print("PASS cancellation")
	await get_tree().create_timer(0.5, false, false, true).timeout
	get_tree().quit()
