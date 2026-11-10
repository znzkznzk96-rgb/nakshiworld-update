extends "res://root.gd"
# Exercise actual composition, but skip only the unrelated splash display delay.
func _ready() -> void:
 splash_started_msec=Time.get_ticks_msec()-2000
func _start()->void:
 await super._start()
 var m=box.get_child(0).get_child(0)
 m.SET.music=0;m.SET.sfx=0
 for player in find_children("*","AudioStreamPlayer",true,false):player.stop()
 await get_tree().create_timer(.1).timeout
