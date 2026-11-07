extends Node2D
# New PixelLab sprites only. Source coordinate overlay; input/save untouched.
var elapsed:float=0
var clouds:Array[Sprite2D]=[]
var mist_node:Sprite2D
var support_node:Sprite2D
var assets:Dictionary={}
var bounds:Dictionary={}
var tile_fish:Array[Texture2D]=[]
var fish_bounds:Array[Rect2]=[]
var bird_frames:Array[Texture2D]=[]
func _ready():
 add_clouds()
 add_mist()
 add_support()
 for key in ["cloud","mist","arch-vine","ledge-grass","floor-ribbon","floor-broad","wall-ribbon","bubble-cluster","water-specks","gull"]:
  var path:String="res://tests/tile_pier_cloud_assets/"+key+".png"
  if FileAccess.file_exists(path):
   var image:Image=Image.load_from_file(path);assets[key]=ImageTexture.create_from_image(image);bounds[key]=Rect2(image.get_used_rect())
 for id in [0,1,2,3]:
  var tex:Texture2D=load("res://art/fish/l2_%02d.png"%id);tile_fish.append(tex);fish_bounds.append(Rect2(tex.get_image().get_used_rect()))
 for i in 9:
  var path:String="res://tests/tile_pier_cloud_assets/gull-flight-%02d.png"%i
  if FileAccess.file_exists(path):bird_frames.append(ImageTexture.create_from_image(Image.load_from_file(path)))
func add_mist():
 var path:String="res://tests/tile_pier_cloud_assets/mist.png"
 if not FileAccess.file_exists(path):return
 mist_node=Sprite2D.new();mist_node.texture=ImageTexture.create_from_image(Image.load_from_file(path));mist_node.scale=Vector2(2.8,1.4);mist_node.modulate=Color(1,1,1,.26)
 var mat=ShaderMaterial.new();mat.shader=load("res://tests/tile_dream_mist_soft.gdshader");mist_node.material=mat;add_child(mist_node)
func add_clouds():
 var path:String="res://tests/tile_pier_cloud_assets/cloud.png"
 if not FileAccess.file_exists(path):return
 var tex:Texture2D=ImageTexture.create_from_image(Image.load_from_file(path))
 for i in 2:
  var cloud=Sprite2D.new();cloud.texture=tex;cloud.show_behind_parent=true
  var mat=ShaderMaterial.new();mat.shader=load("res://tests/tile_pier_cloud_edge.gdshader");cloud.material=mat
  cloud.scale=Vector2([255.0,185.0][i]/192.0,[1.25,.95][i]);cloud.modulate=Color(1,1,1,[.68,.48][i]);add_child(cloud);clouds.append(cloud)
func add_support():
 var path:String="res://tests/tile_pier_cloud_assets/support.png"
 if not FileAccess.file_exists(path):return
 var image:Image=Image.load_from_file(path);var used:Rect2=Rect2(image.get_used_rect());var tex:Texture2D=ImageTexture.create_from_image(image)
 var atlas=AtlasTexture.new();atlas.atlas=tex;atlas.region=used
 support_node=Sprite2D.new();support_node.texture=atlas;support_node.show_behind_parent=true
 var mat=ShaderMaterial.new();mat.shader=load("res://tests/tile_pier_support.gdshader");mat.set_shader_parameter("uv_min",used.position/Vector2(image.get_size()));mat.set_shader_parameter("uv_span",used.size/Vector2(image.get_size()));support_node.material=mat
 var ratio:float=258.0/used.size.x;support_node.scale=Vector2(ratio,ratio);support_node.position=Vector2(129.0,977.0+used.size.y*ratio*.5);add_child(support_node)
