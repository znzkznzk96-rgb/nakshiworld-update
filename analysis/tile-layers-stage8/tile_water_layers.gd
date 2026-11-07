extends Node2D
# Preview only: child of the unchanged native plate, coordinates are source pixels.
var kind:String="surface"
var elapsed:float=0.0
var animate:bool=false
var intensity:float=1.0
const SOURCE=Vector2(801,1962)
func _process(dt:float)->void:
 if animate:elapsed+=dt;queue_redraw()
func _draw()->void:
 if kind=="surface":surface()
 elif kind=="light":light()
 elif kind=="bubbles":bubbles()
 elif kind=="reflection":reflection()
 elif kind=="particles":particles()
 elif kind=="flow":flow()
 elif kind=="pier":pier()
 elif kind=="fish_mid":decorative_fish(false)
 elif kind=="fish_near":decorative_fish(true)
 elif kind=="plants_floor" or kind=="plants_wall":plants()
var motion_seed:int=randi()
func variation(index:int,salt:int)->float:
 return fposmod(sin(index*12.9898+salt*78.233+motion_seed*.001)*43758.5453,1.0)
var environment
var hour_override:float=-1.0
func solar_hour()->float:
 if hour_override>=0:return hour_override
 if environment!=null:return environment.hour()
 return 12.0
func smooth_variation(index:int,salt:int,period:float)->float:
 var cell:int=int(floor(elapsed/period))
 var f:float=smoothstep(0,1,fposmod(elapsed,period)/period)
 return lerpf(variation(index+cell*97,salt),variation(index+(cell+1)*97,salt),f)
func sun_slope()->float:
 var phase:float=clampf((solar_hour()-6.0)/12.0,0,1)
 return cos(phase*PI)*.55
func surface()->void:
 # Broken, broad horizontal reflection fields. No curved crawling glyphs.
 for row in 7:
  var depth:float=row/6.0
  var base_y:float=850+row*18
  var speed:float=5+depth*8
  var row_shift:float=sin(elapsed*.55+row*1.7)*6
  for j in 6:
   var id:int=row*6+j
   var x:float=345+fposmod(j*83+variation(id,3)*40+elapsed*speed+row_shift,452)
   var width:float=(20+depth*42)*lerpf(.6,1.5,smooth_variation(id,4,2.8+variation(id,5)*3))
   var phase:float=elapsed*(.7+variation(id,6)*.5)+variation(id,7)*TAU
   var alpha:float=(.045+.14*pow(.5+.5*sin(phase),2))*intensity
   var y:float=base_y+roundf(sin(phase)*1.2)
   var w:float=minf(width,799-x)
   if w<3:continue
   # A flat tapered pixel cluster fades in place rather than wriggling along.
   draw_rect(Rect2(x,y,w,2+floor(depth*2)),Color(.42,.91,.85,alpha))
   draw_rect(Rect2(x+w*.18,y-1,w*.63,1),Color(.63,.98,.89,alpha*.8))
   if depth>.5:
    draw_rect(Rect2(x+4,y+5,maxf(2,w*.55),1),Color(.03,.43,.53,alpha*.5))
 # Low-contrast broken lip, keeping the cross-section calm and clean.
 for j in 11:
  var x:float=340+j*43+sin(elapsed*.9+j)*8
  var width:float=18+smooth_variation(j,8,2.3+j*.13)*27
  draw_rect(Rect2(x,973+roundf(sin(elapsed*.8+j)),minf(width,800-x),2),Color(.68,.98,.91,.10*intensity))
func ray_widths(index:int)->Vector2:
 # Deliberately different narrow/medium/wide classes, shuffled per scene seed.
 # Every class still varies smoothly and independently through time.
 var classes:Array[float]=[.18,1.0,.46,.76]
 var c:float=classes[(index+posmod(motion_seed,4))%4]
 var tip:float=lerpf(3,11,smooth_variation(index,72,1.8+index*.63))
 var spread:float=lerpf(62,330,c)*lerpf(.68,1.34,smooth_variation(index,73,2.5+index*.71))
 return Vector2(tip,tip+spread)
