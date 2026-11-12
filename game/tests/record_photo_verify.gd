extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String)->void:
 if not ok:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false;m.TUT.done=true
 var d=m.personal_dex;d.restore({});m.DEX={};m.REC={}
 d.observe(0,4,8,.1,"2026-11-11");d.observe(0,1,12,.2,"2026-11-12");d.observe(0,0,10,.5,"2026-11-13")
 var saved:Dictionary=d.serialize()
 var photo=d.photo
 for type in ["grade","length","weight"]:
  check(photo.open(m,0,type),"known record opens "+type)
  check(photo.specimen==d.best(m,0,type),"uses that complete specimen "+type)
  photo.specimen["date"]="changed UI copy"
  check(d.serialize()==saved,"presentation cannot mutate persistent records")
 photo.open(m,0,"length");check(photo.specimen.len==12 and photo.specimen.w==.2,"length never borrows heaviest weight")
 for sp in 80:
  for length in [.5,8.9,27.6,129.1,999.0]:
   var g:Dictionary=photo.measure(m,sp,{"len":length},Rect2(0,0,270,270))
   check(g.range>=length,"ruler range covers fish")
   check(absf((g.tail_x-g.zero.x)/g.width*g.range-length)<.0001,"tail aligns with actual length")
   check(g.fish_rect.size.y<=270*.208+.01,"fins fit mat vertically")
   check(g.fish_rect.position.x>=0 and g.fish_rect.end.x<=270,"original art not clipped")
   check(g.fish_rect.size.x>0 and g.fish_rect.size.y>0,"valid fish source")
 for h in [480,540,660]:
  var boxes:Dictionary=photo.layout(h)
  for key in ["scene","caption","save","close"]:
   check(boxes.panel.encloses(boxes[key]),"phone layout fits "+key)
  check(not boxes.save.intersects(boxes.close),"save close do not overlap")
 d.open(m);d.selected=0;d.draw(m,540)
 d.press(m,d.rects.records[1][0].get_center());check(photo.opened and photo.kind=="length","record row touch opens correct photo")
 preload("res://addons/reservoir/back_navigation.gd").close_top(m)
 check(not photo.opened and d.opened and d.selected==0,"Android back dismisses photo before dex")
 photo.open(m,0,"weight");photo.specimen={"grade":3,"legacy":true}
 var values:Dictionary=photo.text_values(m)
 check(values.length=="길이 미기록" and values.weight=="무게 미기록" and values.date=="날짜 미기록","legacy missing details not fabricated")
 check(photo.measure(m,0,photo.specimen,Rect2(0,0,270,270)).range==0,"legacy length has no invented ruler")
 var image:=Image.create(8,8,false,Image.FORMAT_RGBA8);image.fill(Color.CORAL)
 var folder:=OS.get_user_data_dir().path_join("isolated-photo-output")
 var result:Dictionary=photo.gallery.save(image,"record.png",folder)
 check(result.ok and Image.load_from_file(result.path).get_size()==Vector2i(8,8),"desktop PNG write produces decodable photo")
 Engine.print_error_messages=false
 check(not photo.gallery.save(image,"record.png","/proc/unsupported-photo-path").ok,"write failure is reported")
 Engine.print_error_messages=true
 check(d.serialize()==saved,"read/render/export operations preserve record bytes")
 photo.close();m.audio_feedback.dispose();m.queue_free();await process_frame
 print("RECORD_PHOTO_VERIFY failures=",failures," geometry_cases=400")
 quit(0 if failures.is_empty() else 1)
