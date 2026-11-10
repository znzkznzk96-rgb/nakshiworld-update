extends SceneTree
const Close=preload("res://addons/reservoir/close_control.gd")
var failures:Array=[]
func check(ok:bool,s:String):
 if not ok:failures.append(s);push_error(s)
func _initialize():call_deferred("run")
func run():
 var m=load("res://main.gd").new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false;m.scene="village";m.S={"phase":"idle"}
 var rect:=Rect2(210,30,22,23);m.ui_commands=[];Close.draw(m,rect);var explicit:Array=m.ui_commands.duplicate(true)
 m.ui_commands=[];m._ui_texture(m.icons.close,rect.position)
 check(explicit==m.ui_commands,"legacy icon callers use exact shared artwork and size")
 var bounds:=Rect2()
 for c in m.ui_commands:
  var r:Rect2=c[2] if c[0]=="region" else c[1]
  bounds=bounds.merge(r) if bounds.size!=Vector2.ZERO else r
 check(bounds==rect,"visual stays in fixed22x23 box")
 for height in [480,540,660]:
  m.V.open_shop(m,"forge");m.expedition.opened="explore";m.expedition.choosing_slot=0;m.expedition.data.soldiers=[]
  m.text_items=[];m.ui_commands=[];m.expedition.draw_roster(m,100,height-44)
  var close:Rect2=m.expedition.rects.roster_close
  check(close.size.x==100 and close.position.y>300,"narrow selection sheet uses bottom text close")
  check(not close.intersects(m.expedition.rects.prev) and not close.intersects(m.expedition.rects.next),"close separated from paging")
 m.expedition.opened=""
 print("CLOSE_CONTROLS_VERIFY failures=",failures)
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
