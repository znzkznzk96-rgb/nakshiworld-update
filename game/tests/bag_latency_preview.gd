extends SceneTree
var gaps: Array=[]
var reports: Array=[]
func _initialize() -> void: call_deferred("run")
func sample(m,label: String,seconds: float) -> void:
 var previous: int=Time.get_ticks_usec();var until: int=previous+int(seconds*1000000);gaps=[]
 while Time.get_ticks_usec()<until:
  await process_frame
  var now: int=Time.get_ticks_usec();gaps.append((now-previous)/1000.0);previous=now
 gaps.sort();reports.append({"phase":label,"frames":gaps.size(),"max_ms":gaps[-1],"p95_ms":gaps[int(gaps.size()*0.95)]});print(reports[-1])
func run() -> void:
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_size=Vector2i(270,660);root.size=Vector2i(628,1536)
 var layer=CanvasLayer.new();layer.layer=10;root.add_child(layer)
 var txt=Node2D.new();txt.set_script(load("res://text_layer.gd"));layer.add_child(txt)
 var m=load("res://main.gd").new();m.development_preview=true;m.text_layer=txt;root.add_child(m);await process_frame
 m.title_open=false;m.title_screen.leaving=false;m.lesson_open=false;m.trans={};m.TUT.done=true;m.SET.sfx=0;m.SET.music=0;m.bag=[]
 for i in 180:m.bag.append({"sp":i%17,"grade":i%5,"w":0.1,"len":10.0,"price":100})
 m.scene="village";m.S={"phase":"idle"};m.V.shop="";m.market_open=false
 await sample(m,"baseline",1)
 m.market_open=true;m.market_sell=false;m.inventory.tab="fish";await sample(m,"cold_bag",6)
 m.inventory.open_group(0,0);await sample(m,"cold_detail",6)
 var t: int=Time.get_ticks_usec();m.inventory.detail_press(m.inventory.list_view.detail_rects.close.get_center());print("DETAIL_CLOSE_US ",Time.get_ticks_usec()-t," selected=",m.inventory.selected)
 await sample(m,"closed_detail",2)
 m.inventory.press(m,m.inventory.rects.close.get_center());print("BAG_CLOSED ",not m.market_open)
 var out: String=OS.get_cmdline_user_args()[0];FileAccess.open(out,FileAccess.WRITE).store_string(JSON.stringify(reports,"  "))
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit()
