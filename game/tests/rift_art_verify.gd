extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String)->void:
	if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
	var m=load("res://main.gd").new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
	var art=m.rift_art;art.setup()
	check(art.catalog.size()==20,"approved twenty species")
	check(m.FISH_NAME.size()==80 and m.FISH_LEN.size()==80,"rift approved entry now has 80 catalog entries")
	check(m.progression.available_regions==[0,1,2,3],"rift available; deep sea and space remain gated")
	var old=m.S.duplicate(true);var frames:=0
	for sp in range(60,80):
		var e=art.entry(sp);var tex=art.texture(sp)
		check(tex.get_width()==int(e.canvas[0])*4 and tex.get_height()==int(e.canvas[1])*4,"atlas size %d"%sp)
		check(art.frame_index(sp,.96)==0,"approved 960ms loop %d"%sp)
		var first:Vector2=art.source_rect(sp,0).size
		for frame in 16:
			check(art.source_rect(sp,(frame+.25)*.06).size==first,"fixed crop %d %d"%[sp,frame])
			check(art.frame_index(sp,(frame+.25)*.06)==frame,"loop ordering %d %d"%[sp,frame])
			for face in [-1.0,1.0]:
				m.ui_commands=[];seed(183);var expected:=randf();seed(183)
				m._shadow_fish(Vector2(135,340),0,0,(frame+.25)*60,"swim",false,1,{},0,sp,face,1,80)
				check(randf()==expected and m.S==old,"art never mutates RNG/state")
				check(not m.ui_commands.is_empty(),"real renderer queues fish")
			frames+=1
		check(m._ui_fish(sp,Rect2(0,0,80,60)).size.x<=80.01,"static UI path")
	for h in [480,540,660]:
		root.size=Vector2i(270,h);await process_frame
		m.active_region=3;m._layout();m.environment.show_scene(true)
		var r=m.environment.rift
		check(r.root.visible and not m.environment.tile.root.visible and not m.environment.front.visible,"exclusive rift plate")
		check(absf(r.map_rect.position.y+r.map_rect.size.y*1314/2640-m.WATER)<=.5,"water mapping %d"%h)
		m.active_region=0;m._layout();m.environment.show_scene(true);check(not r.root.visible,"rift hides outside region")
	m.active_region=0;m.audio_feedback.dispose();m.queue_free();await process_frame
	print("RIFT_ART_VERIFY failures=",failures," frames=",frames);quit(0 if failures.is_empty() else 1)
