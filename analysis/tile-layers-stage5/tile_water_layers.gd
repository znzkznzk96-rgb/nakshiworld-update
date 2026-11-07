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
func surface()->void:
 # Above-water open sea only. Moving broken crests, dark troughs and glints.
 for i in 34:
  var depth:float=variation(i,1)
  var y:float=841+depth*126
  var velocity:float=8+variation(i,2)*18
  var x:float=347+fposmod(variation(i,3)*430+elapsed*velocity*(1 if i%2 else -1),429)
  var width:float=12+variation(i,4)*36
  var phase:float=elapsed*(1.1+variation(i,5))+i
  var crest:float=sin(phase)*2
  var alpha:float=(.08+.16*(.5+.5*sin(phase)))*intensity
  draw_line(Vector2(x,y+crest),Vector2(minf(x+width,788),y+crest),Color(.59,.98,.92,alpha),2,false)
  if width>25:
   draw_line(Vector2(x+4,y+4),Vector2(minf(x+width*.65,788),y+4),Color(.03,.42,.57,.07*intensity),2,false)
  if i%4==0:
   draw_rect(Rect2(x+width*.3,y-2+crest,4,2),Color(.85,1,.94,alpha*.8))
 # Undulating narrow cross-section boundary stays inside the original waterline.
 for i in 32:
  var x:float=335+i*14
  var offset:float=roundf(sin(elapsed*1.8+i*.58)*2)
  draw_rect(Rect2(x,974+offset,11,2),Color(.66,1,.95,.22*intensity))
func light()->void:
 # Four irregular shafts fan out from the real water surface. Feathered sides,
 # a short soft entrance and long depth fade prevent hard rectangular strips.
 var feather:Array[float]=[.07,.28,.67,1.0,.67,.28,.07]
 for i in 4:
  var origin:float=[118,307,502,696][i]+sin(elapsed*.23+i*1.8)*7
  var length:float=[605,515,690,455][i]
  var drift:float=[118,78,146,92][i]+sin(elapsed*.31+i)*12
  var pulse:float=.88+.12*sin(elapsed*.65+i*1.7)
  for segment in 20:
   var a:float=segment/20.0;var b:float=(segment+1)/20.0
   var mid:float=(a+b)*.5
   var y0:float=980+length*a;var y1:float=980+length*b
   var w0:float=24+a*112;var w1:float=24+b*112
   var fade:float=clampf(mid*14,0,1)*pow(1-mid,1.15)
   var shimmer:float=.93+.07*sin(elapsed*.7-mid*4+i)
   for band in 7:
    var l:float=band/7.0-.5;var r:float=(band+1)/7.0-.5
    var alpha:float=.165*feather[band]*fade*pulse*shimmer*intensity
    var pts:PackedVector2Array=PackedVector2Array([Vector2(origin+drift*a+w0*l,y0),Vector2(origin+drift*a+w0*r,y0),Vector2(origin+drift*b+w1*r,y1),Vector2(origin+drift*b+w1*l,y1)])
    draw_colored_polygon(pts,Color(.64,.98,.85,alpha))
  # Readable sunlit dust glimmers inside shafts, independently pulsing.
  for j in 5:
   var along:float=fposmod(variation(i*5+j,24)+elapsed*.021,1)
   var fx:float=origin+drift*along+(variation(i*5+j,25)-.5)*(18+along*70)
   var fy:float=996+length*along
   var alpha:float=(.13+.13*(.5+.5*sin(elapsed*1.7+j*2+i)))*(1-along)*intensity
   draw_rect(Rect2(roundf(fx/2)*2,roundf(fy/2)*2,2+(j%2)*2,2),Color(.82,1,.91,alpha))
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
 for i in 15:
  var x:float=354+fmod(i*49+elapsed*(8+i%3*3),410)
  var y:float=985+(i%5)*9
  var alpha:float=(.075+.045*sin(elapsed*1.4+i))*intensity
  draw_rect(Rect2(roundf(x/2)*2,y,14+i%3*7,2),Color(.48,.97,.90,alpha))
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
