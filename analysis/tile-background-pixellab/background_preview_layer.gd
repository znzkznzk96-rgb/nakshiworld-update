extends Node2D
# New PixelLab sprites only. Source coordinate overlay; input/save untouched.
var elapsed:float=0
var assets:Dictionary={}
var bounds:Dictionary={}
func _ready():
 for key in ["cloud-far","cloud-near","horizon-mist","arch-vine","ledge-grass","floor-ribbon","floor-broad","wall-ribbon","fish-far","fish-mid","fish-near","bubble-cluster","water-specks"]:
  var path:String="res://tests/tile_background_assets/"+key+".png"
  if FileAccess.file_exists(path):
   var image:Image=Image.load_from_file(path);assets[key]=ImageTexture.create_from_image(image);bounds[key]=Rect2(image.get_used_rect())
func sprite(key:String,pos:Vector2,width:float,tint:Color=Color.WHITE,flip:bool=false):
 if not assets.has(key):return
 var tex:Texture2D=assets[key];var used:Rect2=bounds[key];var h:float=width*used.size.y/used.size.x
 draw_set_transform(pos,0,Vector2(-1 if flip else 1,1))
 draw_texture_rect_region(tex,Rect2(-width*.5,-h*.5,width,h),used,tint)
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
func _draw():
 sprite("cloud-far",Vector2(466+sin(elapsed*.035)*90,355),143,Color(.90,.98,1,.72))
 sprite("cloud-far",Vector2(699+sin(elapsed*.028+2)*65,470),105,Color(.90,.98,1,.6))
 sprite("cloud-near",Vector2(570+sin(elapsed*.05+1)*110,255),190)
 sprite("horizon-mist",Vector2(560+sin(elapsed*.08)*24,835),465,Color(.72,.98,.94,.26))
 sprite("arch-vine",Vector2(33,480),53)
 sprite("arch-vine",Vector2(746,1625),39,Color(.80,.95,.97,.90),true)
 sprite("ledge-grass",Vector2(68,887),44)
 sprite("ledge-grass",Vector2(264,903),32)
 sprite("floor-ribbon",Vector2(31+sin(elapsed*1.1)*2,1630),58)
 sprite("floor-ribbon",Vector2(664+sin(elapsed*.95)*2,1730),65)
 sprite("floor-broad",Vector2(728,1597),57)
 sprite("floor-broad",Vector2(153,1747),44)
 sprite("wall-ribbon",Vector2(30,1710),54)
 sprite("wall-ribbon",Vector2(747,1670),65,Color(.90,.98,1,1),true)
 for depth in 3:
  var key:String=["fish-far","fish-mid","fish-near"][depth]
  for i in (4 if depth==0 else 3):
   var phase:float=elapsed*(.15+depth*.025+i*.009)+i*2.3+depth*.9
   var pos:Vector2=Vector2(420+sin(phase)*(260+i%2*64),1090+depth*120+i*74+sin(elapsed*.8+i)*7)
   sprite(key,pos,[27,46,76][depth],Color(1,1,1,[.56,.78,1.0][depth]),cos(phase)<0)
 for i in 8:
  var x:float=(55 if i%2==0 else 729)+sin(elapsed*.7+i)*8
  var y:float=1710-fposmod(elapsed*(26+i*3)+i*83,700)
  var fade:float=clampf((y-1010)/60,0,1)*clampf((1710-y)/60,0,1)
  sprite("bubble-cluster",Vector2(x,y),[18,24,31][i%3],Color(1,1,1,.60*fade))
 for i in 7:
  var x:float=60+fposmod(i*131+elapsed*3,690)
  var y:float=1070+fposmod(i*91+elapsed*4,550)
  sprite("water-specks",Vector2(x,y),23,Color(.85,1,1,.4))
