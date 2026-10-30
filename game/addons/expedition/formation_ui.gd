extends RefCounted
var owner_ref:WeakRef
var v:
 get:return owner_ref.get_ref() if owner_ref else null
 set(value):owner_ref=weakref(value)
var data
var modal_rects:Dictionary={}
func sprite(m,id,box):v.sprite(m,id,box)
func button(m,key,r,txt):v.button(m,key,r,txt)
func label(m,s,p,size=9,c=Color("493421"),center=false,w=220):m._text(s,p,size,c,center,w)
func stars(m,u,p,center=false):
 label(m,"★".repeat(int(u.star)),p,10,Color("a57425"),center,70)
func draw(owner,m,y:float,bottom:float)->void:
 v=owner;data=v.data;v.role_badges=[]
 var variant:int=1
 var compact:bool=bottom-y<350
 if v.formation_uid>=0 and m.get_viewport_rect().size.y<620:comparison(m,false);return
 var green:=Color("39715c")
 label(m,"출전 병사",Vector2(20,y+10),10)
 label(m,"%d / 3"%data.team.size(),Vector2(246,y+10),9,green,true,30)
 y+=18
 for visual in 3:
  var slot:int=2-visual
  var u:Dictionary=data.unit(data.team[slot]) if slot<data.team.size() else {}
  var spec:Dictionary=data.catalog.soldiers[int(u.id)] if not u.is_empty() else {}
  var r:=Rect2(18+visual*80,y,74,92 if compact else 111)
  m._ui_style_box(m.sb_chip,r)
  m._ui_rect(Rect2(r.position+Vector2(5,5),Vector2(64,14)),Color("e1e7d8"))
  label(m,["앞","중간","뒤"][slot],r.position+Vector2(37,15),9,green,true,64)
  if not u.is_empty():
   v.role_badges.push_front({"role":spec.role,"rect":r})
   sprite(m,int(u.id),Rect2(r.position+Vector2(17,20),Vector2(40,35)))
   label(m,"★".repeat(int(u.star))+(" +%d"%u.get("level",0) if compact else ""),r.position+Vector2(37,62),8,Color("a57425"),true,68)
   if not compact:
    label(m,spec.name,r.position+Vector2(37,75),8,Color("493421"),true,68)
    label(m,{"attack":"공격","defense":"방어","support":"지원"}[spec.role]+" · +%d"%u.get("level",0),r.position+Vector2(37,88),8,Color("75614d"),true,68)
   label(m,"해제",r.position+Vector2(37,85 if compact else 103),8,green,true,68)
   v.rects["clear_slot:%d"%slot]=Rect2(r.position+Vector2(4,r.size.y-20),Vector2(66,18))
  else:label(m,"빈 자리",r.get_center(),9,Color("75614d"),true,68)
  v.rects["slot:%d"%slot]=r

 y+=100 if compact else 119
 if v.formation_uid>=0:comparison(m,false);return
 label(m,"보유 병사를 누르면 배치칸이 열려요",Vector2(135,y+9),8,Color("75614d"),true,234)
 y+=18
 for i in 4:
  var r:=Rect2(18+i*59,y,57,23)
  button(m,"role_filter:"+["all","attack","defense","support"][i],r,["전체","공격","방어","지원"][i])
  if v.role_filter==["all","attack","defense","support"][i]:m._ui_rect(Rect2(r.position+Vector2(5,20),Vector2(47,2)),green)
 y+=31
 label(m,"보유 병사",Vector2(20,y+7),9)
 label(m,"성급 / 강화",Vector2(245,y+7)-Vector2(m._text_w("성급 / 강화",8),0),8,Color("75614d"))
 y+=14
 var units:Array=data.soldiers.filter(func(u):return v.role_filter=="all" or data.catalog.soldiers[int(u.id)].role==v.role_filter)
 v.formation_viewport=Rect2(18,y,234,maxf(64,bottom-y-20))
 v.formation_max_scroll=maxf(0,ceilf(units.size()/2.0)*70-v.formation_viewport.size.y)
 v.formation_scroll=clampf(v.formation_scroll,0,v.formation_max_scroll)
 for i in units.size():
  var u:Dictionary=units[i];var spec:Dictionary=data.catalog.soldiers[int(u.id)]
  var r:=Rect2(18+(i%2)*119,y+floori(i/2.0)*70-roundf(v.formation_scroll),115,66)
  if r.position.y<y or r.end.y>v.formation_viewport.end.y:continue
  m._ui_style_box(m.sb_chip,r)
  sprite(m,int(u.id),Rect2(r.position+Vector2(70,3),Vector2(34,32)))
  stars(m,u,r.position+Vector2(7,17))
  label(m,"강화 +%d"%u.get("level",0),r.position+Vector2(7,30),8)
  label(m,spec.name,r.position+Vector2(8,44),8,Color("493421"),false,99)
  label(m,v.ROLES[spec.role],r.position+Vector2(8,58),8,green)
  label(m,"편성 중" if int(u.uid) in data.team else "눌러 배치",r.position+Vector2(76,58),8,Color("75614d"),true,65)
  v.rects["formation_unit:%d"%u.uid]=r
 if v.formation_max_scroll>0:
  m._ui_rect(Rect2(254,y,2,v.formation_viewport.size.y),Color("d3c39e"))
  var thumb:float=maxf(15,v.formation_viewport.size.y*v.formation_viewport.size.y/(ceilf(units.size()/2.0)*70))
  m._ui_rect(Rect2(254,y+v.formation_scroll/v.formation_max_scroll*(v.formation_viewport.size.y-thumb),2,thumb),Color("9d7c4c"))
 label(m,"%d마리 · 위아래로 밀어 보기"%units.size(),Vector2(135,bottom-7),8,Color("75614d"),true,234)

