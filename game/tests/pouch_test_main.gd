extends "res://main.gd"
var fail_saves: bool=false
func _save_game() -> bool:
 if fail_saves:return false
 return super._save_game()
