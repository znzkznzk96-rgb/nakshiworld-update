extends SceneTree
const Back=preload("res://addons/reservoir/back_navigation.gd")
var failures:Array=[]
var cases:=0
func check(ok:bool,label:String):
 cases+=1
 if not ok:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func reset(m):
 m.capture_robot.opened=false;m.expedition.opened="";m.expedition.formation_uid=-1;m.expedition.choosing_slot=-1;m.expedition.management.confirm=false
 m.personal_dex.opened=false;m.personal_dex.selected=-1;m.equipment.pending_sale="";m.guide.opened=false;m.mailbox.opened=false;m.mailbox.detail="";m.mailbox.deleting=false
 m.V.commerce.pending={};m.inventory.pouch.opened=false;m.inventory.selected=-1;m.settings_open=false;m.reset_confirm=false;m.market_open=false;m.V.shop="";m.V.pick_slot=-1;m.V.aqua_manage=false;m.V.bundle_preview.reward_open=false;m.V.bundle_preview.bulk_open=false;m.V.bundle_preview.selected=-1;m.bait_picker.opened=false;m.lesson_open=false;m.menu_open=false;m.scene="village";m.trans={};m.title_open=false
func run():
 var m=load("res://main.gd").new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 m.gold=10000;m.pearl=5;m.souls=100
 var serialized:String=JSON.stringify([m.gold,m.pearl,m.souls,m.bag,m.equipment.serialize(),m.expedition.data.serialize(),m.progression.serialize()])
 reset(m);m.V.shop="hall";m.market_open=true;m.inventory.selected=0;m.V.commerce.pending={"action":"buy"};m.equipment.pending_sale="rod:0";m.personal_dex.opened=true;m.personal_dex.selected=1;m.expedition.opened="explore";m.capture_robot.opened=true
 Back.handle(m);check(not m.capture_robot.opened and m.expedition.opened=="explore","robot top only")
 Back.handle(m);check(m.expedition.opened=="" and m.personal_dex.opened,"expedition before dex")
 Back.handle(m);check(m.personal_dex.selected==-1 and m.personal_dex.opened,"dex detail before list")
 Back.handle(m);check(not m.personal_dex.opened and m.equipment.pending_sale!="","dex list before confirmation")
 Back.handle(m);check(m.equipment.pending_sale=="" and not m.V.commerce.pending.is_empty(),"sale confirmation cancels only")
 Back.handle(m);check(m.V.commerce.pending.is_empty() and m.inventory.selected==0,"purchase confirmation cancels only")
 Back.handle(m);check(m.inventory.selected==-1 and m.market_open,"inventory detail before bag")
 Back.handle(m);check(not m.market_open and m.V.shop=="hall","bag before shop")
 Back.handle(m);check(m.V.shop=="","shop closes")
 reset(m);m.V.shop="museum";var b=m.V.bundle_preview;b.reward_open=true;b.bulk_open=true;b.selected=2;b.bulk_plan=[1]
 Back.handle(m);check(not b.reward_open and b.bulk_open,"reward dialog before donation")
 Back.handle(m);check(not b.bulk_open and b.selected==2 and b.bulk_plan.is_empty(),"donation cancels without donating")
 Back.handle(m);check(b.selected==-1 and m.V.shop=="museum","museum detail before main")
 reset(m);m.settings_open=true;m.reset_confirm=true;m.set_view="license"
 Back.handle(m);check(not m.reset_confirm and m.settings_open,"reset confirmation canceled")
 Back.handle(m);check(m.set_view=="main" and m.settings_open,"settings subsection before settings")
 Back.handle(m);check(not m.settings_open,"settings closes")
 reset(m);m.mailbox.opened=true;m.mailbox.detail="1.20";m.mailbox.deleting=true
 Back.handle(m);check(m.mailbox.detail=="" and m.mailbox.opened,"letter before mailbox")
 Back.handle(m);check(not m.mailbox.deleting and m.mailbox.opened,"mail delete mode canceled")
 reset(m);m.guide.opened=true;m.guide.screen="article"
 Back.handle(m);check(m.guide.screen=="topics" and m.guide.opened,"guide article back")
 Back.handle(m);check(m.guide.screen=="home" and m.guide.opened,"guide topics back")
 Back.handle(m);check(not m.guide.opened,"guide home closes")
 reset(m);m.expedition.opened="management";m.expedition.management.confirm=true
 Back.handle(m);check(not m.expedition.management.confirm and m.expedition.opened=="management","salvage confirmation canceled")
 Back.handle(m);check(m.expedition.opened=="alchemy" and m.expedition.tab==2,"management detail back")
 reset(m);m.expedition.opened="merge_confirm"
 Back.handle(m);check(m.expedition.opened=="alchemy" and m.expedition.tab==1,"merge confirmation canceled")
 reset(m);m.V.shop="forge";m.V.enhancement.phase="roll"
 Back.handle(m);check(m.V.shop=="forge","existing forge busy guard")
 m.V.enhancement.phase="";reset(m)
 m.scene="fish";m.S={"phase":"fight","tension":65};m.holding=true
 check(not Back.handle(m) and m.S.phase=="fight" and m.holding,"base back neither quits nor mutates fight")
 reset(m);m.market_open=true
 var field:=LineEdit.new();root.add_child(field);field.grab_focus();await process_frame
 Back.handle(m);check(not field.has_focus() and m.market_open,"keyboard focus dismissed before bag")
 field.queue_free()
 reset(m);m.expedition.opened="explore";m.expedition.formation_uid=0
 Back.handle(m);check(m.expedition.formation_uid==-1 and m.expedition.opened=="explore","formation comparison closes first")
 reset(m);m.V.shop="hall";m.market_open=true
 root.go_back_requested.emit();check(not m.market_open and m.V.shop=="hall","real Android window event routed")
 root.go_back_requested.emit();check(m.V.shop=="hall","duplicate event same frame dismissed once")
 await process_frame;m._handle_back_request();check(m.V.shop=="","next physical press closes next window")
 reset(m);m.market_open=true;var key:=InputEventKey.new();key.keycode=KEY_ESCAPE;key.pressed=true;key.echo=true;m._unhandled_input(key);check(m.market_open,"ESC repeat ignored")
 await process_frame;key.echo=false;m._unhandled_input(key);check(not m.market_open,"ESC shares navigation")
 check(not quit_on_go_back,"Android auto quit disabled at runtime")
 check(serialized==JSON.stringify([m.gold,m.pearl,m.souls,m.bag,m.equipment.serialize(),m.expedition.data.serialize(),m.progression.serialize()]),"no purchases/reset/rewards/roster or save schema mutations")
 print("ANDROID_BACK_VERIFY failures=",failures," cases=",cases)
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
