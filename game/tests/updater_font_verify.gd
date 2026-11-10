extends SceneTree
var failures:Array=[]
class GlyphStamp extends Node2D:
 var face:Font
 var factor:float=2
 func _draw():
  draw_set_transform(Vector2.ZERO,0,Vector2.ONE*factor)
  draw_string(face,Vector2(8,24),"최신 버전입니다 · 곧 시작합니다",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("111c52"))
  draw_string(face,Vector2(8,48),"잠시 후 낚시월드로 이동해요",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("223b66"))
  draw_string(face,Vector2(8,72),"잠시만 기다려 주세요",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("426581"))
func check(ok:bool,label:String):
 if not ok:failures.append(label)
func signature(f):return [f.antialiasing,f.hinting,f.subpixel_positioning,f.oversampling,f.fallbacks.size()]
func metrics(f):
 var result:Array=[]
 for size in [8,9,11,16]:result.append(f.get_string_size("최신 버전입니다 · 곧 시작합니다",HORIZONTAL_ALIGNMENT_LEFT,-1,size))
 return result
func hash_image(image:Image)->String:
 var ctx:=HashingContext.new();ctx.start(HashingContext.HASH_SHA256);ctx.update(image.get_data());return ctx.finish().hex_encode()
func _initialize():call_deferred("run")
func run():
 var native:bool=DisplayServer.get_name()!="headless"
 var args:=OS.get_cmdline_user_args();var out:String=args[0] if not args.is_empty() else "user://font-evidence"
 if native:
  DirAccess.make_dir_recursive_absolute(out)
  root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_size=Vector2i(270,660);root.size=Vector2i(540,1320)
 var boot=load("res://root.gd").new();boot.preview_only=true;root.add_child(boot);await process_frame;boot.set_process(false)
 # Simulate older installed APKs which still keep the original cached FontFile.
 var legacy:FontFile=load("res://font/neodgm.ttf")
 var fonts:Array=[boot.font,legacy];var before:Array=[];var widths:Array=[];var views:Array=[];var stamps:Array=[];var hashes:Array=[]
 for f in fonts:before.append(signature(f));widths.append(metrics(f))
 check(boot.font!=legacy,"new loader owns an independent font")
 if native:
  for index in 2:
   for factor in [2.0,628.0/270.0]:
    var view:=SubViewport.new();view.size=Vector2i(roundi(270*factor),roundi(90*factor));view.transparent_bg=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(view)
    var stamp:=GlyphStamp.new();stamp.face=fonts[index];stamp.factor=factor;view.add_child(stamp);views.append(view);stamps.append(stamp)
  await process_frame;await process_frame;await RenderingServer.frame_post_draw
  for i in views.size():
   var image:Image=views[i].get_texture().get_image();hashes.append(hash_image(image));image.save_png(out.path_join("before_%d.png"%i))
 var main
 if native:
  boot.update_phase="ready";boot.status="최신 버전입니다 · 곧 시작합니다";boot._start()
  var started:int=Time.get_ticks_msec()
  while boot.status!="" and Time.get_ticks_msec()-started<30000:await process_frame
  check(boot.status=="","actual game preparation and transition completed")
  for node in root.find_children("*","Node2D",true,false):
   if node.get_script()!=null and node.get_script().resource_path=="res://main.gd":main=node
 else:
  main=load("res://main.gd").new();main.development_preview=true;main.SET.sfx=0;main.SET.music=0;root.add_child(main);await process_frame
 main.set_process(false)
 for i in 2:
  check(fonts[i]!=main.fonts[0],"game font separated from loader %d"%i)
  check(signature(fonts[i])==before[i],"loader configuration unchanged %d"%i)
  check(metrics(fonts[i])==widths[i],"loader glyph widths unchanged %d"%i)
 check(main.fonts[0].antialiasing==TextServer.FONT_ANTIALIASING_NONE and main.fonts[0].hinting==TextServer.HINTING_NONE and main.fonts[0].oversampling==1.0,"game retains existing pixel-font settings")
 if native:
  for stamp in stamps:stamp.queue_redraw()
  await process_frame;await process_frame;await RenderingServer.frame_post_draw
  for i in views.size():
   var image:Image=views[i].get_texture().get_image();image.save_png(out.path_join("after_%d.png"%i));check(hash_image(image)==hashes[i],"identical rendered pixels before/after game initialization %d"%i)
 print("UPDATER_FONT_VERIFY failures=",failures," native=",native," raster_cases=",hashes.size())
 main.audio_feedback.dispose()
 for player in root.find_children("*","AudioStreamPlayer",true,false):player.stop();player.stream=null
 await create_timer(.1).timeout
 main.queue_free();boot.queue_free()
 for view in views:view.queue_free()
 views.clear();stamps.clear();fonts.clear();legacy=null
 await process_frame;await process_frame
 call_deferred("quit",0 if failures.is_empty() else 1)
