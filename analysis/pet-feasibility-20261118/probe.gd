extends SceneTree
class Probe extends "res://main.gd":
 func _save_game()->bool:return true
var checks:Array=[]
func _initialize():call_deferred("run")
func run():
 var m=Probe.new();m.SET.sfx=0;m.SET.music=0;m.SET.vib=false;root.add_child(m);await process_frame;m.set_process(false)
 m.title_open=false;m.TUT.done=true;m.scene="fish";m.trans={};m.angler_scene.setup()
 var frames={}
 for k in m.angler_scene.cats:
  frames[k]=m.angler_scene.cats[k].size()
  for t in m.angler_scene.cats[k]:assert(t.get_width()>0 and t.get_height()>0)
 for h in [480,540,660]:
  root.content_scale_size=Vector2i(270,h);root.size=Vector2i(270,h);await process_frame;m._layout()
  for r in 4:
   m.active_region=r
   var layout:Dictionary=m.capture_robot.surface_layout(m)
   assert(layout.robot.size.x>0)
   checks.append({"height":h,"region":r,"cat_anchor":[m.CATX,m.SURF],"robot_rect":[layout.robot.position.x,layout.robot.position.y,layout.robot.size.x,layout.robot.size.y]})
 m.S={"grade":0,"quickHook":false};var normal=m._perfect_half_width();m.S.quickHook=true;assert(is_equal_approx(m._perfect_half_width(),normal*2))
 var robot=load("res://addons/reservoir/capture_robot.gd").new();robot.owned=true;robot.enabled=true;m.pond_stock=0;robot.update(m,1.0);assert(robot.job.is_empty() and robot.fish.is_empty())
 var copy=load("res://addons/reservoir/capture_robot.gd").new();copy.restore(robot.serialize());assert(copy.owned and copy.enabled)
 var model=load("res://addons/expedition/model.gd").new();model.unlocked=10
 for id in [3,1,7]:model.team.append(model.add_unit(id,1,[4,4,4]).uid)
 assert(model.start(3,1000));var saved=model.serialize();var restored=load("res://addons/expedition/model.gd").new();restored.restore(saved);assert(restored.battle.fighters==model.battle.fighters)
 var out={"scope":"existing integration seams only; no pet motion render or pet mechanic implementation","cat_frames":frames,"anchor_cases":checks,"quick_hook_multiplier":2,"zero_stock_robot_blocked":true,"robot_roundtrip":true,"battle_snapshot_roundtrip":true}
 var f=FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE);f.store_string(JSON.stringify(out,"\t"));f.close()
 print("PET_FEASIBILITY_PROBE passed anchor_cases=",checks.size()," cat_frames=",frames)
 m.audio_feedback.dispose();m.queue_free();await process_frame;call_deferred("finish")
func finish():await process_frame;quit()
