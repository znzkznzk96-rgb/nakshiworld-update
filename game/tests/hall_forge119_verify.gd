extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String):
 if not ok:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func paint(m,h:int):
 m.text_items=[];m.ui_commands=[];m.V.draw_shop(m,h)
 for row in m.V.rects.rows:check(m.V.rects.panel.encloses(row[0]),"action inside panel %d %s"%[h,row[1]])
 for item in m.text_items:
  if item[1].y>m.V.rects.panel.position.y:check(item[1].y<m.V.rects.panel.end.y-2,"text inside panel %s"%str(item[2]))
func run():
 var m=load("res://main.gd").new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false;m.TUT.done=true;m.scene="village";m.S={"phase":"idle"}
 m.equipment.rods=[0,1,2];m.rod_owned=2;m.rod_lv=2;m.equipment.rod_equipped=true;m.gold=32075;m.souls=100;m.region_shop.unlocked=[0,1,2]
 var v=m.V;var original:Dictionary=m._save_payload().duplicate(true) if m.has_method("_save_payload") else {}
 for height in [480,540,660]:
  v.open_shop(m,"forge");check(v.rod_page==3 and m.rod_lv==2,"opening previews next rod without equipping")
  for selected in 6:
   v.rod_page=selected;paint(m,height)
   var actions:Array=v.rects.rows.map(func(row):return row[1])
   check(not "rod:3" in actions and not "rod:5" in actions,"insufficient or locked rods cannot be bought")
   check(m.gold==32075 and m.rod_lv==2,"browsing never purchases or equips")
  m.gold=2800000;v.rod_page=3;paint(m,height)
  check(v.rects.rows.any(func(row):return row[1]=="rod:3"),"funded next rod purchase remains available")
  m.gold=32075
  for tab in ["upgrade","robot"]:v.forge_tab=tab;paint(m,height)
  for lv in [0,2,6,12]:
   m.pond_cap_lv=lv;m.pond_regen_lv=lv;m.pond_stock=m.pond_max();m.pond_overflow=110;v.open_shop(m,"hall");paint(m,height)
   var before:Array=[m.gold,m.pond_cap_lv,m.pond_regen_lv,m.pond_stock,m.pond_overflow]
   paint(m,height);check(before==[m.gold,m.pond_cap_lv,m.pond_regen_lv,m.pond_stock,m.pond_overflow],"hall rendering never changes facility state")
   check(v.active_style.panel==m.sb_panel,"approved common wooden frame reused")
 print("HALL_FORGE119_VERIFY failures=",failures)
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