var shader_rays:Array[TextureRect]=[]
var ray_noise:Texture2D
func _ready()->void:
 if kind!="light":return
 var noise:FastNoiseLite=FastNoiseLite.new()
 noise.seed=motion_seed;noise.frequency=.052;noise.fractal_octaves=3
 ray_noise=ImageTexture.create_from_image(noise.get_image(128,128))
 for i in 4:
  var ray:TextureRect=TextureRect.new();ray.name="ShaderRay%d"%i
  ray.position=Vector2(0,980);ray.size=Vector2(801,750)
  ray.texture=ray_noise;ray.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  ray.stretch_mode=TextureRect.STRETCH_SCALE;ray.mouse_filter=Control.MOUSE_FILTER_IGNORE
  ray.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
  ray.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
  var mat:ShaderMaterial=ShaderMaterial.new();mat.shader=load("res://tests/tile_light.gdshader")
  ray.material=mat;add_child(ray);shader_rays.append(ray)
 light()
func light()->void:
 var daylight:float=smoothstep(5.5,7.5,solar_hour())*(1-smoothstep(17,19,solar_hour()))
 for i in shader_rays.size():
  var ray:TextureRect=shader_rays[i];ray.visible=daylight>0.001
  var mat:ShaderMaterial=ray.material
  var length:float=lerpf(490,710,smooth_variation(i,71,4.7+i*.8))
  var widths:Vector2=ray_widths(i)
  mat.set_shader_parameter("elapsed",elapsed)
  mat.set_shader_parameter("speed",.14+i*.031)
  mat.set_shader_parameter("wave_freq",11+i*2.3)
  mat.set_shader_parameter("wave_amp",.012+i*.001)
  mat.set_shader_parameter("origin_x",([118,307,502,696][i]+sin(elapsed*(.16+i*.023)+i)*8)/801.0)
  mat.set_shader_parameter("slope_x",sun_slope()*750.0/801.0)
  mat.set_shader_parameter("tip_width",widths.x/801.0)
  mat.set_shader_parameter("bottom_width",widths.y/801.0)
  mat.set_shader_parameter("ray_length",length/750.0)
  mat.set_shader_parameter("seed_offset",i*.713+variation(i,93))
  mat.set_shader_parameter("light_intensity",lerpf(.68,1.0,smooth_variation(i,74,2.9+i*.61))*daylight*intensity)
func bubbles()->void:
 # Each slot has its own seeded cycle, silent gap and randomized rise track.
 for i in 28:
  var duration:float=7+variation(i,31)*11
  var offset:float=variation(i,32)*duration
  var cycle:int=int(floor((elapsed+offset)/duration))
  var phase:float=fposmod(elapsed+offset,duration)/duration
  var delay:float=.08+variation(i+cycle*53,33)*.24
  if phase<delay:continue
  var progress:float=(phase-delay)/(1-delay)
  var seed_index:int=i+cycle*53
  var side:float=variation(seed_index,34)
  var base_x:float=(25+side*85 if i%2==0 else 668+side*103)
  var start_y:float=1450+variation(seed_index,35)*310
  var end_y:float=1000+variation(seed_index,36)*115
  var x:float=base_x+sin(progress*9+variation(i,37)*TAU)*(4+variation(i,38)*9)
  var y:float=lerpf(start_y,end_y,progress)
  var fade:float=clampf(progress*12,0,1)*clampf((1-progress)*12,0,1)
  var size:float=3+floor(variation(seed_index,39)*6)
  var col:Color=Color(.58,.94,.98,.48*fade*intensity)
  draw_rect(Rect2(x+2,y,size-2,1),col);draw_rect(Rect2(x+2,y+size,size-2,1),col)
  draw_rect(Rect2(x,y+2,1,maxf(1,size-3)),col);draw_rect(Rect2(x+size,y+2,1,maxf(1,size-3)),col)
  draw_rect(Rect2(x+1,y+1,2,1),Color(.86,1,1,.7*fade*intensity))
  # Small companion bubbles appear only on selected bursts.
  if variation(seed_index,40)>.72:
   draw_rect(Rect2(x+9,y+size+8,2,2),Color(.74,.97,1,.35*fade*intensity))

# Decorative effects never touch game input, fish state, or the line anchor.
var fish_textures:Array[Texture2D]=[]
var plant_textures:Array[Texture2D]=[]
func reflection()->void:
 # Broken shimmering patches track the same sun direction, with variable widths.
 for i in 16:
  var depth:float=variation(i,81)
  var x:float=355+fposmod(variation(i,82)*435+elapsed*(7+variation(i,83)*12)+sun_slope()*depth*65,435)
  var y:float=987+depth*36+sin(elapsed*(1.1+variation(i,84))+i)*3
  var w:float=lerpf(6,37,smooth_variation(i,85,1.4+variation(i,86)*2.5))
  var alpha:float=(.06+.13*smooth_variation(i,87,1.7+variation(i,88)))*intensity
  draw_rect(Rect2(x,y,minf(w,800-x),2+floor(variation(i,89)*3)),Color(.54,.98,.87,alpha))
