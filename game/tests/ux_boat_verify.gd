extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String):
 if not ok:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 m.title_open=false;m.lesson_open=false;m.TUT.done=true;m.S={"phase":"idle"};m.gold=10000000
 var fg=m.FACILITIES;m.boat_lv=0;m.progression.available_regions=[0,1,2,3]
 for area in 4:
  m.region_shop.unlocked=range(area+1)
  var count=0
  while fg.unlocked(m,"boat"):
   var before:int=m.gold;var cost:int=fg.cost(m,"boat")
   check(fg.purchase(m,"boat"),"valid purchase")
   check(before-m.gold==cost,"exact price deducted")
   count+=1
  check(count==[2,2,1,1][area],"regional boat count %d"%area)
  check(m.boat_lv==[2,4,5,6][area],"regional cumulative level")
 check(m.V.passengers(m)==14 and m.V.interval(m)==40,"rift final keeps existing 14/40 benefit")
 # Existing tile-region level6 saves retain their purchase and income; no second charge.
 m.region_shop.unlocked=[0,1,2];m.boat_lv=6
 var old_rate:float=m.V.multiplier(m);check(m._save_game(),"legacy save written")
 m.boat_lv=0;m._load_game()
 check(m.boat_lv==6 and is_equal_approx(old_rate,m.V.multiplier(m)),"legacy level6 roundtrip preserves benefit")
 check(not fg.unlocked(m,"boat"),"legacy purchase cannot be bought again")
 # Rift missing, insufficient cash, and stale confirmation must all reject.
 m.boat_lv=5;m.gold=2000000;m.region_shop.unlocked=[0,1,2]
 check(not fg.purchase(m,"boat") and m.gold==2000000,"tile cannot buy rift tier")
 m.region_shop.unlocked=[0,1,2,3];m.gold=999999
 check(not fg.purchase(m,"boat") and m.boat_lv==5,"rift requires full price")
 m.gold=2000000;m.V.commerce.request(m.V,m,"boat");m.region_shop.unlocked=[0,1,2]
 check(not m.V.commerce.confirm(m.V,m) and m.gold==2000000 and m.boat_lv==5,"stale quote rechecks unlock")
 m.boat_lv=8;check(fg.max_level("boat")==8 and not fg.unlocked(m,"boat") and fg.lock_label(m,"boat")=="최대 단계","eight-tier cap")
 m.pond_cap_lv=6;check(fg.lock_label(m,"pondcap")=="강화 준비 중","unfinished content distinct from unlock")
 m.guide.tab=2;m.guide.topic=0
 for stock in [0.0,0.5,0.75,0.999]:
  m.pond_stock=stock;check(m.guide.content(m)[0].begins_with("현재 재고: 0 /"),"guide counts usable stock")
 check(m.guide.section_specs()[2][0]=="어장 고갈과 회복","no stale exception heading")
 m.guide.tab=3;m.guide.topic=0
 check(m.guide.section_specs()[1][2]==m.guide.content(m).size(),"boat guide covers every line")
 m.audio_feedback.dispose();m.queue_free();await process_frame;call_deferred("finish")
func finish():
 await process_frame
 print("UX_BOAT_VERIFY failures=",failures)
 quit(0 if failures.is_empty() else 1)
