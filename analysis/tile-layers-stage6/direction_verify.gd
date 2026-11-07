extends SceneTree
func _initialize():
 var fx=load("res://tests/tile_water_layers.gd").new()
 fx.motion_seed=2026110804
 var samples:Dictionary={}
 var changes:int=0
 for t in [0.0,2.0,8.0]:
  var left:int=0;var right:int=0
  for near in [false,true]:
   for i in (3 if near else 5):
    var period:float=16+fx.variation(i+(31 if near else 0),51)*20
    var initial:float=fx.variation(i+(31 if near else 0),52)*TAU
    var direction:bool=cos(t*TAU/period+initial)>0
    if direction:right+=1
    else:left+=1
    if t==8.0 and direction!=(cos(initial)>0):changes+=1
  samples[str(t)]={"left":left,"right":right}
  if left==0 or right==0:push_error("one-direction sample");quit(1);return
 print("FISH_DIRECTIONS ",JSON.stringify(samples)," turns_in_8s=",changes)
 fx.free();quit(0 if changes>0 else 1)
