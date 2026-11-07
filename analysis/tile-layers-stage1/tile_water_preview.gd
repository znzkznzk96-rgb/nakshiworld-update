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
