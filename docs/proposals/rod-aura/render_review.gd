extends SceneTree
var actors: Array=[]
var canvas: Node2D
var caption: Label
var failures: Array=[]
func label(text: String,pos: Vector2,size: int,color: Color) -> Label:
	var n:=Label.new();n.text=text;n.position=pos;n.add_theme_font_override("font",load("res://font/neodgm.ttf"));n.add_theme_font_size_override("font_size",size);n.add_theme_color_override("font_color",color);canvas.add_child(n);return n
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var args:=OS.get_cmdline_user_args();var out: String=args[0]
	DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(1080,800);root.content_scale_size=Vector2i(1080,800);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	RenderingServer.set_default_clear_color(Color("111b29"))
	canvas=Node2D.new();root.add_child(canvas)
	label("강화 오라 V2 · 실제 최대 +20",Vector2(22,10),26,Color("fff0d1"))
	caption=label("낮 · 대기",Vector2(780,16),20,Color("dce6f3"))
	var levels: Array=[0,2,4,6,8,10]
	var names: Array=["기본","선명한 은백빛","푸른 흐름","보라 오로라","황금 오로라","진홍 오로라"]
	var tier_labels: Array=[]
	var aura=load("res://review_aura/rod_aura.gd").new()
	for i in 6:
		var x: int=(i%3)*360;var y: int=55+(i/3)*360
		tier_labels.append(label("+%d   %s"%[levels[i],names[i]],Vector2(x+14,y),21,aura.COLORS[i] if i>0 else Color("e2e7ef")))
		var view:=SubViewport.new();view.size=Vector2i(180,150);view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;view.disable_3d=true;root.add_child(view)
		var actor=load("res://review_aura/actor_review.gd").new();actor.position=Vector2(0,-60);actor.preview_enhancement=levels[i];view.add_child(actor);actors.append(actor)
		var display:=Sprite2D.new();display.texture=view.get_texture();display.centered=false;display.position=Vector2(x,y+30);display.scale=Vector2(2,2);display.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;canvas.add_child(display)
	label("검토용 시안 · 동일 은하낚싯대/동작 · 성능 및 공개게임 변경 없음",Vector2(20,777),16,Color("a5b7cb"))
	await process_frame
	var frames: int=672 if args.size()<2 else 1
	for frame in frames:
		var time: float=frame/24.0
		if frame==336:
			levels=[0,12,14,16,18,20]
			names=["기본","청록 오로라","녹빛 오로라","불꽃 오로라","자홍 오로라","무지갯빛 극광"]
			for i in 6:
				actors[i].preview_enhancement=levels[i]
				tier_labels[i].text="+%d   %s"%[levels[i],names[i]]
				tier_labels[i].add_theme_color_override("font_color",aura.COLORS[int(levels[i]/2)])
		var cycle: float=fposmod(time,14)
		var night: bool=cycle>=7
		var section: float=fposmod(cycle,7)
		var action: String="idle" if section<2 else ("cast" if section<3.6 else "fight")
		var local: float=section if action=="idle" else (minf(1.45,(section-2)/1.6*1.45) if action=="cast" else section-3.6)
		caption.text=("밤" if night else "낮")+" · "+("대기" if action=="idle" else ("캐스팅" if action=="cast" else "감기 / 버티기"))
		for actor in actors:actor.pose(time,action,local,night)
		await process_frame;await process_frame;await RenderingServer.frame_post_draw
		for i in 6:
			var d: Dictionary=actors[i].rig.debug
			if i>0 and d.tip.distance_to(actors[0].rig.debug.tip)>.0001:failures.append("changed rod tip "+str(i))
			if float(d.get("front_error",1))>.001 or float(d.get("rear_error",1))>.001:failures.append("arm reach "+str(i))
		root.get_texture().get_image().save_png(out.path_join("%04d.png"%frame))
		if frame in [24,65,120,192,232,288,360,401,456,528,568,624]:root.get_texture().get_image().save_png(out.path_join("compare-%d.png"%frame))
	print("ROD_AURA_REVIEW failures=",failures," frames=",frames)
	quit(0 if failures.is_empty() else 1)
