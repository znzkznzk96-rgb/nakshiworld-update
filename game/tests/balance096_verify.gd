extends SceneTree
var failures=[]
func check(ok,label):
 if not ok:failures.append(label);push_error(label)
func _initialize():
 var Model=load("res://addons/expedition/model.gd")
 for revision in [0,1,2]:
  for r in range(1,11):
   for first in [true,false]:
    var d=Model.new();d.unlocked=10
    for id in [0,5,10]:var u=d.add_unit(id,3,[4,4,4]);d.team.append(u.uid)
    if not first:d.completed=[r]
    check(d.start(r,1000),"start")
    d.battle.reward_revision=revision
    var loaded=Model.new();loaded.restore(d.serialize());loaded.finish(true,1000)
    var expected=(d.FIRST_GOLD[r-1] if first else d.REPEAT_GOLD[r-1]) if revision==2 else ((26*r if first else 2*r) if revision==1 else (20*r if first else 0))
    check(loaded.battle.reward==expected,"saved reward revision")
    var saved=loaded.serialize();var done=Model.new();done.restore(saved)
    check(done.claim().gold==expected and done.claim().is_empty(),"pending reward once")
 var m=load("res://main.gd").new()
 check(m.V.ROD_COST==[0,8000,140000,2800000,18000000,76000000],"rod fourfold")
 for i in 4:check(m.region_shop.price(m,0,i)==[660,1320,2376,3960][i],"initial parts fourfold")
 check(m.spots.PRICES==[0,19800,312000,4635000,30150000,127350000],"entry threefold")
 m.free()
 print("BALANCE096_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