func comparison(m,cards:bool):
 var green:=Color("39715c");var red:=Color("a44e3c");var muted:=Color("75614d")
 var old:Dictionary=data.unit(data.team[v.formation_target]) if v.formation_target<data.team.size() else {};var chosen:Dictionary=data.unit(v.formation_uid)
 var before:Dictionary=data.stats(old) if not old.is_empty() else {"atk":0,"hp":0,"def":0};var after:Dictionary=data.stats(chosen)
 # Keep the top formation visible. Only the roster is covered by this review-only dialog.
 var dy:float=minf(282,m.get_viewport_rect().size.y-338)-282
 var r:=Rect2(12,282+dy,246,326)
 modal_rects={"cancel":Rect2(229,287+dy,22,22)}
 m._ui_style_box(m.sb_chip,r)
 label(m,"병사 배치",Vector2(25,302+dy),12)
 label(m,"×",Vector2(242,302+dy),12,muted,true,18)
 for i in 3:
  var tr:=Rect2(23+i*76,311+dy,72,25)
  m._ui_style_box(m.sb_btn,tr)
  if i==2-v.formation_target:m._ui_rect(tr.grow(-3),green,false,1)
  modal_rects["target:%d"%(2-i)]=tr
  label(m,["뒤","중간","앞"][i],tr.get_center()+Vector2(0,4),10,green if i==2-v.formation_target else muted,true,66)
 label(m,"현재 "+["앞","중간","뒤"][v.formation_target]+"자리",Vector2(76,352+dy),8,muted,true,102)
 label(m,"교체할 병사",Vector2(194,352+dy),8,green,true,102)
 for i in 2:
  var u:Dictionary=old if i==0 else chosen;var x:float=23+i*118
  if u.is_empty():
   label(m,"빈 자리",Vector2(x+53,390+dy),10,muted,true,106);continue
  sprite(m,int(u.id),Rect2(x+35,356+dy,36,34))
  label(m,data.catalog.soldiers[int(u.id)].name,Vector2(x+53,403+dy),9,Color("493421"),true,106)
  label(m,"★".repeat(int(u.star))+"  +%d"%u.get("level",0),Vector2(x+53,418+dy),9,Color("a57425"),true,106)
 label(m,"→",Vector2(135,381+dy),12,muted,true,20)
 if not cards:
  label(m,"현재 → 교체 후",Vector2(150,438+dy),8,muted,true,110)
  for i in 3:
   var key:String=["atk","hp","def"][i];var delta:int=after[key]-before[key];var yy:float=455+dy+i*19
   m._ui_rect(Rect2(24,yy-12,222,18),Color("e1e7d8") if delta>0 else Color("efded0"))
   label(m,["공격력","체력","방어력"][i],Vector2(28,yy),9)
   label(m,"%d → %d"%[before[key],after[key]],Vector2(142,yy),9,muted,true,95)
   label(m,("▲ +" if delta>0 else ("▼ " if delta<0 else ""))+str(delta),Vector2(219,yy),9,green if delta>0 else (red if delta<0 else muted),true,56)
 else:
  for i in 3:
   var key:String=["atk","hp","def"][i];var delta:int=after[key]-before[key]
   var cr:=Rect2(23+i*76,431+dy,72,64)
   m._ui_rect(cr,Color("e1e7d8") if delta>0 else Color("efded0"))
   label(m,["공격력","체력","방어력"][i],cr.position+Vector2(36,15),9,muted,true,68)
   label(m,("▲ +" if delta>0 else ("▼ " if delta<0 else ""))+str(delta),cr.position+Vector2(36,34),12,green if delta>0 else (red if delta<0 else muted),true,68)
   label(m,"%d → %d"%[before[key],after[key]],cr.position+Vector2(36,53),8,muted,true,68)
 label(m,"역할  %s → %s"%[v.ROLES[data.catalog.soldiers[int(old.id)].role] if not old.is_empty() else "없음",v.ROLES[data.catalog.soldiers[int(chosen.id)].role]],Vector2(25,513+dy),9)
 label(m,"현재: "+(str(data.catalog.soldiers[int(old.id)].description) if not old.is_empty() else "없음"),Vector2(25,529+dy),8,muted,false,220)
 label(m,"교체: "+str(data.catalog.soldiers[int(chosen.id)].description),Vector2(25,546+dy),8,green,false,220)

 for i in 2:
  var br:=Rect2(23+i*114,562+dy,110,29)
  modal_rects["confirm" if i==1 else "cancel_button"]=br
  m._ui_style_box(m.sb_btn,br)
  label(m,["취소",["앞","중간","뒤"][v.formation_target]+("자리 교체" if not old.is_empty() else "에 배치")][i],br.get_center()+Vector2(0,4),10,green if i==1 else muted,true,102)

func press(owner,m,pos:Vector2):
 v=owner;data=v.data
 for key in modal_rects:
  if not modal_rects[key].has_point(pos):continue
  if str(key).begins_with("cancel"):v.formation_uid=-1;return
  if str(key).begins_with("target:"):v.formation_target=int(str(key).get_slice(":",1));return
  if key=="confirm":
   if data.active():m.show_toast("탐험 중에는 편성을 바꿀 수 없어요",Color("ffdc96"));return
   if data.unit(v.formation_uid).is_empty():v.formation_uid=-1;return
   var previous:Array=data.team.duplicate()
   var source:int=data.team.find(v.formation_uid)
   var target:int=mini(v.formation_target,data.team.size())
   if target<data.team.size():
    if source>=0:data.team[source]=data.team[target]
    data.team[target]=v.formation_uid
   elif source<0 and data.team.size()<3:data.team.append(v.formation_uid)
   if not m._save_game():data.team=previous;m.show_toast("저장하지 못했어요. 다시 시도해 주세요",Color("ffdc96"));return
   v.formation_uid=-1;return
