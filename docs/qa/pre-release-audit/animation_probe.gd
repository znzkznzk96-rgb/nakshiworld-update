extends SceneTree
class CanvasProbe:
	extends RefCounted
	var draws: Array=[]
	func _ui_texture_rect_region(_texture,rect,region,_color=Color.WHITE): draws.append({"rect":rect,"region":region})
	func _ui_arc(_a,_b,_c,_d,_e,_f,_g): pass
	func _ui_texture_rect(_a,_b): pass
func _initialize(): call_deferred("run")
func run():
	var v=load("res://addons/expedition/view.gd").new();v.setup()
	var p=CanvasProbe.new();var result={}
	for id in ["3R","5R","7R","10R"]:
		var seen={};var n=320 if id=="10R" else 224
		for phase in ["approach","fight","death","defeat"]:
			for step in 301:
				var t=step/200.0
				v.data.battle={"phase":phase,"clock":t,"phase_time":step/100.0,"ticks":1,"fighters":[],"enemy":{"id":id}}
				p.draws=[];v.battle_art(p,Rect2(0,0,246,48))
				var region=p.draws[-1].region
				seen["%d,%d"%[int(region.position.y/n),int(region.position.x/n)]]=true
		result[id]={"reachable_frames":seen.keys(),"used":seen.size(),"available":24}
	var f={"id":0,"hp":100,"shield":0}
	v.data.battle={"phase":"fight","clock":.5,"phase_time":0,"ticks":1,"fighters":[f],"enemy":{"id":"3R"}}
	p.draws=[];v.battle_art(p,Rect2(0,0,246,48));var alive=p.draws.size()
	f.hp=0;p.draws=[];v.battle_art(p,Rect2(0,0,246,48))
	result["soldier_death"]={"draws_alive":alive,"draws_dead":p.draws.size(),"immediate_removal":alive==p.draws.size()+1}
	print("ANIMATION_AUDIT ",JSON.stringify(result));quit()
