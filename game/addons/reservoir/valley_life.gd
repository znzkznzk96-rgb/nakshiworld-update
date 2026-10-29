extends Node2D
# Decoration only: no game RNG, input, catches, currency or save mutations.
const SPECIES=[20,21,28]
const SOURCES=[Vector2(14,159),Vector2(37,183),Vector2(56,214),Vector2(22,250),Vector2(47,281),Vector2(26,322),Vector2(67,378)]
const SHAPES=[[[0,1],[2,0],[4,1],[3,3],[1,4]],[[0,0],[3,1],[4,3],[2,4],[1,2]],[[0,1],[2,0],[5,1],[3,2],[2,4],[1,2]],[[0,0],[2,1],[3,4],[1,5],[0,3]]]
var valley
var fish=[]
var bounds=[]
var runs=[]
var idles=[]
var mist: Texture2D
func _ready():
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 for sp in SPECIES:
  var tex: Texture2D=load("res://art/fish/l1_%02d.png"%(sp-20))
  fish.append(tex);bounds.append(Rect2(tex.get_image().get_used_rect()))
 for i in 9:runs.append(load("res://art/valley094/deer_run_%02d.png"%i))
 for i in 5:idles.append(load("res://art/valley094/deer_idle_%02d.png"%i))
 mist=load("res://art/valley094/mist.png")
static func rnd(n: float)->float:return fposmod(sin(n*127.1+42)*43758.5453,1)
static func deer_state(t: float)->Dictionary:
 var cycle: float=fposmod(t+1,22)
 var x: float=129
 var moving:=false
 var facing:=1
 if cycle<4:x=93+cycle*9;moving=true
 elif cycle>=8.4 and cycle<9:facing=-1
 elif cycle>=9 and cycle<13:x=129-(cycle-9)*9;moving=true;facing=-1
 return {"visible":cycle<13,"x":x,"y":276-maxf(0,1-absf(x-132)/22)*11,"moving":moving,"facing":facing,"alpha":clampf((x-93)/5,0,1)}
func sprite(tex: Texture2D,pos: Vector2,size: Vector2,color: Color,flip: bool=false,source: Rect2=Rect2()):
 var dst:=Rect2(pos,size)
 if flip:dst.position.x+=dst.size.x;dst.size.x=-dst.size.x
 if source.has_area():draw_texture_rect_region(tex,dst,source,color)
 else:draw_texture_rect(tex,dst,false,color)
func _draw():
 if valley==null:return
 var t: float=valley.elapsed
 draw_set_transform(valley.map_rect.position,0,valley.map_rect.size/Vector2(314,768))
 # Thin textured mist uses varied depth, speed and opacity.
 for i in 3:
  sprite(mist,Vector2([155,178,163][i]+sin(t*(0.13+i*0.04)+i)*10,[325,377,412][i]),Vector2([78,88,124][i],[24,27,26][i]),Color(0.77,0.95,0.93,[0.035,0.045,0.055][i]))
 for j in 4:
  var x: float=130+j*43+sin(t*0.22+j)*7
  draw_colored_polygon(PackedVector2Array([Vector2(x,435),Vector2(x+13,435),Vector2(x-28,625),Vector2(x-53,625)]),Color(0.76,0.95,0.74,0.055))
 for i in 3:
  var phase: float=t*[0.16,0.13,0.11][i]+i*2
  var pos:=Vector2([177,182,163][i]+sin(phase)*[51,58,46][i],[485,548,597][i]+sin(t*0.6+i)*3)
  var size: Vector2=bounds[i].size*0.375
  sprite(fish[i],pos-size/2,size,Color(0.78,0.92,0.94,[0.58,0.68,0.63][i]),cos(phase)<0,bounds[i])
 var d:=deer_state(t)
 if d.visible:
  var frames: Array=runs if d.moving else idles
  sprite(frames[int(t*(12 if d.moving else 4))%frames.size()],Vector2(d.x-13.5,d.y-27),Vector2(27,27),Color(0.56,0.62,0.64,d.alpha*0.93),d.facing<0)
 for i in 6:
  var x: float=85+fposmod(t*(7 if i<5 else -10)+i*19,224)
  var y: float=(139+i%3*9 if i<5 else 207)+sin(t*0.65+i)*3
  var wing: float=sin(t*7+i)*2.5
  draw_polyline(PackedVector2Array([Vector2(x-3,y-wing),Vector2(x,y),Vector2(x+3,y-wing)]),Color(0.14,0.29,0.34,0.76),0.8)
 for j in 77:
  var group: int=j/3
  var phase: float=fposmod(t*(0.065+rnd(group)*0.025)+rnd(group+70)+(j%3)*0.025,1)
  var pos: Vector2=SOURCES[group%7]+Vector2(sin(phase*6+j)*4+phase*(6+rnd(group+11)*15)+(j%3-1)*3,phase*(35+rnd(group+17)*26))
  var a: float=minf(1,minf(phase*12,(1-phase)*5))*(0.55+rnd(j)*0.3)
  var s: float=0.62+rnd(j+23)*0.48
  var pts:=PackedVector2Array()
  for q in SHAPES[j%4]:pts.append(pos+Vector2(q[0],q[1]).rotated(sin(t*0.9+j)*0.65)*s)
  var col: Color=[Color("93b946"),Color("658b32"),Color("b0cb59"),Color("759d38")][j%4];col.a=a
  draw_colored_polygon(pts,col)
  draw_line(pos+Vector2(1,1)*s,pos+Vector2(2,2)*s,Color(0.75,0.85,0.46,a*0.65),0.7)
 for k in 3:
  for j in 7:
   var phase: float=fposmod(t*(0.055+k*0.012)+j/7.0,1)
   var pos:=Vector2([79,267,213][k]+sin(phase*11+j)*4,[620,605,635][k]-phase*173)
   draw_arc(pos,2 if j%3==0 else 1,0,TAU,8,Color(0.66,0.91,0.86,sin(phase*PI)*0.5),0.6)
 for j in 22:
  var x: float=89+rnd(j+250)*181+sin(t*0.3+j)*2
  draw_rect(Rect2(x,620+rnd(j+140)*19,3+rnd(j)*8,0.5),Color(0.55,0.83,0.71,maxf(0,sin(t*0.8+j))*0.13))
 draw_set_transform(Vector2.ZERO)
