extends Node2D
# Shared light field in plate/source coordinates. No game/save/RNG references.
var source_rect:Rect2=Rect2(0,980,801,750)
var seed_offset:float=399.67199999999997
var field:TextureRect
var shader_material:ShaderMaterial
func _ready()->void:
 var image:Image=Image.create(1,1,false,Image.FORMAT_RGBA8);image.fill(Color.WHITE)
 field=TextureRect.new();field.name="VerticalNoiseLight"
 field.texture=ImageTexture.create_from_image(image)
 field.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;field.stretch_mode=TextureRect.STRETCH_SCALE
 field.mouse_filter=Control.MOUSE_FILTER_IGNORE;field.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 shader_material=ShaderMaterial.new();shader_material.shader=load("res://addons/reservoir/vertical_water_light.gdshader")
 field.material=shader_material;add_child(field);apply_layout();update_light(0,8)
func apply_layout()->void:
 if not is_instance_valid(field):return
 field.position=source_rect.position;field.size=source_rect.size
 shader_material.set_shader_parameter("source_pixels",source_rect.size)
func update_light(elapsed:float,hour:float)->void:
 if shader_material==null:return
 var daylight:float=smoothstep(5.5,7.5,hour)*(1-smoothstep(17,19,hour))
 field.visible=daylight>.001
 shader_material.set_shader_parameter("elapsed",elapsed)
 shader_material.set_shader_parameter("seed_offset",seed_offset)
 shader_material.set_shader_parameter("sun_shear",cos(clampf((hour-6)/12,0,1)*PI)*.55*source_rect.size.y/source_rect.size.x)
 shader_material.set_shader_parameter("light_intensity",daylight)
