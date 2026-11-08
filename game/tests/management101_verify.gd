extends SceneTree
var failures:Array=[]
func check(ok:bool,msg:String):
 if not ok:failures.append(msg);push_error(msg)
func _initialize():call_deferred('run')
func run():
 var m=load('res://tests/pouch_test_main.gd').new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 var v=m.expedition;var d=v.data;d.restore({})
 for id in 15:
  var u=d.add_unit(id,1,[0,0,0]);var element:int=d.native_element(u.uid);var old:Array=d.souls.duplicate()
  check(element==int(d.catalog.soldiers[id].elements[0]),'own element')
  var q:Dictionary=d.salvage(u.uid)
  check(q.gold==250 and q.souls==1 and d.souls[element]==old[element]+1,'exact salvage reward')
  check(d.salvage(u.uid).is_empty(),'no repeat salvage')
 var u=d.add_unit(2,1,[0,0,0]);u.locked=true;check(d.salvage(u.uid).is_empty(),'locked protected');u.locked=false
 d.team=[u.uid];check(d.salvage(u.uid).is_empty(),'team protected');d.team=[]
 d.pending={'kind':'craft','uid':u.uid};check(d.salvage(u.uid).is_empty(),'pending protected');d.pending={}
 v.opened='management';v.management.uid=u.uid;v.management.confirm=true
 var gold:int=m.gold;var souls:Array=d.souls.duplicate()
 v.rects={};v.management.detail(m)
 v.press(m,v.rects.salvage_cancel.get_center());check(d.souls==souls and m.gold==gold and not d.unit(u.uid).is_empty(),'cancel leaves inventory')
 m.fail_saves=true;v.management.confirm=true;v.management.detail(m);v.press(m,v.rects.salvage_confirm.get_center())
 check(not d.unit(u.uid).is_empty() and m.gold==gold and d.souls==souls,'failed save rolls back all rewards')
 m.fail_saves=false
 v.management.confirm=true;v.management.detail(m);v.press(m,v.rects.salvage_confirm.get_center())
 check(d.unit(u.uid).is_empty() and m.gold==gold+250 and d.souls[2]==souls[2]+1,'confirmed transaction')
 var u2=d.add_unit(0,1,[0,0,0]);d.pending={'kind':'craft','uid':u2.uid};v.management.result(m,u2)
 v.press(m,v.rects.pending_again.get_center());check(v.tab==0 and d.pending.is_empty(),'return to alchemy')
 for h in [480,540,660]:
  root.size=Vector2i(270,h);v.open(m,'alchemy');v.tab=1;v.draw(m,h)
  for r in v.rects.values():check(r.position.y>=0 and r.end.y<=h,'controls fit screen')
 # A-layout list must expose distinct rows, and scrolling reaches the last unit.
 d.restore({})
 for i in 15:
  var a=d.add_unit(i,1,[0,0,0]);a.level=3
 root.size=Vector2i(270,660);v.open(m,'alchemy');v.tab=1;v.draw(m,660)
 var first_rect:Rect2=v.rects['select:%d'%d.soldiers[0].uid]
 var second_rect:Rect2=v.rects['select:%d'%d.soldiers[1].uid]
 check(first_rect.position.x==second_rect.position.x and first_rect.end.y<=second_rect.position.y,'A uses distinct full-width list rows')
 v.press(m,first_rect.get_center());v.draw(m,660)
 check(v.selected.size()==1,'first material selected')
 v.press(m,second_rect.get_center());v.draw(m,660)
 check(v.selected.size()==2,'second material selected')
 v.roster_scroll=v.roster_max_scroll;v.draw(m,660)
 check(v.rects.has('select:%d'%d.soldiers[-1].uid),'scroll reaches last soldier')
 check(v.management.SKILLS.size()==15,'15 skill icons')
 for key in v.management.SKILLS:
  var icon=load('res://art/ui/soldier_skills/'+key+'.png')
  check(icon is Texture2D and icon.get_size()==Vector2(64,64),'skill icon loads: '+key)
 # Exact shortage information without spending or changing inventory.
 v.selected=[d.soldiers[0].uid,d.soldiers[1].uid];d.soldiers[0].level=3;d.soldiers[1].level=3
 d.souls=[0,0,0,0,0];m.gold=0;v.opened="merge_confirm"
 for height in [480,540,660]:
  m.text_items=[];m.ui_commands=[];v.draw(m,height)
  check(m.text_items.any(func(t):return "필요" in str(t[2]) and "보유" in str(t[2]) and "부족" in str(t[2])),"merge shows need owned and exact shortage")
  check(m.text_items.any(func(t):return t[2]=="재료 부족"),"unaffordable merge button explains disabled state")
 check(d.souls==[0,0,0,0,0] and m.gold==0,"rendering shortages never spends resources")
 m.text_items=[];m.ui_commands=[];var box:=Rect2(20,200,180,40)
 m._ui_style_box(m.sb_chip,box);m._text("하단 여백",Vector2(30,239),9,Color("493421"),false,150)
 check(m.text_items[-1][1].y<=234,"shared card text keeps bottom padding")
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print('MANAGEMENT101_VERIFY failures=',failures);quit(0 if failures.is_empty() else 1)
