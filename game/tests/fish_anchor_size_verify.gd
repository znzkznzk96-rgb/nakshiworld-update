extends SceneTree
class FishProbe extends "res://main.gd":
 func _fish_effect_rect(_r: Rect2, _c: Color) -> void: pass
 func _fish_effect_circle(_p: Vector2, _r: float, _c: Color) -> void: pass
var failures: Array=[]
func check(ok: bool,label: String) -> void:
 if not ok: failures.append(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var m=FishProbe.new();m.SET.music=0;m.SET.sfx=0;root.add_child(m)
 await process_frame;m.set_process(false);m.S={"phase":"fight"};m.visibility_flash=0
 for sp in 60:
  check((m._fish_texture_u(sp,0)<m._fish_texture_u(sp,1))==(sp>=40),"texture head orientation %d"%sp)
  for face in [-1.0,1.0]:
   for beh in ["swim","run","thrash","hanging"]:
    m.ui_commands=[]
    m._shadow_fish(Vector2(135,310),0,0,0,beh,false,2.2,{},0,sp,face,1)
    check(m.fish_mouth.distance_to(m.aura.pts[0])<m.aura.L*.04,"mouth anchored at geometry head")
    var body=m.ui_commands.filter(func(c):return c[0]=="polygon" and c[4]==m.fish_tex[sp])
    check(not body.is_empty(),"body drawn")
    check(absf(body[0][3][0].x-m._fish_texture_u(sp,0))<.0001,"head UV on actual head edge")
 for pair in [[2,8],[25,39],[45,59]]:
  var small: float=m._fish_display_length(0,2.2,false,pair[0])
  var large: float=m._fish_display_length(4,2.2,false,pair[1])
  check(large>small*1.8,"species body size contrast")
 for sp in 60:
  check(m._fish_display_length(0,m._fight_fish_scale(1.4),false,sp)>m._fish_display_length(0,m._fight_fish_scale(.8),false,sp),"individual size retained")
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print("FISH_ANCHOR_SIZE_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
