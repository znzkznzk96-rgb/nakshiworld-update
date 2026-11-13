extends SceneTree
var failures:Array=[]
func check(ok:bool,label:String):
 if not ok:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 var m=load("res://main.gd").new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false;m.TUT.done=true
 var d=m.personal_dex;var data=m.expedition.data;data.restore({})
 for id in 15:data.discover(id)
 var saved:Dictionary=data.serialize().duplicate(true)
 d.open(m)
 for height in [480,540,660]:
  d.category="fish";d.region=0;d.selected=-1;m.DEX[m.fish_key(0)]=[0,1,2,3,4];d.draw(m,height)
  for mark in ["N","R","E","L","M"]:check(m.text_items.any(func(t):return t[2]==mark),"Latin collection grade "+mark)
  check(d.rects.region_labels.size()==7,"all region names include full valley name")
  for entry in d.rects.region_labels:
   check(d.rects.regions[int(entry[0])].grow(-2).encloses(entry[2]),"region text fully inside button %s/%d"%[entry[1],height])
  var valley:Array=d.rects.region_labels.filter(func(e):return e[0]==1)
  check(valley.size()==2 and valley[0][1]+" "+valley[1][1]==d.REGIONS[1],"full valley name on two readable lines")
  var record_before:String=JSON.stringify(d.serialize())
  for area in 6:
   d.press(m,d.rects.regions[area].get_center());d.draw(m,height)
   check(d.region==area and d.selected==-1,"region button selects exact destination %d/%d"%[area,height])
   check(d.rects.regions.size()==6 and d.visible_rows>=3,"all region targets and collection rows remain usable")
  check(JSON.stringify(d.serialize())==record_before,"region selection preserves specimen records")
  d.press(m,d.rects.categories[1].get_center());d.draw(m,height)
  check(d.rects.stars.size()==3 and d.rects.filters.size()==4,"star and role controls coexist")
  for star in [1,2,3]:
   d.press(m,d.rects.stars[star-1].get_center());d.draw(m,height)
   check(d.soldier_star==star and d.rows_total==15,"all discovered species shown at chosen star")
   for row in d.rects.fish:check(d.list_view.encloses(row[0]),"row inside scroll view")
   for id in 15:
    d.selected=id;d.draw(m,height)
    var info:Dictionary=data.TIER_SKILLS.info(id,star)
    check(m.text_items.any(func(t):return t[2]=="%s · %d초"%[info.name,info.cd]),"real tier skill %d/%d"%[id,star])
    check(m.text_items.any(func(t):return t[2]=="기본 능력치 · ★%d 기준"%star),"star-specific base stats heading")
    for key in ["hp","atk","def"]:check(m.text_items.any(func(t):return t[2]==str(int(data.catalog.soldiers[id].stars[str(star)][key]))),"actual star stat "+key)
    for text in m.text_items:check(text[1].y<height-10,"text remains inside viewport")
   d.selected=-1;d.draw(m,height)
  d.press(m,d.rects.filters[2].get_center());d.draw(m,height)
  for row in d.rects.fish:check(data.catalog.soldiers[row[1]].role=="defense" and d.soldier_star==3,"role filter preserves star selection")
  d.role_filter="all";d.scroll=100000;d.draw(m,height)
  check(d.rects.fish.back()[1]==14,"last soldier reachable by scroll")
  d.scroll=0
 check(saved==data.serialize(),"view selection never changes discoveries, soldiers or save data")
 data.restore({});d.selected=-1;d.category="soldier";d.role_filter="all";d.draw(m,480)
 check(d.rects.fish.is_empty(),"unknown soldiers still hide details")
 m.audio_feedback.dispose();m.queue_free();await process_frame
 print("DEX_READABILITY_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
