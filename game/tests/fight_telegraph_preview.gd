extends SceneTree
var failures:Array=[]
func _initialize()->void:call_deferred("run")
func run()->void:
 var out:String=OS.get_cmdline_user_args()[0];DirAccess.make_dir_recursive_absolute(out)
 root.content_scale_size=Vector2i(270,540);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.size=Vector2i(540,1080)
 var ui:=CanvasLayer.new();ui.layer=10;root.add_child(ui)
 var text:=Node2D.new();text.set_script(load("res://text_layer.gd"));ui.add_child(text)
 var m=load("res://main.gd").new();m.text_layer=text;m.title_open=false;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame
 m.development_preview=true;m.set_process(false);m.title_open=false;m.lesson_open=false;m.tip_t=0;m.guide.opened=false;m.mailbox.opened=false;m.trans={};m.TUT.done=true;m.TUT.seen=m.BOOK_KEYS.duplicate();m.scene="fish";m.reveal_pending=false;m.reveal_t=0;m.judge_t=0
 m.bg_node.visible=true;m.environment.show_scene(true);m._layout();m.environment.set_hour(12);m.environment.update(0)
 var board:=Image.create(1080,2640,false,Image.FORMAT_RGBA8);board.fill(Color("132535"))
 var actions:Array=["swim","tell","rest","rise","spike","turn","nose","clone","sulk","circle","thrash","skim"]
 var row:int=0
 for action in actions:
  for col in 3:
   var progress:float=[0.0,0.5,0.99][col]
   m.active_region=0;m.rod_lv=1;m.start_wait();m.S.sp=6;m.S.star=1;m.S.grade=0;m.S.lf=1.0;m.S.len=m.FISH_LEN[6];m.start_fight()
   m.S.tut=false;m.S.lesson="";m.S.beh=action if action!="spike" else "swim";m.S.bt=.8;m.S.dist=35;m.S.tension=35;m.S.fx=170;m.S.fy=m.WATER+90;m.S.dispY=m.S.fy;m.S.pose={};m.S.spike=0;m.S.spikeWarn=0;m.clock=15;m.fclock=15;m.holding=false;m.lesson_open=false;m.toast_t=0;m.visibility_flash=0;m.reveal_t=0;m.reveal_pending=false
   var f=m.fight_telegraph;f.note_behavior(m);f.duration=.8;m.S.bt=.8*(1-progress)
   if action=="rest":f.reel_until=m.clock+.25*(1-progress);f.reel_used=false
   if action=="spike":m.S.spikeWarn=f.SPIKE_WARNING*(1-progress)
   if action=="clone":m.S.cloneT=.3*progress;m.S.cloneSub="run";m.S.cloneReal=1
   if action=="sulk":m.S.holdT=progress*.6
   if action=="circle":m.S.circA=.1+progress*PI*1.6
   if action=="thrash":m.S.thT=[4.5,5.5,7.0][col]/(9+4*m.S.F)
   if action=="skim":m.S.skimDir=1
   if col==2:
    if action in ["tell","rise","turn","nose"]:
     m.S.bt=0;m.update_fight(.001);m.S.tension=35;m.S.dist=35
    if action=="spike":m.S.spikeWarn=0;m.S.spike=.25
    if action=="clone":m.S.cloneT=.31
    if action=="rest":f.flash_until=m.clock+.16;f.reel_used=true;f.reel_until=-1
    if action=="skim":m.S.beh="rest";m.S.skimEnd=m.clock+.4;m.S.skimUsed=false;f.note_behavior(m)
   m._last_draw_t=-1;m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
   var image:Image=root.get_texture().get_image()
   var at:Vector2=m.S.lastF.p
   var x:int=clampi(roundi((at.x-90+m.ox)*2),0,image.get_width()-360)
   var y:int=clampi(roundi((at.y-65+m.oy)*2),0,image.get_height()-220)
   board.blit_rect(image,Rect2i(x,y,360,220),Vector2i(col*360,row*220))
   if not f.icon_bounds.size.is_zero_approx():
    if f.icon_bounds.size.x>15 or f.icon_bounds.size.y>15:failures.append("icon too large "+action)
    var hud:Vector2=m.S.get("tensionHud",Vector2(-100,-100))
    if f.icon_bounds.intersects(Rect2(hud,Vector2(44,8))):failures.append("icon overlaps tension bar "+action)
   if col==1 and action in ["tell","circle","sulk","clone"]:image.save_png(out.path_join(action+"-phone.png"))
  row+=1
 board.save_png(out.path_join("telegraph-board.png"))
 # A full-size small-fish wait frame verifies the previously approved bobber change.
 m.start_wait();m.S.sp=0;m.S.size=0;m.S.biteAt=15;m.S.realUntil=16;m.S.fakes=[];m.clock=15.05;m.S.phase="wait";m.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out.path_join("bobber-small-phone.png"))
 print("FIGHT_TELEGRAPH_PREVIEW failures=",failures)
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
