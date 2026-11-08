extends Node2D
# A transparent original-art mask preserves occlusion between rig parts. No art edits.
var owner_game
var mask:SubViewport
var mask_root:Node2D
var overlay:Sprite2D
var sprites:Array[Sprite2D]=[]
var shader_material:ShaderMaterial
var enabled:bool=true
func _ready()->void:
 name="HelmetLocalLight";z_index=1
 mask=SubViewport.new();mask.name="OriginalActorLightMask";mask.transparent_bg=true
 mask.disable_3d=true;mask.render_target_clear_mode=SubViewport.CLEAR_MODE_ALWAYS
 mask.render_target_update_mode=SubViewport.UPDATE_DISABLED;add_child(mask)
 mask_root=Node2D.new();mask.add_child(mask_root)
 overlay=Sprite2D.new();overlay.centered=false;overlay.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 overlay.texture=mask.get_texture();shader_material=ShaderMaterial.new()
 shader_material.shader=load("res://addons/reservoir/headlamp_light.gdshader")
 overlay.material=shader_material;add_child(overlay);visible=false
func _process(_dt:float)->void:
 if owner_game!=null and (not owner_game.night_play.active(owner_game) or owner_game.environment.night_strength()<=.00001 or not enabled):
  visible=false;mask.render_target_update_mode=SubViewport.UPDATE_DISABLED
func sync(m)->void:
 owner_game=m
 var night:float=m.environment.night_strength()
 visible=enabled and m.night_play.active(m) and night>.00001
 if not visible:
  mask.render_target_update_mode=SubViewport.UPDATE_DISABLED;return
 mask.size=Vector2i(m.get_viewport_rect().size)
 mask.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 var parts:Array=m.angler_scene.light_parts
 while sprites.size()<parts.size():
  var part:=Sprite2D.new();part.centered=false;part.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
  mask_root.add_child(part);sprites.append(part)
 for i in sprites.size():
  sprites[i].visible=i<parts.size()
  if i<parts.size():sprites[i].texture=parts[i].texture;sprites[i].transform=parts[i].transform
 shader_material.set_shader_parameter("lamp_position",m.angler_scene.headlamp_world+Vector2(0,m.oy))
 shader_material.set_shader_parameter("viewport_size",Vector2(mask.size))
 shader_material.set_shader_parameter("night_strength",night)
