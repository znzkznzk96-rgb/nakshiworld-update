extends SceneTree
const Baseline=preload("res://tests/rare_halo_baseline.gd")
class Current extends "res://main.gd":
	func _draw_action_wake(_c: Vector2, _l: float, _h: float, _f: float, _b: String, _t: float) -> void: pass
class Surface extends Node2D:
	var commands: Array=[]
	func _draw() -> void:
		preload("res://addons/reservoir/ui_surface.gd").paint(self,commands)
var failures: Array=[]
func _initialize() -> void: call_deferred("run")
func expand(commands: Array) -> Array:
	var result: Array=[]
	for c in commands:
		if c[0]=="triangles":
			for i in range(0,c[1].size(),3):
				var pts:=PackedVector2Array();var uv:=PackedVector2Array()
				for j in 3: pts.append(c[2][c[1][i+j]]);uv.append(c[4][c[1][i+j]])
				result.append([pts,c[3][0],uv])
		elif c[0]=="polygon": result.append([c[1],c[2][0],c[3]])
	return result
func run() -> void:
	var old=Baseline.new();var new=Current.new()
	for m in [old,new]:
		m.SET.sfx=0;m.SET.music=0;m.title_open=false;root.add_child(m)
	await process_frame
	for m in [old,new]: m.set_process(false);m.visible=false;m.oy=13;m.visibility_flash=0;m.S={"phase":"fight"}
	var out=OS.get_cmdline_user_args()[0]
	var count=0
	for grade in range(1,5):
		for action in ["swim","thrash","jump"]:
			for face in [-1.0,1.0]:
				for m in [old,new]:
					m.ui_commands.clear();m._shadow_fish(Vector2(135.3,100.7),3,grade,1340,action,false,1.7,{},1.9,2,face,1.0)
				var a=expand(old.ui_commands);var b=expand(new.ui_commands)
				if a.size()!=b.size(): failures.append("triangle count")
				else:
					for i in a.size():
						if a[i][1]!=b[i][1] or a[i][2]!=b[i][2]: failures.append("color/UV")
						for j in 3:
							if not a[i][0][j].is_equal_approx(b[i][0][j]): failures.append("geometry")
				if action=="swim" and face==1.0:
					for pair in [[old,"before"],[new,"after"]]:
						var vp=SubViewport.new();vp.size=Vector2i(540,400);vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(vp)
						var surface=Surface.new();surface.scale=Vector2(2,2);surface.commands=pair[0].ui_commands.duplicate();vp.add_child(surface)
						await process_frame;await RenderingServer.frame_post_draw
						vp.get_texture().get_image().save_png(out+"/grade"+str(grade)+"-"+pair[1]+".png")
						vp.queue_free();await process_frame
				count+=1
	for m in [old,new]: m.queue_free()
	await process_frame
	print("RARE_HALO_VERIFY cases=",count," failures=",failures)
	quit(0 if failures.is_empty() else 1)
