## 시험 장면: 클릭하면 한 판 돌린다. 등급은 임의(1~6번 키로 지정 가능).
extends Node2D

var machine: SlotMachine
var rng := RandomNumberGenerator.new()
var grade := -1

func _ready() -> void:
	rng.randomize()
	machine = SlotMachine.new()
	add_child(machine)

func pull(g := -1) -> void:
	if machine.busy:
		return
	var gr := g if g >= 0 else rng.randi() % 7
	machine.play(SlotMachine.make_grid(gr, rng, gr == 6 and rng.randf() < 0.25))

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		if machine.busy:
			machine.skip()
		else:
			pull()
