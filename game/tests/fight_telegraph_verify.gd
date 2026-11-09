extends SceneTree
class Probe extends "res://main.gd":
 var pixels:Array=[]
 func _fish_effect_rect(r:Rect2,c:Color)->void:pixels.append([r,c])
 func _fish_effect_circle(_p:Vector2,_r:float,_c:Color)->void:pass
var failures:Array=[]
func check(ok:bool,label:String)->void:
 if not ok:failures.append(label);push_error(label)
func _initialize()->void:call_deferred("run")
func prepare(m,b:String)->void:
 m.active_region=0;m.start_wait();m.S.grade=0;m.S.star=0;m.S.sp=0;m.start_fight();m.S.tut=false;m.S.lesson="";m.S.chaos=0;m.S.beh=b;m.S.bt=1;m.S.dist=20;m.S.tension=20;m.S.spike=0;m.S.spikeWarn=0;m.S.holdT=0;m.clock=10;m.holding=false;m.fight_telegraph.note_behavior(m)
func run()->void:
 var m=Probe.new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.TUT.done=true;m.title_open=false;m.lesson_open=false;m.trans={};m.development_preview=true
 var f=m.fight_telegraph
 for pair in [["tell","right"],["nose","down"],["rise","up"],["turn","left"]]:
  prepare(m,pair[0])
  for p in [0.0,0.25,0.5,0.99]:
   m.S.bt=1-p;var data:Dictionary=f.sample(m)
   check(data.shape==pair[1] and is_equal_approx(data.progress,p),"warning shape and true remaining-time progress")
   check(data.color==(f.LIME if pair[0]=="turn" else f.CORAL),"approved high-contrast control color")
  m.S.bt=0;m.update_fight(.01)
  check(not f.sample(m).get("shape","") in ["right","left","up","down"],"warning vanishes at actual execution")
 prepare(m,"tell");m.S.fakeTell=true;m.S.bt=0;m.update_fight(.01)
 check(m.S.beh=="swim" and f.sample(m).shape=="cancel","fake warning breaks apart only on actual cancellation")
 prepare(m,"run");m.active_region=2;m.S.chain=true;m.S.bt=0;m.update_fight(.01)
 check(m.S.beh=="tell" and f.ring(m).is_empty(),"chain cannot show safe reeling ring")
 prepare(m,"rest");m.active_region=2;m.S.fakeRest=true;m.S.bt=0;m.update_fight(.01)
 check(m.S.beh=="tell" and f.ring(m).is_empty(),"fake rest retracts safe signal when next warning starts")
 prepare(m,"swim");m.S.spikeWarn=f.SPIKE_WARNING;m.S.bt=10
 check(f.sample(m).shape=="bolt" and is_zero_approx(f.sample(m).progress),"spike warning starts empty")
 m.update_fight(.175);check(is_equal_approx(f.sample(m).progress,.5) and m.S.spike==0,"spike damage not active during warning")
 m.update_fight(.175);check(m.S.spike==.25 and m.S.spikeWarn==0 and f.sample(m).is_empty(),"spike executes exactly after meter fills")
 prepare(m,"rise");m.S.spikeWarn=.2;m.update_fight(.01)
 check(m.S.spikeWarn==0 and f.sample(m).shape=="up","critical action warnings never hidden by queued spike")
 for b in ["swim","rest","run","dive","jump","charge","sulk","circle","thrash","skim","clone"]:
  prepare(m,b);m.S.bt=.5;m.S.cloneT=.1
  var data:Dictionary=f.sample(m)
  if b in ["swim","rest","run","dive","jump","charge"]:check(data.is_empty(),"no permanent icons on ordinary/executing actions")
  if b=="clone":
   check(data.shape=="clones" and data.color==f.VIOLET,"clone group mark is observation only")
   var before:Dictionary=data.duplicate()
   for i in 3:m.S.cloneReal=i;check(f.sample(m)==before,"clone mark cannot reveal real index")
   m.S.cloneT=.31;check(f.sample(m).is_empty(),"clone opening gauge disappears after split")
 prepare(m,"sulk");m.S.holdT=.2;check(f.sample(m).shape=="clamp" and f.can_reel(m),"short pump is safe")
 m.S.holdT=.5;check(not f.can_reel(m) and f.sample(m).color==f.CORAL,"long hold closes clamp and turns coral")
 prepare(m,"circle")
 for a in [0.5,2.0,3.5,5.0]:
  m.S.circA=a;check(f.can_reel(m)==(sin(a)>0),"circle signal follows actual pull multiplier phase")
 prepare(m,"thrash")
 for a in [0.0,.1,.3,.5,.8]:
  m.S.thT=a;check(f.can_reel(m)==(sin(a*(9+4*m.S.F))<=.4),"thrash follows actual strong/weak threshold")
 prepare(m,"run");m.S.beh="rest";f.note_behavior(m)
 var cash:int=m.gold;var distance:float=m.S.dist;var count:int=f.success_count
 check(not f.on_press(m,false),"already held input never gets timing success")
 check(f.on_press(m,true) and f.success_count==count+1,"fresh timely press succeeds once")
 check(not f.on_press(m,true) and m.gold==cash and m.S.dist==distance,"feedback cannot add rewards or repeat")
 prepare(m,"jump");m.S.bt=0;m.update_fight(.01)
 check(f.ring(m).kind=="landing","landing ring shares actual existing landing window")
 m.press(Vector2(100,400));check(m.S.jumpUsed and m.S.dist>20 and f.flash_until>m.clock,"real press preserves landing reward and adds feedback")
 var paid:float=m.S.dist;m.press(Vector2(100,400));check(m.S.dist==paid,"landing cannot pay twice")
 prepare(m,"rest");m.S.skimEnd=m.clock+.4;m.S.skimUsed=false
 check(f.ring(m).kind=="skim","skim ring uses existing bonus window")
 m.press(Vector2(100,400));m.update_fight(.001);check(m.S.skimUsed,"existing skim bonus path retained")
 prepare(m,"tell");m.S.bt=.5
 var untouched:Dictionary=m.S.duplicate(true);var texts:Array=m.text_items.duplicate(true)
 seed(999);var expected:float=randf();seed(999)
 for shape in ["right","left","up","down","bolt","ring","clones","clamp","cycle","zigzag","wave"]:
  check(not f.mask(shape).is_empty(),"every approved symbol has pixels")
  var renderings:Array=[]
  for progress in [0.0,.5,1.0]:
   m.pixels=[];f.paint(m,f.cue(shape,f.CORAL,progress,"right"),Vector2(20,30));renderings.append(m.pixels.duplicate(true))
   for px in m.pixels:check(Rect2(19,29,15,15).encloses(px[0]),"compact pixel icon stays within15px bounds")
  check(renderings[0]!=renderings[1] and renderings[1]!=renderings[2],"empty/half/full progress visibly differs for every icon")
 check(is_equal_approx(randf(),expected) and m.S==untouched and m.text_items==texts,"render has no RNG, simulation or text side effects")
 m.fish_mouth=Vector2(268,290);m.aura={"hw":5};m.pixels=[];f.draw(m,Vector2(260,290),60)
 check(f.icon_bounds.end.x<=270 and f.icon_bounds.position.x>=0,"icon clamps to phone edge")
 for pos in [Vector2(20,150),Vector2(135,350),Vector2(260,400)]:
  for length in [30,80,156]:
   m.fish_mouth=pos+Vector2(10,0);m.S.tensionHud=m._tension_anchor(pos,2.2,length);m.pixels=[];f.draw(m,pos,length)
   check(not f.icon_bounds.intersects(Rect2(m.S.tensionHud,Vector2(44,8))),"icons never cover tension meter at edges/large-fish heights")
 for progress in [0.0,.25,.6,.95]:
  var ps:Array=f.success_pixels(progress)
  check(not ps.is_empty(),"success burst visible across full .30s")
  for px in ps:check(Rect2(-13,-13,27,27).encloses(px[0]),"success burst remains compact")
 check(f.success_pixels(1.0).is_empty(),"success burst fully disappears")
 prepare(m,"run");m.S.beh="rest";f.note_behavior(m);f.on_press(m,true)
 check(is_equal_approx(f.flash_until-m.clock,.30),"success flash lasts .30 without extending timing window")
 m.S.phase="idle";check(f.sample(m).is_empty(),"cue hidden outside fights")
 print("FIGHT_TELEGRAPH_VERIFY failures=",failures)
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
