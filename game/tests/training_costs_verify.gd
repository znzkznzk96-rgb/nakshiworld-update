extends SceneTree
func _initialize():call_deferred('run')
func run():
 var M=load('res://addons/expedition/model.gd');var checks:int=0
 var prices=[[100,200,400],[2000,4000,8000],[32000,64000,128000]]
 for star in [1,2,3]:
  for id in 15:
   var d=M.new();d.souls=[100,100,100,100,100];var u=d.add_unit(id,star,[4,5,6])
   for level in 3:
    var cost:int=prices[star-1][level];var before=d.serialize().duplicate(true);var q=d.training_cost(u.uid)
    if q.gold!=cost or q.souls!=level+1:push_error('quote');quit(1);return
    if not d.train(u.uid,cost-1).is_empty() or d.serialize()!=before:push_error('atomic');quit(1);return
    if d.train(u.uid,cost).gold!=cost or u.level!=level+1:push_error('exact');quit(1);return
    var restored=M.new();restored.restore(JSON.parse_string(JSON.stringify(d.serialize())))
    if restored.unit(u.uid)!=u or restored.stats(restored.unit(u.uid))!=d.stats(u):push_error('save');quit(1);return
    checks+=1
 print('TRAINING_COSTS_VERIFY failures=[] cases=',checks);quit()
