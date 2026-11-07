extends SceneTree
func _initialize():
 var fx=load("res://tests/tile_water_layers.gd").new();fx.motion_seed=2026110804
 var samples:Dictionary={};var ok:bool=true
 for t in [0.0,3.0,7.0]:
  fx.elapsed=t;var widths:Array=[];var low:float=INF;var high:float=0
  for i in 4:
   var w:Vector2=fx.ray_widths(i);widths.append([w.x,w.y]);low=minf(low,w.y);high=maxf(high,w.y)
   ok=ok and w.y>w.x*6
  ok=ok and high/low>2;samples[str(t)]={"tip_bottom":widths,"widest_narrowest":high/low}
 print("FAN_WIDTH_VERIFY ",JSON.stringify({"passed":ok,"samples":samples}));fx.free();quit(0 if ok else 1)
