extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
 if not ok:failures.append(label);push_error(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var m=load("res://main.gd").new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false
 for name in ["heart","leaf","star","check","right","close","fish","plus","rod","soldier","soul0","soul1","soul2","soul3","soul4","region0","region1","region2","region3","region4","region5"]:
  check(ResourceLoader.exists("res://art/ui/codex/%s.png"%name),"required PixelLab icon "+name)
 var d=m.personal_dex;d.open(m);d.draw(m,480)
 check(d.rects.categories.size()==2 and d.rects.regions.size()==6,"two top categories and all six fishing locations")
 var snapshot: Dictionary=d.serialize()
 for i in 6:
  d.press(m,d.rects.regions[i].get_center());d.draw(m,480)
  check(d.region==i,"region navigation %d"%i)
  check(d.rows_total==(20 if i<2 else 0),"only actual regional species %d"%i)
  if i>=2:check(m.text_items.any(func(t):return t[2]=="물고기 도감 준비 중"),"unimplemented location honest empty state")
 check(snapshot==d.serialize(),"category browsing leaves records untouched")
 d.press(m,d.rects.categories[1].get_center());m.expedition.data.restore({})
 for id in 15:m.expedition.data.discover(id)
 for h in [480,660]:
  d.draw(m,h);check(d.rows_total==15,"full soldier collection")
  var before: float=d.scroll;d.begin(d.list_view.get_center());d.move(d.list_view.get_center()-Vector2(0,80));d.finish(m,d.list_view.get_center()-Vector2(0,80))
  check(d.selected==-1 and d.scroll>before,"drag scroll must not open detail")
  for id in 15:
   d.selected=id;d.draw(m,h)
   check(m.text_items.any(func(t):return t[2]=="기본 능력치 · ★1 기준"),"base stats visible")
   for item in m.text_items:
    check(item[1].y<h-10,"text stays inside viewport %s"%str(item[2]))
  d.selected=-1;d.scroll=0
 d.draw(m,480);d.press(m,d.rects.categories[0].get_center());d.draw(m,480)
 check(d.region==5 and d.category=="fish","fish location retained across category navigation")
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print("CODEX089_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
