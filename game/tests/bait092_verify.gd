extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String):
 if not ok: failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func touch(m,p,down):
 var e=InputEventScreenTouch.new();e.position=p;e.pressed=down;e.index=0;m._unhandled_input(e)
func mouse(m,p,down,device=0):
 var e=InputEventMouseButton.new();e.position=p;e.pressed=down;e.button_index=MOUSE_BUTTON_LEFT;e.device=device;m._unhandled_input(e)
func run():
 var m=load("res://main.gd").new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 m.title_open=false;m.trans={};m.scene="fish";m.TUT.done=true;m.lesson_open=false;m.market_open=false;m.settings_open=false;m.V.shop="";m.S={"phase":"idle"}
 var b=m.bait_picker;var shop=m.region_shop;shop.restore({});m.bait=12;shop.stocks[1]=8;shop.stocks[2]=3
 for h in [480,660]:
  root.content_scale_size=Vector2i(270,h);root.size=Vector2i(540,h*2);await process_frame;m._layout()
  b.draw_button(m,h-108-m.bot_pad);m._draw_menu(h-108-m.bot_pad)
  check(b.button.size==Vector2(32,32) and b.button.end.x<90,"small bait stays beside left menu")
  check(not b.button.grow(2).intersects(m.ui_rects.menu),"menu and bait hitboxes separated")
  check(b.panel.position.y>m.top_y+70 and b.panel.end.y<b.button.position.y,"popup fits short and tall screens")
  var pos: Vector2=b.button.get_center()+Vector2(m.ox,0)
  mouse(m,pos,true,-1);check(not b.opened,"emulated first mouse cannot toggle bait")
  touch(m,pos,true);touch(m,pos,false);mouse(m,pos,false,-1)
  check(b.opened and m.S.phase=="idle","native bait opens once without casting")
  var choose: Vector2=b.cells[1].get_center()+Vector2(m.ox,0)
  mouse(m,choose,true,-1);touch(m,choose,true);touch(m,choose,false);mouse(m,choose,false,-1)
  check(not b.opened and shop.selected_bait==1 and shop.stocks[1]==8,"select persists without spending stock")
  b.opened=true;var outside=Vector2(240,250)+Vector2(m.ox,0);touch(m,outside,true);touch(m,outside,false)
  check(not b.opened and m.S.phase=="idle","outside dismiss does not cast")
  b.opened=true;check(not b.select(m,3) and b.opened,"locked or empty choice remains disabled")
  check(b.select(m,-1),"explicit bare hook selection")
  check(shop.take_bait(m)==0.85 and m.bait==12 and shop.stocks[1]==8,"bare hook never consumes owned bait")
  shop.restore(shop.serialize());check(shop.selected_bait==-1,"bare choice survives save format roundtrip")
  shop.selected_bait=1;shop.stocks[1]=1;check(shop.take_bait(m)==1.0 and shop.last_bait==1,"selected final bait consumed once")
  check(shop.take_bait(m)==0.85 and shop.last_bait==-1 and m.bait==12,"depletion does not auto-consume other bait")
  shop.stocks[1]=8;m.S={"phase":"fight"};check(not b.select(m,0),"cannot swap during active fishing")
  m.S={"phase":"idle"};m.scene="village";m.text_items=[];m.mailbox.draw_button(m);m.guide.draw_button(m)
  for item in m.text_items:
   if str(item[2]) in ["우편","가이드"]:
    var box: Rect2=m.mailbox.button if item[2]=="우편" else m.guide.button
    check(item[1].y>box.end.y and item[1].y<h-m.bot_pad-49,"labels outside frames and above navigation")
  m.scene="fish"
 m.development_preview=false;shop.selected_bait=-1;m._save_game();shop.selected_bait=2;m._load_game();check(shop.selected_bait==-1,"real save/load preserves bare hook choice")
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print("BAIT092_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
