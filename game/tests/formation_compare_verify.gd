extends SceneTree
var failures:Array=[]
func check(ok:bool,msg:String):
 if not ok:failures.append(msg);push_error(msg)
func _initialize():call_deferred('run')
func paint(m):
 m.text_items=[];m.ui_commands=[];m.expedition.rects={};m.expedition.draw_formation(m,139,650)
func run():
 var m=load('res://main.gd').new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 var v=m.expedition;var d=v.data;d.restore({});d.soldiers=[];d.team=[];d.battle={}
 for i in 9:
  var u=d.add_unit(i%8,1,[0,0,0])
  if i<3:d.team.append(u.uid)
 v.open(m,'explore');v.explore_tab=1;paint(m)
 var original:Array=d.team.duplicate();var selected:int=d.soldiers[3].uid
 v.press(m,v.rects['formation_unit:%d'%selected].get_center());check(v.formation_uid==selected and d.team==original,'select opens without mutation')
 paint(m);v.press(m,v.formation_ui.modal_rects['target:0'].get_center());paint(m);check(d.team==original,'target selection does not mutate')
 v.press(m,v.formation_ui.modal_rects.cancel.get_center());check(v.formation_uid<0 and d.team==original,'cancel keeps formation')
 v.formation_uid=selected;v.formation_target=0;paint(m);v.press(m,v.formation_ui.modal_rects.confirm.get_center());check(d.team==[selected,original[1],original[2]],'confirm replaces exact slot')
 v.formation_uid=original[2];v.formation_target=0;paint(m);v.press(m,v.formation_ui.modal_rects.confirm.get_center());check(d.team==[original[2],original[1],selected],'existing soldier swaps with no duplicate')
 d.team=[];v.formation_uid=original[0];v.formation_target=2;paint(m);v.press(m,v.formation_ui.modal_rects.confirm.get_center());check(d.team==[original[0]],'empty team appends safely')
 d.team=original.duplicate();d.start(1,1000);v.formation_uid=selected;paint(m);v.press(m,v.formation_ui.modal_rects.confirm.get_center());check(d.team==original,'active expedition confirmation blocked')
 print('FORMATION_COMPARE_VERIFY failures=',failures);m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
