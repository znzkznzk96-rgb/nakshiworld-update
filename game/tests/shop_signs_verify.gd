extends SceneTree
var failures:Array=[]
func check(ok:bool,s:String):
 if not ok:failures.append(s);push_error(s)
func _initialize():call_deferred("run")
func run():
 var m=load("res://main.gd").new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false;m.scene="village";m.S={"phase":"idle"}
 var v=m.V;m.equipment.rods=[0,1,2];m.rod_owned=2;m.rod_lv=2;m.equipment.rod_equipped=true;m.gold=32075
 for h in [480,540,660]:
  for shop in ["up","work","harbor","museum","bait","hall","forge","aqua"]:
   v.open_shop(m,shop);m.ui_commands=[];m.text_items=[];v.draw_shop(m,h)
   var header_parts:int=0
   for cmd in m.ui_commands:
    if cmd[0]=="region" and cmd[1].resource_path=="res://art/shop_repair/header.png":header_parts+=1
   check(header_parts==9,"shared header %s %d"%[shop,h])
   check(Rect2(0,0,270,h).encloses(v.bundle_preview.rects.close) if shop=="museum" else v.rects.panel.encloses(v.rects.close),"close remains in panel %s %d"%[shop,h])
  v.open_shop(m,"forge")
  for selected in [0,3,5]:
   v.rod_page=selected;m.ui_commands=[];m.text_items=[];v.draw_shop(m,h)
   var cards:Array=[]
   for row in v.rects.rows:
    if str(row[1]).begins_with("rodselect:"):cards.append(row[0])
   check(cards.size()==6,"six choices")
   for card in cards:
    var labels:int=0
    for it in m.text_items:
     if not card.has_point(it[1]):continue
     var f:Font=it[0];var sc:float=it[7];var px:int=it[5]
     var width:float=f.get_string_size(it[2],HORIZONTAL_ALIGNMENT_LEFT,-1,px).x*sc
     var xx:float=it[1].x+(it[4]*sc-width)/2 if it[3]==HORIZONTAL_ALIGNMENT_CENTER else it[1].x
     var bounds:=Rect2(xx,it[1].y-f.get_ascent(px)*sc,width,(f.get_ascent(px)+f.get_descent(px))*sc)
     check(card.grow(-8).encloses(bounds),"glyphs clear frame %d %s %s"%[h,it[2],bounds])
     labels+=1
    check(labels>=2,"name and state visible")
   check(m.gold==32075 and m.rod_lv==2,"render read only")
 print("SHOP_SIGNS_VERIFY failures=",failures)
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
