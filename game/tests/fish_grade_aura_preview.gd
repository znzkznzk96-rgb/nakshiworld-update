extends SceneTree
var failures:Array=[]
func _initialize():call_deferred("run")
func run():
	var out:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size=Vector2i(270,540);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.size=Vector2i(540,1080)
	var ui=CanvasLayer.new();ui.layer=10;root.add_child(ui)
	var text=Node2D.new();text.set_script(load("res://text_layer.gd"));ui.add_child(text)
	var m=load("res://main.gd").new();m.text_layer=text;m.title_open=false;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame
	m.development_preview=true;m.set_process(false);m.title_open=false;m.lesson_open=false;m.tip_t=0;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.TUT.seen=m.BOOK_KEYS.duplicate();m.scene="fish";m.reveal_pending=false;m.reveal_t=0;m.judge_t=0
	m.bg_node.visible=true;m.environment.show_scene(true);m._layout();m.environment.set_hour(12);m.environment.update(0)
	var board=Image.create(720,24*240,false,Image.FORMAT_RGBA8);board.fill(Color("132535"))
	var row=0;var commands=0;var samples=0
	for height in [480,540,660]:
		root.content_scale_size=Vector2i(270,height);root.size=Vector2i(540,height*2);await process_frame;m._layout()
		for grade in [1,2,3,4]:
			for action in ["tell","nose"]:
				m.active_region=0;m.start_wait();m.S.sp=[0,7,19][(grade+height)%3];m.S.star=1;m.S.grade=grade;m.S.lf=1.0;m.S.len=m.FISH_LEN[m.S.sp];m.start_fight()
				m.S.tut=false;m.S.lesson="";m.S.beh=action;m.S.bt=.4;m.S.dist=35;m.S.tension=35;m.S.fx=166;m.S.fy=m.WATER+95;m.S.dispY=m.S.fy;m.S.pose={};m.S.spike=0;m.S.spikeWarn=0;m.clock=15;m.fclock=15;m.holding=false;m.toast_t=0;m.visibility_flash=0;m.reveal_t=0;m.reveal_pending=false
				m.fight_telegraph.note_behavior(m);m.fight_telegraph.duration=.8
				var saved=m.S.duplicate(true)
				for column in 2:
					m.S=saved.duplicate(true);m.fish_grade_aura.masking_enabled=column==1;m._last_draw_t=-1;m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
					var image:Image=root.get_texture().get_image();var at:Vector2=m.S.lastF.p
					var x=clampi(roundi((at.x-90+m.ox)*2),0,image.get_width()-360)
					var y=clampi(roundi((at.y-90+m.oy)*2),0,image.get_height()-240)
					board.blit_rect(image,Rect2i(x,y,360,240),Vector2i(column*360,row*240))
					if column==1:
						var context:Dictionary=m.aura_cue_context
						var layout=m.fight_telegraph.layout(m,context.center,m.aura.L,context.group,context.hud)
						if layout.bounds!=m.fight_telegraph.icon_bounds:failures.append("same-frame cue bounds "+action)
						commands=maxi(commands,m.ui_commands.size());samples=maxi(samples,m.fish_grade_aura.last_samples.size())
					if grade==4 and height==540:image.save_png(out.path_join(action+("-after" if column==1 else "-before")+"-phone.png"))
				row+=1
	board.save_png(out.path_join("aura-cue-before-after.png"))
	FileAccess.open(out.path_join("NATIVE.json"),FileAccess.WRITE).store_string(JSON.stringify({"cases":row,"renders":row*2,"heights":[480,540,660],"max_ui_commands":commands,"max_live_emitters":samples,"failures":failures},"\t"))
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("FISH_GRADE_AURA_PREVIEW failures=",failures," cases=",row)
	quit(0 if failures.is_empty() else 1)
