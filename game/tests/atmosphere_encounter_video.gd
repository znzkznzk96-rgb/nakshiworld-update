extends SceneTree
var failures: Array=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var out: String=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size=Vector2i(270,660);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.size=Vector2i(540,1320)
	var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
	var text:=Node2D.new();text.set_script(load("res://text_layer.gd"));ui.add_child(text)
	var m=load("res://main.gd").new();m.text_layer=text;m.SET.sfx=0;m.SET.music=0;m.title_open=false;root.add_child(m);await process_frame
	m.development_preview=true;m.set_process(false);m.title_open=false;m.lesson_open=false;m.tip_t=0;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.TUT.seen=m.BOOK_KEYS.duplicate()
	var previous: int=-1
	for frame in 192:
		var seconds: float=frame/12.0
		var segment: int=0
		var local: float=seconds
		if seconds>=13.2:segment=6;local=seconds-13.2
		elif seconds>=10.2:segment=5;local=seconds-10.2
		elif seconds>=3.0:segment=1+int((seconds-3.0)/1.8);local=fposmod(seconds-3.0,1.8)
		if segment!=previous:
			m.environment.set_hour(22.0 if segment==0 else 10.0)
			m.equipment.active_parts=["float","hook","line","reel"] if segment==5 else []
			m.rod_lv=2;m.equipment.rod_equipped=true;m.start_wait();m.S.judge="GREAT";m.S.sp=1;m.S.star=0;m.S.grade=segment if segment<5 else 0;m.S.lf=1.0;m.S.len=25.0
			if segment in [1,2,3,4,6]:m.start_fight()
			if segment==6:m.start_catch()
			if segment==5:m.S.owner=true;m.S.sp=19;m.S.star=4
			previous=segment
		m.S.phase="wait" if segment==0 else ("pre" if segment==5 else ("catch" if segment==6 else "fight"))
		m.S.t=local;m.clock=15+seconds;m.S.encounter_at=m.clock-local;m.fclock=local;m.cat_t=seconds;m.holding=false;m.S.tension=35;m.tip_t=0;m.judge_t=0;m.lesson_open=false
		if segment==6 and local>=2.4:m.S.phase="wait"
		m.environment.elapsed=seconds;m.environment.update(0)
		m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("%04d.png"%frame))

	m.audio_feedback.dispose();print("ATMOSPHERE_ENCOUNTER_VIDEO failures=",failures);quit(0 if failures.is_empty() else 1)
