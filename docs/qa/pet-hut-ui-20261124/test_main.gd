extends Control
var ui: PetHutUI
func _ready() -> void:
	ui = PetHutUI.new()
	ui.size = Vector2(270, 420)
	add_child(ui)
