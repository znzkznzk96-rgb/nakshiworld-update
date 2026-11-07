extends SceneTree
class Clock extends RefCounted:
 var h:float=9.0
 func hour()->float:return h
func _initialize():
 var fx=load("res://tests/tile_water_layers.gd").new();fx.motion_seed=2026110804
 var clock=Clock.new();fx.environment=clock
 var slopes:Array=[]
 for h in [9.0,12.0,16.0]:clock.h=h;slopes.append(fx.sun_slope())
 var widths:Dictionary={}
 for t in [0.0,3.0,7.0]:
  fx.elapsed=t;var values:Array=[]
  for i in 4:values.append(lerpf(16,59,fx.smooth_variation(i,72,2.1+i*.79)))
  widths[str(t)]=values
 var ok:bool=slopes[0]>.2 and absf(slopes[1])<.01 and slopes[2]<-.2 and widths["0.0"]!=widths["3.0"] and widths["3.0"]!=widths["7.0"]
 print("SUN_WIDTH_VERIFY ",JSON.stringify({"slopes":slopes,"widths":widths,"passed":ok}))
 fx.free();quit(0 if ok else 1)
