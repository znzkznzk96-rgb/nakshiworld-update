extends "res://addons/expedition/model.gd"
# Archived skill contract fixture. New runtime is covered by tier_skills_verify.
func start(round_no:int,now:float)->bool:
 if not super.start(round_no,now):return false
 for key in ['tier_skill_revision','skill_time','skill_accumulator','normal_time','skill_effects','skill_casts','stun_left','stun_immune_until','enemy_ready','enemy_delay']:battle.erase(key)
 for f in battle.fighters:
  for key in f.keys():
   if key not in ['id','uid','hp','max_hp','atk','def','shield','hits','support_budget']:f.erase(key)
 spawn_enemy()
 return true