func particles()->void:
 for i in 32:
  var x:float=36+fmod(i*137+elapsed*(3+i%3*2),728)
  var y:float=1040+fmod(i*83-elapsed*(5+i%2*3)+1600,640)
  var a:float=.19*(.6+.4*sin(elapsed*.6+i))*intensity
  draw_rect(Rect2(roundf(x/2)*2,roundf(y/2)*2,2,2),Color(.60,.91,.84,a))
func flow()->void:
 for i in 8:
  var y:float=1080+i*77
  var x:float=30+fmod(i*143+elapsed*17,710)
  draw_rect(Rect2(roundf(x/2)*2,y,16+i%3*5,1),Color(.36,.83,.89,.10*intensity))
func pier()->void:
 for i in 3:
  var phase:float=fmod(elapsed*.42+i/3.0,1.0)
  var width:float=18+phase*66
  var a:float=.28*(1-phase)*intensity
  draw_line(Vector2(210-width*.5,971+i*2),Vector2(210+width*.5,971+i*2),Color(.67,.98,.92,a),2,false)
func decorative_fish(near:bool)->void:
 if fish_textures.is_empty():return
 var count:int=3 if near else 5
 for i in count:
  var tex:Texture2D=fish_textures[i%fish_textures.size()]
  var period:float=16+variation(i+(31 if near else 0),51)*20
  var phase_path:float=elapsed*TAU/period+variation(i+(31 if near else 0),52)*TAU
  var range_x:float=260+variation(i,53)*110
  var x:float=400+sin(phase_path)*range_x
  var y:float=(1210 if near else 1090)+(i%3)*(154 if near else 111)+sin(elapsed*(.7+variation(i,54)) + i)*13
  var width:float=(85 if near else 46)+(i%2)*10
  var h:float=width*tex.get_height()/float(tex.get_width())
  var direction:float=-1 if cos(phase_path)>0 else 1
  var turn_scale:float=lerpf(.25,1,clampf(absf(cos(phase_path))*7,0,1))
  var phase:float=elapsed*(5.2+variation(i,55)*3)+i*2
  draw_set_transform(Vector2(x,y),sin(elapsed*1.1+i)*.025,Vector2(direction*turn_scale,1))
  var tint:Color=Color(1,1,1,(.93 if near else .65)*intensity)
  var tw:float=tex.get_width();var th:float=tex.get_height()
  # Preserve original head/body; flex only original tail pixels in four bands.
  draw_texture_rect_region(tex,Rect2(-width*.5,0,width*.68,h),Rect2(0,0,tw*.68,th),tint)
  for band in 4:
   var f:float=band/4.0
   var shift:float=sin(phase-f*.9)*(1.2+f*3.6)
   draw_texture_rect_region(tex,Rect2(width*(-.5+.68+f*.32),shift,width*.08,h),Rect2(tw*(.68+f*.32),0,tw*.08,th),tint)
  draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
func plants()->void:
 if plant_textures.is_empty():return
 var wall:bool=kind=="plants_wall"
 var count:int=2 if wall else 4
 for i in count:
  var tex:Texture2D=plant_textures[i%plant_textures.size()]
  var h:float=(112 if wall else 105)+(i%2)*13
  var w:float=h*tex.get_width()/float(tex.get_height())
  var anchor:Vector2
  if wall:anchor=Vector2(28,1718) if i==0 else Vector2(750,1660)
  else:anchor=Vector2([30,148,635,735][i],[1672,1785,1760,1638][i])
  draw_set_transform(anchor,0,Vector2(-1 if wall and i==1 else 1,1))
  var root_x:float=w*.25 if wall else w*.5
  var root_y:float=h*.41 if wall else h
  for band in 12:
   var v:float=band/12.0
   var influence:float=pow(absf(v-(.41 if wall else 1.0)),1.5)
   var shift:float=sin(elapsed*1.7+i+v*1.8)*12*influence
   draw_texture_rect_region(tex,Rect2(-root_x+shift,-root_y+v*h,w,h/12.0+.1),Rect2(0,v*tex.get_height(),tex.get_width(),tex.get_height()/12.0),Color(.86,.98,1,.96*intensity))
  draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
