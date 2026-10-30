extends SceneTree
var failures:Array=[]
func check(ok:bool,s:String):
 if not ok:failures.append(s);push_error(s)
func _initialize():call_deferred('run')
func actions(v)->Array:return v.rects.rows.map(func(row):return row[1])
func paint(m,h:int):
 m.text_items=[];m.ui_commands=[];m.V.draw_shop(m,h)
 for row in m.V.rects.rows:check(m.V.rects.panel.encloses(row[0]),'button within panel '+str(h)+' '+row[1])
func run():
 var m=load('res://main.gd').new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false;m.scene='village';m.S={'phase':'idle'}
 var v=m.V;v.open_shop(m,'forge');m.equipment.rods=[0];m.rod_owned=0;m.rod_lv=0;m.equipment.rod_equipped=true;m.gold=3998;m.souls=15
 for h in [480,540,660]:
  v.forge_tab='rods';v._act(m,'rodselect:1');paint(m,h)
  check(v.rod_page==1 and m.gold==3998 and m.rod_lv==0,'selection does not purchase/equip')
  check(not 'rod:1' in actions(v),'insufficient funds disables buy')
  m.gold=8000;paint(m,h);check('rod:1' in actions(v),'funded next rod available')
  v._act(m,'rodselect:5');paint(m,h);check(not 'rod:5' in actions(v),'locked rod disabled')
  m.gold=3998;v.forge_tab='upgrade';m.forge_lv=0;paint(m,h);check('forge' in actions(v),'low-level upgrade enabled')
  m.forge_lv=3;m.protection_tickets=1;paint(m,h);check('forge_protect' in actions(v) and 'forge_ticket' in actions(v),'risk protection controls present')
  m.equipment.rod_equipped=false;paint(m,h);check(not 'forge' in actions(v),'unequipped cannot upgrade');m.equipment.rod_equipped=true
  m.forge_lv=5;paint(m,h);check(not 'forge' in actions(v),'max cannot upgrade')
 print('FORGE_LAYOUT_VERIFY failures=',failures);m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
