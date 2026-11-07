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
  var x:float=352+fmod(i*97+elapsed*(1.0+i%3),402)
  var pulse:float=.5+.5*sin(elapsed*.7+i*1.7)
  var width:float=8+(i%4)*7
  draw_rect(Rect2(Vector2(roundf(x/2)*2,y),Vector2(width,2)),Color(.64,.96,.90,(.07+.065*pulse)*intensity))
 for i in 7:
  var x:float=354+fmod(i*69+elapsed*2,410)
  draw_rect(Rect2(x,969,12+(i%3)*8,2),Color(.7,1,.94,.09*intensity))
func light()->void:
 # Restrict rays to open water, clear of bottom ruins and above-water architecture.
 for i in 5:
  var x:float=170+i*120+roundf(sin(elapsed*.22+i)*6)
  var wide:float=28+i%3*9
  var end_y:float=1330+i%3*65
  for j in 7:
   var a:float=j/7.0;var b:float=(j+1)/7.0
   var y0:float=990+(end_y-990)*a;var y1:float=990+(end_y-990)*b
   var skew0:float=70*a;var skew1:float=70*b
   var pulse:float=.85+.15*sin(elapsed*.35+i)
   var alpha:float=.036*(1-a)*pulse*intensity
   draw_colored_polygon(PackedVector2Array([Vector2(x+skew0,y0),Vector2(x+wide+skew0,y0),Vector2(x+wide+skew1,y1),Vector2(x+skew1,y1)]),Color(.44,.94,.91,alpha))
func bubbles()->void:
 # Side lanes keep the line/fish/tension HUD in the middle clear.
 for i in 10:
  var lane:float=52 if i%2==0 else 720
  var x:float=lane+(i%3)*13+roundf(sin(elapsed*.8+i)*5)
  var y:float=1500-fmod(i*49+elapsed*(8+i%3*2),485)
  var edge_fade:float=clampf((y-1015)/70,0,1)*clampf((1500-y)/70,0,1)
  var size:float=3 if i%3 else 5
  var col:Color=Color(.68,.94,.94,.24*edge_fade*intensity)
  draw_rect(Rect2(x,y,size,1),col);draw_rect(Rect2(x,y+size,size,1),col)
  draw_rect(Rect2(x-1,y+1,1,size-1),col);draw_rect(Rect2(x+size,y+1,1,size-1),col)

# Decorative effects never touch game input, fish state, or the line anchor.
var fish_textures:Array[Texture2D]=[]
var plant_textures:Array[Texture2D]=[]
func caustics()->void:
 for i in 11:
  var x:float=65+i*64+roundf(sin(elapsed*.3+i)*9)
  var y:float=1580+(i%3)*47+roundf(cos(elapsed*.4+i)*7)
  var a:float=(.025+.014*sin(elapsed*.65+i))*intensity
  draw_line(Vector2(x,y),Vector2(x+24,y-7),Color(.35,.95,.87,a),2,false)
  draw_line(Vector2(x+24,y-7),Vector2(x+42,y+4),Color(.35,.95,.87,a),2,false)
func reflection()->void:
 for i in 10:
  var x:float=386+i*37+roundf(sin(elapsed*.5+i)*3)
  var y:float=985+(i%4)*9
  draw_rect(Rect2(x,y,8+i%3*3,2),Color(.32,.91,.84,.035*intensity))
func particles()->void:
 for i in 22:
  var x:float=36+fmod(i*137+elapsed*(1+i%3),728)
  var y:float=1040+fmod(i*83-elapsed*(2+i%2)+1600,640)
  var a:float=.09*(.6+.4*sin(elapsed*.6+i))*intensity
  draw_rect(Rect2(roundf(x/2)*2,roundf(y/2)*2,2,2),Color(.60,.91,.84,a))
func flow()->void:
 for i in 8:
  var y:float=1080+i*77
  var x:float=30+fmod(i*143+elapsed*5,710)
  draw_rect(Rect2(roundf(x/2)*2,y,9+i%3*3,1),Color(.36,.83,.89,.05*intensity))
func pier()->void:
 for i in 3:
  var phase:float=fmod(elapsed*.18+i/3.0,1.0)
  var width:float=14+phase*32
  var a:float=.15*(1-phase)*intensity
  draw_line(Vector2(210-width*.5,971+i*2),Vector2(210+width*.5,971+i*2),Color(.67,.98,.92,a),2,false)
func decorative_fish(near:bool)->void:
 if fish_textures.is_empty():return
 var count:int=3 if near else 5
 for i in count:
  var tex:Texture2D=fish_textures[i%fish_textures.size()]
  var speed:float=9.0 if near else 5.0
  var x:float=-70+fmod(160+i*173+elapsed*speed,940)
  var y:float=(1220 if near else 1110)+(i%3)*(148 if near else 104)+roundf(sin(elapsed*.6+i)*5)
  var width:float=(62 if near else 30)+(i%2)*8
  var h:float=width*tex.get_height()/float(tex.get_width())
  draw_set_transform(Vector2(x+width,y),0,Vector2(-1,1))
  draw_texture_rect(tex,Rect2(0,0,width,h),false,Color(1,1,1,(.72 if near else .40)*intensity))
  draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
func plants()->void:
 if plant_textures.is_empty():return
 for i in 4:
  var wall:bool=kind=="plants_wall"
  var tex:Texture2D=plant_textures[i%plant_textures.size()]
  var x:float=([8,730,35,690][i] if wall else [30,160,620,724][i])
  var y:float=([1660,1620,1740,1700][i] if wall else [1768,1800,1790,1745][i])
  var h:float=(85 if wall else 75)+(i%2)*12
  var w:float=h*tex.get_width()/float(tex.get_height())
  var sway:float=sin(elapsed*.65+i)*1.5
  draw_texture_rect(tex,Rect2(x+sway,y-h,w,h),false,Color(.78,.94,.96,.85*intensity))
