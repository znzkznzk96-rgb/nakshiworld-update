extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String):
 if not ok:failures.append(label)
func _initialize():call_deferred('run')
func run():
 var v=load('res://addons/expedition/view.gd').new();v.setup()
 var box:=Rect2(10,20,90,60)
 for id in 15:
  var spec:Dictionary=v.data.catalog.soldiers[id]
  var count:int=v.frame_count(id,2)
  check(count==(13 if spec.id=='puffer' else 15),spec.id+' frame count')
  var tex:Texture2D=v.textures[spec.id+'_tier2'];var art:Dictionary=v.tier2[spec.id]
  check(tex.get_width()==int(art.size[0])*count and tex.get_height()==int(art.size[1]),spec.id+' atlas dimensions')
  var previous:Rect2=Rect2()
  for frame in count:
   var g:Dictionary=v.sprite_geometry(id,box,frame,2,true)
   check(g.texture==spec.id+'_tier2',spec.id+' tier2 selected')
   check(Rect2(Vector2.ZERO,tex.get_size()).encloses(g.region),spec.id+' atlas bounds')
   check(box.grow(1).encloses(g.rect),spec.id+' display bounds')
   if frame>0:check(g.rect==previous,spec.id+' stable animation position and size')
   previous=g.rect
  for star in [1,3]:
   var g:Dictionary=v.sprite_geometry(id,box,0,star)
   check(g.texture==spec.id,spec.id+' unchanged other star')
   check(v.frame_count(id,star)==int(spec.frame_count),spec.id+' unchanged other frames')
  var u:Dictionary=v.data.add_unit(id,2,[0,0,0])
  check(v.fighter_star({'uid':u.uid,'id':id})==2,spec.id+' existing battle star from uid')
 # Real saved in-progress battle resolves old fighters without modifying its data.
 v.data.team=[v.data.soldiers[0].uid,v.data.soldiers[1].uid,v.data.soldiers[2].uid]
 v.data.start(1,1000)
 var before:Dictionary=v.data.serialize().duplicate(true)
 for f in v.data.battle.fighters:check(v.fighter_star(f)==2,'legacy battle resolution')
 check(v.data.serialize()==before,'render selection never mutates save')
 var restored=load('res://addons/expedition/model.gd').new();restored.restore(before)
 check(restored.serialize()==before,'save roundtrip unchanged')
 print('TIER2_MOTION_VERIFY failures=',failures);quit(0 if failures.is_empty() else 1)
