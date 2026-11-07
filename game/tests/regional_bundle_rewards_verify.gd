extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
 if not ok: failures.append(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var m=load("res://main.gd").new();m.SET.music=0;m.SET.sfx=0;m.title_open=false;root.add_child(m)
 await process_frame;m.set_process(false)
 var p=m.progression;var ui=m.V.bundle_preview
 for area in 3:
  for kind in [1,2]:
   p.restore({});m.gold=0;m.souls=0;m.pearl=0
   var key=p.bundle_key(area,kind)
   p.extra_completed[key]=true;p.bundle_values[key]=1001
   var expected: int=([1201,1502,1802][area] if kind==1 else [1502,2002,2503][area])
   check(ui.reward_amount(m,area,kind)==expected and ui.reward_preview_amount(m,area,kind)==expected,"display exact amount")
   m.development_preview=true
   check(not p.claim_reward(m,area,kind) and m.gold==0 and m.souls==0 and m.pearl==0 and not p.claimed(area,kind),"failed save rolls back")
   m.development_preview=false
   check(p.claim_reward(m,area,kind) and m.gold==expected,"regional payout")
   check(m.souls==([15,30,50][area] if kind==1 else 0) and m.pearl==([2,4,6][area] if kind==2 else 0),"regional extras")
   var saved: Dictionary=p.serialize().duplicate(true);p.restore(saved)
   check(not p.claim_reward(m,area,kind) and m.gold==expected,"receipt prevents duplicate after restore")
   ui.region=area;ui.tab=kind;ui.draw(m,540)
   if kind==2: check(m.text_items.any(func(it):return ("진주 %d개"%[2,4,6][area]) in str(it[2])),"regional pearl caption")
 check(ui.MUSEUM_TILE.resource_path=="res://art/refresh53/tile_sea.png","museum original thumbnail")
 check(m.spots.images[2].resource_path=="res://art/bg/tile_sea_approved_20261107.png","fishing approved background preserved")
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print("REGIONAL_BUNDLE_REWARDS_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
