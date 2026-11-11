extends SceneTree
var failures:Array=[]
func _initialize():call_deferred("run")
func capture(path:String)->void:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run():
	var out:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
	var text:=Node2D.new();text.set_script(load("res://text_layer.gd"));ui.add_child(text)
	var m=load("res://main.gd").new();m.text_layer=text;m.SET.music=0;m.SET.sfx=0;m.development_preview=true;root.add_child(m);await process_frame;m.set_process(false);m.development_preview=true
	m.title_open=false;m.title_screen.leaving=false;m.title_screen.root.hide();m.lesson_open=false;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.tip_t=0
	var renders:=0
	for h in [480,540,660]:
		root.content_scale_size=Vector2i(270,h);root.size=Vector2i(540,h*2);await process_frame
		m.active_region=3;m._layout();m._switch_scene("fish");m.S={"phase":"idle"}
		for phase in [0.0,1.05,3.15]:
			m.clock=phase;m.environment.update(0);m.queue_redraw();await capture(out.path_join("boat-%d-%02d.png"%[h,roundi(phase*100)]));renders+=1
			var e=m.environment.rift;var actual:float=(e.boat.position.y-(e.DECK_Y-306))*e.map_rect.size.x/e.SOURCE.x
			if absf(actual-m.rift_actor_bob)>.001:failures.append("shared boat/actor bob")
			for part in m.angler_scene.light_parts:
				if part.texture!=m.angler_scene.textures.lower:continue
				var image:Image=part.texture.get_image();var used:Rect2i=image.get_used_rect();var y:int=used.end.y-1
				for x in range(used.position.x,used.end.x):
					if image.get_pixel(x,y).a<.5:continue
					var foot:Vector2=part.transform*Vector2(x+.5,y+.5)-Vector2(0,m.oy)
					var deck_right:float=e.map_rect.position.x+360*e.map_rect.size.x/e.SOURCE.x
					if foot.x>deck_right-1 or absf(foot.y-(m.SURF+m.rift_actor_bob))>3:failures.append("actual sole remains on deck")
		m._switch_scene("village");m.V.open_shop(m,"museum");m.V.bundle_preview.region=3
		for tab in 3:
			m.V.bundle_preview.tab=tab;m.queue_redraw();await capture(out.path_join("bundle-%d-%d.png"%[h,tab]));renders+=1
		m.V.shop=""
	root.content_scale_size=Vector2i(270,540);root.size=Vector2i(540,1080);await process_frame
	m.active_region=3;m._layout();m._switch_scene("fish");m.S={"phase":"idle"}
	for i in 8:
		m.clock=i*4.2/8;m.environment.update(0);m.queue_redraw();await capture(out.path_join("motion-%02d.png"%i));renders+=1
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("RIFT_LAYERS_PREVIEW failures=",failures," renders=",renders);quit(0 if failures.is_empty() else 1)