func sprite(key:String,pos:Vector2,width:float,tint:Color=Color.WHITE,flip:bool=false):
 if not assets.has(key):return
 var tex:Texture2D=assets[key];var used:Rect2=bounds[key];var h:float=width*used.size.y/used.size.x
 draw_set_transform(pos,0,Vector2(-1 if flip else 1,1))
 if key in ["arch-vine","floor-ribbon","floor-broad","wall-ribbon"]:
  for band in 10:
   var a:float=band/10.0
   var influence:float=a if key=="arch-vine" else (1-a if key.begins_with("floor") else absf(a-.4))
   var shift:float=sin(elapsed*1.1+a*2+pos.x*.01)*3*influence*influence
   draw_texture_rect_region(tex,Rect2(-width*.5+shift,-h*.5+a*h,width,h/10+.1),Rect2(used.position+Vector2(0,a*used.size.y),Vector2(used.size.x,used.size.y/10)),tint)
 elif key.begins_with("fish"):
  # Head-right source: keep body fixed; flex the actual tail pixels only.
  draw_texture_rect_region(tex,Rect2(-width*.18,-h*.5,width*.68,h),Rect2(used.position+Vector2(used.size.x*.32,0),Vector2(used.size.x*.68,used.size.y)),tint)
  for band in 4:
   var a:float=band/4.0
   var shift:float=sin(elapsed*6.0-a*.8+pos.y)*1.6*(1-a)
   draw_texture_rect_region(tex,Rect2(-width*.5+a*width*.32,-h*.5+shift,width*.08,h),Rect2(used.position+Vector2(a*used.size.x*.32,0),Vector2(used.size.x*.08,used.size.y)),tint)
 else:
  draw_texture_rect_region(tex,Rect2(-width*.5,-h*.5,width,h),used,tint)
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
func draw_fish(index:int,pos:Vector2,width:float,alpha:float,going_right:bool):
 var tex:Texture2D=tile_fish[index%tile_fish.size()];var used:Rect2=fish_bounds[index%fish_bounds.size()]
 var h:float=width*used.size.y/used.size.x
 # Genuine tile originals all face left. Flip only to follow rightward movement.
 draw_set_transform(pos,0,Vector2(-1 if going_right else 1,1))
 draw_texture_rect_region(tex,Rect2(-width*.5,-h*.5,width,h),used,Color(1,1,1,alpha))
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
func _draw():
 for i in clouds.size():clouds[i].position=Vector2([490.0,740.0][i]+sin(elapsed*.025+i*2)*45,[335.0,490.0][i])
 if is_instance_valid(mist_node):mist_node.position=Vector2(557+sin(elapsed*.05)*18,826)
 # A broad far bank drifts slowly through the edge; nearer clouds move faster.
 sprite("arch-vine",Vector2(33,480),53)
 sprite("floor-ribbon",Vector2(68,887),22)
 sprite("floor-ribbon",Vector2(31+sin(elapsed*1.1)*2,1630),58)
 sprite("floor-broad",Vector2(728,1597),57)
 sprite("wall-ribbon",Vector2(747,1670),65,Color(.9,.98,1,1),true)
 for depth in 3:
  for i in 2:
   var phase:float=elapsed*(.10+depth*.025+i*.007)+i*1.7+depth*1.3
   var pos:Vector2=Vector2(410+sin(phase)*(260+i%2*65),1070+depth*125+(i%3)*68+sin(elapsed*.6+i)*8)
   draw_fish(i+depth*2,pos,[28,40,52][depth]+i%2*4,[.48,.72,.92][depth],cos(phase)>0)
 for i in 8:
  var x:float=(55 if i%2==0 else 729)+sin(elapsed*.7+i)*8
  var y:float=1710-fposmod(elapsed*(26+i*3)+i*83,700)
  var fade:float=clampf((y-1010)/60,0,1)*clampf((1710-y)/60,0,1)
  sprite("bubble-cluster",Vector2(x,y),[18,24,31][i%3],Color(1,1,1,.6*fade))
 for i in 8:
  sprite("water-specks",Vector2(60+fposmod(i*131+elapsed*3,690),1070+fposmod(i*91+elapsed*4,550)),25,Color(.85,1,1,.35))
 # Phase-offset near/far gulls, never above HUD. Motion frames are PixelLab output.
 for i in 7:
  var direction:float=1 if i%3 else -1
  var x:float=210+fposmod(i*127+elapsed*(13+i%3*5)*direction,640)
  var y:float=305+(i%4)*95+sin(elapsed*.75+i)*8
  var width:float=[22,38,55][i%3]
  if not bird_frames.is_empty():
   var tex:Texture2D=bird_frames[(int(elapsed*(7+i%2))+i*2)%bird_frames.size()]
   draw_set_transform(Vector2(x,y),0,Vector2(1 if direction>0 else -1,1))
   draw_texture_rect(tex,Rect2(-width*.5,-width*.5,width,width),false,Color(1,1,1,.65 if i%3==0 else .9))
   draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  else:sprite("gull",Vector2(x,y),width,Color(1,1,1,.7),direction<0)
