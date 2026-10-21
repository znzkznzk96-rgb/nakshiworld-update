extends SceneTree
class FishProbe extends "res://main.gd":
	func _fish_effect_rect(_r: Rect2, _c: Color) -> void: pass
	func _fish_effect_circle(_p: Vector2, _r: float, _c: Color) -> void: pass
var failures: Array=[]
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m=FishProbe.new();m.SET.sfx=0;m.SET.music=0;m.title_open=false;root.add_child(m)
	await process_frame;m.set_process(false);m.oy=41;m.visibility_flash=0;m.S={"phase":"fight"}
	for sp in m.FISH_NAME.size():
		for action in ["swim","charge","circle","jump","thrash"]:
			for grade in [0,4]:
				m.ui_demo=false;m.ui_commands=[]
				m._shadow_fish(Vector2(150.3,310.7),0,grade,320,action,false,2.2,{},1.3,sp,1,1)
				var body=m.ui_commands.filter(func(c): return c[0]=="polygon" and c[4]==m.fish_tex[sp])
				check(body.size()==24,"full body on display surface")
				check(m.ui_commands[-1][4]==m.fish_tex[sp],"body after halo")
				for command in body:
					for point in command[1]: check(point.is_finite(),"finite geometry")
				var mouth=m.fish_mouth
				check(mouth.is_finite() and mouth.y<340,"mouth stays in world coordinates")
				# Same input through lesson must keep the rigid head, only add world offset.
				m.ui_demo=true;m.ui_commands=[]
				m._shadow_fish(Vector2(150.3,310.7),0,grade,320,action,false,2.2,{},1.3,sp,1,1)
				var demo=m.ui_commands.filter(func(c): return c[0]=="polygon" and c[4]==m.fish_tex[sp])
				for i in 10:
					for j in 3: check(body[i][1][j].is_equal_approx(demo[i][1][j]+Vector2(0,41)),"head matches lesson and world offset")
	m.ui_demo=false;m.S={"phase":"idle"};print("FISH_SURFACE_VERIFY failures=",failures)
	m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
