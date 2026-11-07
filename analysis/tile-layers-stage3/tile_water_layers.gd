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
 elif kind=="caustics":caustics()
 elif kind=="reflection":reflection()
 elif kind=="particles":particles()
 elif kind=="flow":flow()
 elif kind=="pier":pier()
 elif kind=="fish_mid":decorative_fish(false)
 elif kind=="fish_near":decorative_fish(true)
 elif kind=="plants_floor" or kind=="plants_wall":plants()
func surface()->void:
 # Keep the deck, far architecture, and cross-section boundary untouched.
 for i in 18:
  var y:float=858+(i%6)*18
  var x:float=352+fmod(i*97+elapsed*(7.0+i%3*2),402)
  var pulse:float=.5+.5*sin(elapsed*.7+i*1.7)
  var width:float=8+(i%4)*7
  draw_rect(Rect2(Vector2(roundf(x/2)*2,y),Vector2(width,2)),Color(.64,.96,.90,(.12+.13*pulse)*intensity))
 for i in 7:
  var x:float=354+fmod(i*69+elapsed*11,410)
  draw_rect(Rect2(x,969,12+(i%3)*8,2),Color(.7,1,.94,.18*intensity))
func light()->void:
 # Restrict rays to open water, clear of bottom ruins and above-water architecture.
 for i in 5:
  var x:float=170+i*120+roundf(sin(elapsed*.43+i)*18)
  var wide:float=38+i%3*12
  var end_y:float=1450+i%3*85
  for j in 7:
   var a:float=j/7.0;var b:float=(j+1)/7.0
   var y0:float=990+(end_y-990)*a;var y1:float=990+(end_y-990)*b
   var skew0:float=70*a;var skew1:float=70*b
   var pulse:float=.72+.28*sin(elapsed*.65+i)
   var alpha:float=.075*(1-a)*pulse*intensity
   draw_colored_polygon(PackedVector2Array([Vector2(x+skew0,y0),Vector2(x+wide+skew0,y0),Vector2(x+wide+skew1,y1),Vector2(x+skew1,y1)]),Color(.44,.94,.91,alpha))
func bubbles()->void:
 # Varying sizes and clustered rising streams in side lanes.
 for i in 22:
  var lane:float=48 if i%2==0 else 710
  var x:float=lane+(i%4)*12+roundf(sin(elapsed*1.4+i)*9)
  var y:float=1740-fmod(i*71+elapsed*(31+i%5*7),720)
  var fade:float=clampf((y-1020)/60,0,1)*clampf((1740-y)/55,0,1)
  var size:float=[4,6,8,5][i%4]
  var col:Color=Color(.56,.93,.98,.52*fade*intensity)
  draw_rect(Rect2(x+2,y,size-2,1),col);draw_rect(Rect2(x+2,y+size,size-2,1),col)
  draw_rect(Rect2(x,y+2,1,size-3),col);draw_rect(Rect2(x+size,y+2,1,size-3),col)
  draw_rect(Rect2(x+1,y+1,2,2),Color(.86,1,1,.72*fade*intensity))
 # Small short-lived pops along the waterline, not near the cast.
 for i in 3:
  var phase:float=fmod(elapsed*.65+i*.37,1)
  if phase<.3:
   var x:float=490+i*90
   var spread:float=3+phase*22
   draw_line(Vector2(x-spread,981),Vector2(x-2,981),Color(.7,.98,1,(.3-phase)*intensity),2,false)
   draw_line(Vector2(x+2,981),Vector2(x+spread,981),Color(.7,.98,1,(.3-phase)*intensity),2,false)

# Decorative effects never touch game input, fish state, or the line anchor.
var fish_textures:Array[Texture2D]=[]
var plant_textures:Array[Texture2D]=[]
func caustics()->void:
 # Slowly bending broken light cells. Open water only; avoid UI and ruins.
 for row in 3:
  for col in 5:
   var x:float=88+col*139+roundf(sin(elapsed*.8+row+col*.6)*13)
   var y:float=1410+row*112+roundf(cos(elapsed*.6+col)*9)
   var width:float=46+sin(elapsed*.7+col)*10
   var alpha:float=(.075+.04*sin(elapsed*.9+col+row))*intensity
   var points:PackedVector2Array=PackedVector2Array([Vector2(x-width,y),Vector2(x-12,y-12),Vector2(x+width*.55,y-6),Vector2(x+width,y+10)])
   draw_polyline(points,Color(.24,.87,.90,alpha),2,false)
   draw_line(Vector2(x-12,y-12),Vector2(x-4,y-30),Color(.38,.98,.92,alpha*.7),2,false)
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
  var speed:float=(27.0 if near else 17.0)+(i%3)*4
  var x:float=-100+fmod(145+i*177+elapsed*speed,1010)
  var y:float=(1210 if near else 1090)+(i%3)*(154 if near else 111)+roundf(sin(elapsed*1.1+i)*9)
  var width:float=(85 if near else 46)+(i%2)*10
  var h:float=width*tex.get_height()/float(tex.get_width())
  var phase:float=elapsed*(6.2+i*.45)+i*2
  draw_set_transform(Vector2(x+width,y),sin(elapsed*1.1+i)*.025,Vector2(-1,1))
  var tint:Color=Color(1,1,1,(.93 if near else .65)*intensity)
  var tw:float=tex.get_width();var th:float=tex.get_height()
  # Preserve original head/body; flex only original tail pixels in four bands.
  draw_texture_rect_region(tex,Rect2(0,0,width*.68,h),Rect2(0,0,tw*.68,th),tint)
  for band in 4:
   var f:float=band/4.0
   var shift:float=sin(phase-f*.9)*(1.2+f*3.6)
   draw_texture_rect_region(tex,Rect2(width*(.68+f*.32),shift,width*.08,h),Rect2(tw*(.68+f*.32),0,tw*.08,th),tint)
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
