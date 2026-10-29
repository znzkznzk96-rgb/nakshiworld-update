extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
 if not ok:failures.append(label);push_error(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var m=load("res://main.gd").new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false;m.scene="village";m.S={"phase":"idle"};m.trans={};m.TUT.done=true
 var c=m.V.commerce;m.gold=10000;m.bait=0;m.region_shop.restore({});m.V.open_shop(m,"up")
 c.request(m.V,m,"bait:0:5");check(c.confirm(m.V,m),"purchase succeeds")
 check(m.bait==5 and m.gold==9975 and c.notice_delta==-25 and m.toast_t==0,"purchase feedback does not change economics or global toast")
 var before=m.gold;c.confirm(m.V,m);check(m.gold==before,"no duplicate purchase")
 for h in [480,660]:
  m.text_items=[];m.V.draw_shop(m,h);c.draw(m.V,m,h)
  check(m.V.rects.panel.encloses(c.notice_bounds),"feedback stays inside shop")
  check(not c.notice_bounds.intersects(Rect2(8,m.top_y+69,254,72)),"feedback avoids village expedition strip")
 c.report(m,"판매 완료 · +120 비늘",120);check(c.notice_delta==120,"new transaction replaces old notice")
 m.V.shop="";m.text_items=[];c.draw_currency_delta(m)
 check(m.text_items.any(func(x):return x[2]=="+120"),"closed shop shows only currency delta")
 m.ui_clock+=2;m.text_items=[];c.draw_currency_delta(m);check(m.text_items.is_empty(),"currency feedback expires")
 m.V.open_shop(m,"up");m.gold=0;c.request(m.V,m,"bait:0:5");check(not c.confirm(m.V,m) and m.gold==0,"insufficient funds cannot charge");c.pending={}
 m.show_toast("보관통이 가득해요");check(m.toast_t==0 and c.notice=="보관통이 가득해요","shop error stays local")
 m.V.shop="";m.scene="fish";m.menu_open=false;m.settings_open=false;m.market_open=false;m.guide.opened=false;m.mailbox.opened=false;m.personal_dex.opened=false
 for slot in 4:
  var key=m.region_shop.part_key(0,slot)
  if key not in m.parts_owned:m.parts_owned.append(key)
  if key not in m.equipment.active_parts:m.equipment.active_parts.append(key)
 var v=m.expedition;v.opened="";v.data.battle={"status":"win","round":1,"progress":100};v.result_notice=6
 var saved=v.data.serialize().duplicate(true)
 for outcome in ["win","lose"]:
  v.data.battle.status=outcome;m.text_items=[];v.draw_fishing_strip(m)
  check(v.fishing_strip_visible(m),"completed expedition reuses progress strip")
  check(not v.fishing_strip_rect(m).intersects(Rect2(7,m.top_y+73,256,48)),"completion avoids owner gauge")
  check(not m.text_items.is_empty() and m.text_items.all(func(x):return "마을에서 결과 확인" in x[2]),"one completion line")
  var count=m.text_items.size();v.draw_result_notice(m);check(m.text_items.size()==count,"no duplicate overlay")
 v.data.battle.status="win";check(v.data.serialize()==saved,"drawing leaves result and rewards intact")
 for modal in ["menu_open","settings_open","market_open"]:
  m.set(modal,true);check(not v.fishing_strip_visible(m),"hidden during "+modal);m.set(modal,false)
 v.result_notice=0;check(not v.fishing_strip_visible(m),"completion expires")
 v.data.battle.status="running";check(v.fishing_strip_visible(m),"running progress remains")
 c=null;v=null;m.audio_feedback.dispose();m.queue_free();await process_frame
 print("NOTIFICATION091_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
