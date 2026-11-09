extends SceneTree
var failures:Array=[]
func _initialize()->void:call_deferred("run")
func at(m,key:String,beh:String,k:float)->float:
 var elapsed:float=0
 for step in m.LESSON[key].anim:
  if step[0]==beh:return elapsed+m.lesson_step_duration(key,step)*k
  elapsed+=m.lesson_step_duration(key,step)
 return 0
func run()->void:
 var out:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
 var text:=Node2D.new();text.set_script(load("res://text_layer.gd"));ui.add_child(text)
 var m=load("res://main.gd").new();m.text_layer=text;m.title_open=false;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame
 m.development_preview=true;m.set_process(false);m.title_open=false;m.TUT.done=true;m.TUT.seen=m.BOOK_KEYS.duplicate();m.trans={};m._switch_scene("village");m.V.shop="";m.settings_open=true;m.set_view="book";m.S={"phase":"idle","sp":6};m.ui_clock=30
 var cases:Array=[["swim","swim","swim"],["tell","tell","run"],["rest","rest","rest"],["jump","rise","land"],["spike","spike_warn","spike"],["dive","nose","dive"],["charge","turn","charge"],["clone","clone","clone"],["sulk","sulk","sulk"],["circle","circle","circle"],["thrash","thrash","thrash"],["skim","skim","rest"]]
 for height in [480,660]:
  root.content_scale_size=Vector2i(270,height);root.size=Vector2i(540,height*2);await process_frame;m._layout()
  var board:=Image.create(1080,2256,false,Image.FORMAT_RGBA8);board.fill(Color("183548"))
  for row in cases.size():
   var c:Array=cases[row]
   for col in 3:
    m.open_card(c[0],"book")
    var beh:String=c[1] if col<2 else c[2]
    var k:float=[.05,.5,.66][col]
    if c[0]=="clone":k=[.01,.125,.5][col]
    m.lesson_clock=30;m.ui_clock=30+at(m,c[0],beh,k)
    m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
    var bounds:Rect2=m.lesson_telegraph.icon_bounds
    if not bounds.size.is_zero_approx() and not Rect2(45,166,180,94).encloses(bounds):failures.append("cue outside demo "+c[0])
    if c[0]=="charge" and beh=="charge" and not bounds.size.is_zero_approx():failures.append("charge ring returned")
    var image:Image=root.get_texture().get_image()
    board.blit_rect(image,Rect2i(90,332,360,188),Vector2i(col*360,row*188))
    if col==1 and c[0] in ["tell","charge","spike","clone"]:image.save_png(out.path_join("%s-h%d.png"%[c[0],height]))
   m.close_card(true)
  board.save_png(out.path_join("book-board-h%d.png"%height))
 print("BODY_BOOK_TELEGRAPH_PREVIEW failures=",failures)
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
