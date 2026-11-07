extends SceneTree
func _initialize():call_deferred("run")
func run():
 var fx=load("res://tests/tile_water_layers.gd").new();fx.kind="light";fx.motion_seed=2026110804;fx.hour_override=12
 root.add_child(fx);await process_frame
 var ok:bool=fx.shader_rays.size()==1
 var field:TextureRect=fx.shader_rays[0];var mat:ShaderMaterial=field.material
 ok=ok and field.texture.get_width()==1
 fx.elapsed=3;fx.light();ok=ok and is_equal_approx(mat.get_shader_parameter("elapsed"),3.0)
 fx.hour_override=9;fx.light();var morning:float=mat.get_shader_parameter("sun_shear")
 fx.hour_override=16;fx.light();var afternoon:float=mat.get_shader_parameter("sun_shear")
 fx.hour_override=0;fx.light();ok=ok and not field.visible and morning>0 and afternoon<0
 var source:String=mat.shader.code
 ok=ok and not source.contains("tip_width") and not source.contains("bottom_width") and not source.contains("texture(") and source.contains("noise2")
 print("PROCEDURAL_LIGHT_VERIFY passed=",ok," fields=",fx.shader_rays.size()," apex=none sampled_pattern=none")
 fx.queue_free();await process_frame;quit(0 if ok else 1)
