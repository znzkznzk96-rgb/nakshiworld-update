extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String)->void:
 if not ok:failures.append(label);push_error(label)
func _initialize()->void:call_deferred("run")
func frame_at(m,key:String,beh:String,k:float)->Dictionary:
 var elapsed:float=0
 for step in m.LESSON[key].anim:
  if step[0]==beh:return m.lesson_frame(key,elapsed+m.lesson_step_duration(key,step)*k)
  elapsed+=m.lesson_step_duration(key,step)
 return {}
func run()->void:
 var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;m.title_open=false;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false;m.TUT.done=true;m.development_preview=true;m.trans={};m.lesson_open=false
 # Reproduce the reported exact turn->charge transition while holding/releasing.
 for held in [false,true]:
  m.start_wait();m.S.sp=6;m.S.star=0;m.S.grade=0;m.start_fight();m.S.tut=false;m.S.lesson="";m.S.chaos=0;m.S.beh="turn";m.S.bt=.55;m.S.dist=20;m.S.tension=20;m.holding=held
  var f=m.fight_telegraph;f.note_behavior(m)
  check(f.sample(m).shape=="left","reverse-dash preparation retains lime arrow")
  m.S.bt=0;m.update_fight(.001)
  check(m.S.beh=="charge" and f.sample(m).is_empty() and f.ring(m).is_empty(),"reverse dash has no misleading .25s circle")
  check(not f.on_press(m,true),"continuously reeling move cannot award resume feedback")
  for i in 20:m.clock+=.01;m.update_fight(.01);check(f.sample(m).is_empty(),"reported .2s interval stays free of circle")
 m.start_wait();m.start_fight();m.S.beh="run";m.fight_telegraph.note_behavior(m);m.S.beh="rest";m.fight_telegraph.note_behavior(m)
 check(not m.fight_telegraph.ring(m).is_empty(),"real release-to-reel opportunities remain")
 var mappings:Dictionary={"tell":"right","nose":"down","rise":"up","turn":"left"}
 for key in m.BOOK_KEYS:
  for step in m.LESSON[key].anim:
   for k in [.05,.5,.95]:
    var frame:Dictionary=frame_at(m,key,step[0],k);var d:Dictionary=m.lesson_telegraph.lesson_descriptor(key,frame)
    if mappings.has(frame.beh):check(d.cue.shape==mappings[frame.beh] and is_equal_approx(d.cue.progress,k),"book uses actual warning mask and progress")
    if key=="charge" and frame.beh=="charge":check(d.cue.is_empty() and not d.success,"book also has no reverse-dash ring")
    if frame.beh=="spike_warn":check(d.cue.shape=="bolt" and d.cue.color==m.lesson_telegraph.CORAL,"book teaches new spike warning")
 check(not "예고 없이" in m.LESSON.spike.text,"stale surprise-only spike description corrected")
 for key in ["rest","tell","dive","spike","jump","skim"]:
  var beh:String="land" if key=="jump" else "rest"
  var early:Dictionary=m.lesson_telegraph.lesson_descriptor(key,frame_at(m,key,beh,.1))
  var hit:Dictionary=m.lesson_telegraph.lesson_descriptor(key,frame_at(m,key,beh,.66))
  check(early.cue.shape=="ring" and hit.flash>0 and hit.cue.is_empty(),"book demonstrates ring->fresh timing success "+key)
 # Render every book card through real drawing code, without touching the fight model.
 m.S={"phase":"idle","sp":6,"sentinel":"preserve"};m.fish_mouth=Vector2(99,111);m.holding=true
 var before:Dictionary=m.S.duplicate(true);var gold:int=m.gold;var mouth:Vector2=m.fish_mouth;var real_behavior:String=m.fight_telegraph.behavior;var real_window:float=m.fight_telegraph.reel_until
 seed(745);var expected:float=randf();seed(745)
 for key in m.BOOK_KEYS:
  m.lesson_key=key;m.lesson_after="book";m.lesson_clock=0;m.ui_clock=1.5;m.ui_commands=[];m.text_items=[];m._draw_lesson_card(0)
  check(not m.lesson_telegraph.demo_last.is_empty(),"all twelve book cards call shared telegraph renderer")
  check(m.S==before and m.gold==gold and m.holding and m.fish_mouth==mouth,"book never changes live fight/hold/mouth/rewards")
 check(m.fight_telegraph.behavior==real_behavior and m.fight_telegraph.reel_until==real_window,"book cannot consume real timing windows")
 check(is_equal_approx(randf(),expected),"book preserves catch RNG")
 print("BODY_BOOK_TELEGRAPH_VERIFY failures=",failures)
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
