extends SceneTree
class Canvas extends RefCounted:
 var sheet:Image
 func _fish_effect_rect(r:Rect2,c:Color)->void:sheet.fill_rect(Rect2i(r),c)
func _initialize()->void:
 var out:String=OS.get_cmdline_user_args()[0]
 var f=load("res://addons/reservoir/fight_telegraph.gd").new()
 var canvas:=Canvas.new();canvas.sheet=Image.create(186,120,false,Image.FORMAT_RGBA8);canvas.sheet.fill(Color("183548"))
 var shapes:Array=["","right","ring","up","bolt","left","down","clones","clamp","cycle","zigzag","wave"]
 for i in shapes.size():
  for phase in 3:
   var shape:String=shapes[i]
   if shape=="":continue
   var color:Color=f.LIME if shape in ["left","ring","clamp"] else (f.VIOLET if shape=="clones" else f.CORAL)
   var dir:String=shape if shape in ["left","right","up","down"] else ("radial" if shape in ["ring","cycle"] else "right")
   f.paint(canvas,f.cue(shape,color,[0.0,.5,1.0][phase],dir),Vector2((i%3)*62+phase*18+4,int(i/3)*30+8))
 canvas.sheet.save_png(out+"-native.png");canvas.sheet.resize(1116,720,Image.INTERPOLATE_NEAREST);canvas.sheet.save_png(out+".png")
 print("FIGHT_TELEGRAPH_ICONS generated");quit()
