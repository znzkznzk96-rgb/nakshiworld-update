extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok and label not in failures: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m=load("res://main.gd").new();m.SET.music=0;m.SET.sfx=0;root.add_child(m);await process_frame;m.set_process(false)
	var cases:=0;var max_extent:=0.0
	for sp in 80:
		for size in 4:
			var fixed_length: float=-1
			for frame in 16:
				for face in [-1.0,1.0]:
					m.S={"phase":"hook","sp":sp,"star":sp%5,"size":size,"biteAt":8.0,"fakes":[]}
					var t: float=(frame+0.25)*60.0
					var target:=Vector2(170,290+size)
					m.ui_commands=[]
					m.bite_preview.draw(m,Vector2(140,320),t,face,0.8,{"amp":0.08,"curl":0.0,"tilt":-1.1,"stretch":1.0,"tailAmp":1.4,"freq":3.0},t/1000.0*TAU*3,target,1.0)
					check(m.bite_preview.last_mouth.distance_to(target)<0.001,"actual mouth touches bobber for every species/frame/side")
					check(m.bite_preview.last_mouth.is_finite(),"finite mouth anchor")
					check(m.bite_preview.mapping_valid,"alpha head anchor maps inside actual body triangles")
					check(m.bite_preview.anchor_opaque.values().all(func(value):return value),"head anchor is on an opaque source pixel")
					var extent:float=maxf(m.bite_preview.last_bounds.size.x,m.bite_preview.last_bounds.size.y)
					max_extent=maxf(max_extent,extent)
					check(extent<=m._bite_preview_length(size)+0.01,"pre-fight silhouette maximum bounded")
					if fixed_length<0:fixed_length=m.bite_preview.last_length
					check(is_equal_approx(fixed_length,m.bite_preview.last_length),"no per-frame auto-fit or scale pumping")
					check(not m.bite_preview.collecting and not m.ui_commands.is_empty(),"body emitted after preview capture")
					cases+=1
			m.clock=8.5;m.ui_commands=[];m._draw_bite_shadow(8500,172,8)
			check(m.bite_preview.last_mouth.distance_to(Vector2(172,m.WATER+9))<0.001,"actual hook path uses moving bobber and dip")
			m.S.phase="wait";m.S.biteAt=10.0;m.S.fakes=[9.0]
			m.clock=9.0-0.12+(0.34+0.12*size)*0.5;m.ui_commands=[]
			m._draw_bite_shadow(m.clock*1000.0,169,3)
			check(m.bite_preview.last_mouth.distance_to(Vector2(169,m.WATER+4))<0.001,"fake nibble peak also contacts bobber")
		m.S={"phase":"fight"}
		check(m._fish_display_length(4,2.2,false,sp)>0,"fight sizing remains species-dependent")
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("BITE_CONTACT_VERIFY failures=",failures," cases=",cases," maximum_extent=",max_extent)
	quit(0 if failures.is_empty() else 1)
