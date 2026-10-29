extends SceneTree
var failures=[]
func check(ok: bool,label: String) -> void:
 if not ok:failures.append(label)
func _initialize() -> void:call_deferred("run")
func prepared():
 var d=load("res://addons/expedition/model.gd").new();d.unlocked=10
 for id in [3,1,4]:d.team.append(d.add_unit(id,2,[4,4,4]).uid)
 return d
func run() -> void:
 var d=prepared();d.rng.seed=83083
 for i in 100000:d.on_capture(i%20)
 check(d.pouches>24000 and d.pouches<26000 and d.souls==[0,0,0,0,0],"capture grants bags only at configured rate")
 var before=d.pouches;var elements=d.open_pouches(before)
 check(d.pouches==0 and int(elements.reduce(func(a,b):return a+b,0))==before,"one bag one soul")
 for n in elements:check(float(n)/before>.19 and float(n)/before<.21,"uniform random elements")
 check(d.open_pouches(1).is_empty() and d.open_pouches(-1).is_empty(),"invalid open cannot change inventory")
 var chance_report=[]
 for r in range(1,11):
  d=prepared();d.start(r,1000);d.finish(true,1000);check(d.battle.reward==d.FIRST_GOLD[r-1] and d.battle.pouch_reward==d.FIRST_POUCHES[r-1],"first clear %d"%r)
  var q=d.claim();check(d.pouches==d.FIRST_POUCHES[r-1] and d.claim().is_empty(),"first claim once %d"%r)
  var wins:=0;d.rng.seed=83000+r
  for i in 10000:
   d.battle={};d.recovery_until=0;d.start(r,1000);var snap=d.serialize().duplicate(true);d.finish(true,1000)
   check(d.battle.reward==d.REPEAT_GOLD[r-1],"repeat scales %d"%r);wins+=int(d.battle.pouch_reward)
   var reward=d.battle.pouch_reward;d.finish(true,1000);check(d.battle.pouch_reward==reward,"finish cannot reroll")
   if i==0:
    var resumed=prepared();resumed.restore(snap);resumed.rng.seed=999;resumed.finish(true,1000);check(resumed.battle.pouch_reward==reward,"saved boss roll stable")
  var expected: float=d.BOSS_POUCH_CHANCE.get(r,0.0)
  check(absf(wins/10000.0-expected)<.015,"repeat probability %d"%r)
  if expected==0:check(wins==0,"normal repeat no bags %d"%r)
  chance_report.append({"round":r,"bags":wins,"clears":10000})
 d=prepared();d.start(3,1000);d.finish(false,1000);check(d.battle.reward==0 and d.battle.pouch_reward==0 and d.completed.is_empty(),"loss no new rewards")
 d=prepared();d.start(3,1000);d.battle.erase("reward_revision");d.battle.erase("pouch_reward");d.battle.reward=18;d.finish(true,1000);var old=d.claim();check(old.gold==78 and old.soul==2 and d.souls[2]==1 and d.pouches==0,"legacy pending reward retained")
 var m=load("res://tests/pouch_test_main.gd").new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false;m.TUT.done=true
 d=m.expedition.data;d.restore({});var v=m.V;var c=v.commerce;m.gold=499;c.pending=c.quote(v,m,"soul_pouch:1");check(not c.confirm(v,m) and m.gold==499 and d.pouches==0,"insufficient purchase atomic")
 m.gold=500;c.pending=c.quote(v,m,"soul_pouch:1");check(c.confirm(v,m) and m.gold==0 and d.pouches==1,"exact price purchase");check(not c.confirm(v,m),"purchase once")
 m.gold=500;m.fail_saves=true;c.pending=c.quote(v,m,"soul_pouch:1");check(not c.confirm(v,m) and m.gold==500 and d.pouches==1,"failed purchase save rollback")
 var helper=load("res://addons/reservoir/soul_pouch_shop.gd");var snapshot=d.serialize().duplicate(true);check(not helper.open(v,m,0) and d.serialize()==snapshot,"failed open save rollback")
 m.fail_saves=false;check(helper.open(v,m,0) and d.pouches==0 and d.souls.reduce(func(a,b):return a+b,0)==1,"open saved")
 var saved=d.serialize().duplicate(true);d.restore({});m._load_game();check(d.serialize()==saved,"bag and souls persist")
 d=prepared();m.expedition.data=d;d.start(5,1000);d.finish(true,1000);snapshot=d.serialize().duplicate(true);var gold=m.gold;m.fail_saves=true;m.expedition.rects={"claim":Rect2(0,0,20,20)};m.expedition.press(m,Vector2(10,10));check(d.serialize()==snapshot and m.gold==gold,"failed claim save rollback")
 m.fail_saves=false;m.expedition.press(m,Vector2(10,10));check(d.battle.is_empty() and d.pouches==3 and m.gold==gold+1200,"claim grant saved")
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print("POUCH_RATES ",JSON.stringify(chance_report));print("SOUL_POUCH_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
