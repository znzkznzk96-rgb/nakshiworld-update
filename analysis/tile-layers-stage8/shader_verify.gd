extends SceneTree
func _initialize():call_deferred("run")
func run():
 var fx=load("res://tests/tile_water_layers.gd").new();fx.kind="light";fx.motion_seed=2026110804;fx.hour_override=12
 root.add_child(fx);await process_frame
 var ok:bool=fx.shader_rays.size()==4
 for ray in fx.shader_rays:
  ok=ok and ray.material is ShaderMaterial and ray.texture_repeat==CanvasItem.TEXTURE_REPEAT_ENABLED and ray.texture.get_width()==128
 var first:ShaderMaterial=fx.shader_rays[0].material
 fx.elapsed=3;fx.light();ok=ok and is_equal_approx(first.get_shader_parameter("elapsed"),3.0)
 fx.hour_override=0;fx.light()
 for ray in fx.shader_rays:ok=ok and not ray.visible
 fx.hour_override=12;fx.light()
 for ray in fx.shader_rays:ok=ok and ray.visible
 ok=ok and fx.shader_rays[0].material!=fx.shader_rays[1].material
 print("SHADER_NODE_VERIFY passed=",ok," rays=",fx.shader_rays.size()," noise=128 repeat=enabled night=hidden")
 fx.queue_free();await process_frame;quit(0 if ok else 1)
