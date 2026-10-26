extends "res://tests/analysis/baseline080_model.gd"
# Frozen v0.80 baseline keeps historical analyses reproducible after balance changes.
var shield_factor: float=1.0
func spawn_enemy() -> void:
 super.spawn_enemy()
 if shield_factor!=1.0:
  for f in battle.fighters:
   if int(f.hp)>0 and skill(f)=="shield": f.shield=roundi(int(f.max_hp)*0.22*shield_factor)
