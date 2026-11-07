extends Node2D
# Tile-only surface overlays. Never samples or displaces the approved plate.
const WATER_RECT:=Rect2(340,844,460,132)
var layers:Array[TextureRect]=[]
var elapsed:float=0.0
var animated:bool=true
var redraw_clock:float=0.0
func make_pattern(seed_value:int)->Texture2D:
 var rng:=RandomNumberGenerator.new();rng.seed=seed_value
 var image:=Image.create(256,96,false,Image.FORMAT_RGBA8);image.fill(Color.TRANSPARENT)
 # Staggered small foam clusters, not repeated bars or curved worm glyphs.
 for cluster in 62:
  var x:int=rng.randi_range(0,255);var y:int=rng.randi_range(3,92)
  var alpha:float=rng.randf_range(.12,.47)
  for fleck in rng.randi_range(2,5):
   var cx:int=posmod(x+rng.randi_range(-6,6),256)
   var cy:int=clampi(y+rng.randi_range(-1,1),1,94)
   var rx:int=rng.randi_range(1,4);var ry:int=1 if cluster%3 else 2
   for dy in range(-ry,ry+1):
    for dx in range(-rx,rx+1):
     if pow(float(dx)/float(rx+1),2)+pow(float(dy)/float(ry+1),2)>1:continue
     var px:int=posmod(cx+dx,256);var py:int=clampi(cy+dy,0,95)
     var a:float=alpha*(1-.35*absf(float(dy))/float(ry+1))
     if a>image.get_pixel(px,py).a:image.set_pixel(px,py,Color(1,1,1,a))
 return ImageTexture.create_from_image(image)
func _ready()->void:
 name="TileSurfaceWater"
 for i in 2:
  var layer:=TextureRect.new();layer.name="SurfaceBack" if i==0 else "SurfaceFront"
  layer.position=WATER_RECT.position;layer.size=WATER_RECT.size
  layer.texture=make_pattern(20261108+i*113)
  layer.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;layer.stretch_mode=TextureRect.STRETCH_SCALE
  layer.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED;layer.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
  layer.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var mat:=ShaderMaterial.new();mat.shader=load("res://addons/reservoir/tile_surface_water.gdshader")
  mat.set_shader_parameter("speed",.35 if i==0 else .78)
  mat.set_shader_parameter("flow_direction",1.0 if i==0 else -1.0)
  mat.set_shader_parameter("frequency",15.0 if i==0 else 23.0)
  mat.set_shader_parameter("wave_strength",.010 if i==0 else .018)
  mat.set_shader_parameter("opacity",.54 if i==0 else .72)
  mat.set_shader_parameter("water_tint",Color(.35,.85,.82) if i==0 else Color(.66,.98,.90))
  layer.material=mat;add_child(layer);layers.append(layer)
 set_time(0)
func set_time(value:float)->void:
 elapsed=value
 for layer in layers:layer.material.set_shader_parameter("elapsed",elapsed)
func _process(dt:float)->void:
 if not animated or not is_visible_in_tree():return
 elapsed+=dt;redraw_clock+=dt
 if redraw_clock<1.0/30.0:return
 redraw_clock=0
 set_time(elapsed)
