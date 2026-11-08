extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String):
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 var args=OS.get_cmdline_user_args();var out:String=args[0];var before:bool=args.size()>1 and args[1]=="before"
 DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_size=Vector2i(270,540);root.size=Vector2i(810,1620)
 var app=load("res://tests/valley_native_root.gd").new();root.add_child(app);app._start()
 var m=app.box.get_child(0).get_child(0);m.development_preview=true;m.SET.sfx=0;m.SET.music=0;m.set_process(false)
 m.title_open=false;m.lesson_open=false;m.trans={};m.TUT.done=true;m.tip_t=0;m.toast_t=0;m.judge_t=0;m.anim_t=0;m.clock=0;m.visibility_flash=0
 var e=m.environment;e.elapsed=3;e.valley.elapsed=3;e.tile.scenery.animated=false;e.tile.scenery.elapsed=3;e.tile.surface_water.animated=false;e.tile.surface_water.set_time(3)
 for height in ([540] if before else [480,540,660]):
  root.content_scale_size=Vector2i(270,height);root.size=Vector2i(810,height*3);await process_frame;app._fit();await process_frame
  for region in [1,2]:
   m.active_region=region;m._layout();m._switch_scene("fish")
   for hour in [12,0]:
    for phase in ["idle","fight"]:
     m.S={"phase":"idle"}
     if phase=="fight":
      seed(440+region);m.S={"sp":28 if region==1 else 49,"star":1,"grade":0,"lf":1.0};m.start_fight();m.S.beh="swim";m.S.dist=35;m.S.fx=156;m.S.fy=minf(m.uw_bot-45,m.WATER+75);m.S.dispY=m.S.fy;m._last_draw_t=-1;m.fclock=0
     e.set_hour(hour);m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
     root.get_texture().get_image().save_png(out.path_join("r%d_h%d_t%d_%s.png"%[region,height,hour,phase]))
     if not before and height==540 and hour==0 and phase=="idle":
      m.headlamp_light.enabled=false;m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
      root.get_texture().get_image().save_png(out.path_join("r%d_helmet_light_off.png"%region))
      m.headlamp_light.enabled=true;m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
      check(m.headlamp_light.visible and m.headlamp_light.sprites.size()==m.angler_scene.light_parts.size(),"original actor mask receives local light")
      check(m.headlamp_light.shader_material.get_shader_parameter("lamp_position").distance_to(m.angler_scene.headlamp_world+Vector2(0,m.oy))<.001,"foreground illumination shares helmet source")
     if not before and hour==0:
      check(m.night_play.flame(m).distance_to(m.angler_scene.headlamp_transform*Vector2(89,38)-Vector2(0,m.oy))<.001,"headlamp aligned to helmet same frame")
      check(m.night_play.flame(m).y<m.SURF-40,"no floor lamp hotspot")
      if phase=="fight":check(m.S.mouth.distance_to(m.fish_mouth)<.001,"night line mouth preserved")
 # Exercise the same-frame head transform through animated cast and reeling poses.
 if not before:
  root.content_scale_size=Vector2i(270,540);root.size=Vector2i(810,1620);await process_frame;app._fit();await process_frame
  for region in [1,2]:
   m.active_region=region;m._layout();e.set_hour(0)
   var poses:Array=[]
   for phase in ["cast","fight"]:
    for t in [0.0,0.35,0.7,1.0]:
     if phase=="cast":m.S={"phase":"cast","t":t}
     else:
      seed(440+region);m.S={"sp":28 if region==1 else 49,"star":1,"grade":0,"lf":1.0};m.start_fight();m.S.beh="swim";m.S.dist=35;m.S.fx=156;m.S.fy=minf(m.uw_bot-45,m.WATER+75);m.S.dispY=m.S.fy;m.S.tension=85;m.holding=true;m.fclock=t
     m.clock=t;m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
     var rig=m.angler_scene
     var ground=e.valley if region==1 else e.tile
     var uv:Vector2=ground.night_glow.shader_material.get_shader_parameter("lantern_uv")
     check((ground.map_rect.position+uv*ground.map_rect.size).distance_to(rig.headlamp_world)<.001,"shader follows moving helmet same frame")
     check(rig.headlamp_world.distance_to(rig.headlamp_transform*Vector2(89,38)-Vector2(0,m.oy))<.001,"cast/reel lamp matches original helmet pixel")
     poses.append(rig.headlamp_world)
     if t==0.7:root.get_texture().get_image().save_png(out.path_join("r%d_helmet_%s.png"%[region,phase]))
   check(poses[0].distance_to(poses[2])>.1,"headlamp follows casting motion")
 m.audio_feedback.dispose();app.queue_free();await process_frame
 print("NIGHT_PLAY_NATIVE_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
