extends RefCounted
const INK=Color("382619")
const CREAM=Color("fff0d1")
const TEAL=Color("08646b")
static func frame(m,r:Rect2,fill:Color,wood:bool=false,gold:bool=false)->void:
 m._ui_rect(Rect2(r.position+Vector2(0,2),r.size),Color("251c19"))
 m._ui_rect(r,Color("573a28"));m._ui_rect(r.grow(-1),Color("bf9060"));m._ui_rect(r.grow(-3),fill)
 m._ui_rect(Rect2(r.position+Vector2(3,2),Vector2(r.size.x-6,1)),Color("efd1a0"))
 m._ui_rect(Rect2(r.position+Vector2(3,r.size.y-3),Vector2(r.size.x-6,1)),Color("63452c"))
 if wood:
  for i in 18:
   var x:float=r.position.x+5+fmod(i*37.0,r.size.x-18)
   var y:float=r.position.y+5+fmod(i*7.0,maxf(1,r.size.y-10))
   m._ui_rect(Rect2(x,y,7+i%6,1),Color("9e6b40") if i%2==0 else Color("4b3025"))
   if i%3==0:m._ui_rect(Rect2(x+2,y+1,6+i%4,1),Color("805432"))
 for p in [r.position,r.position+Vector2(r.size.x-5,0),r.position+Vector2(0,r.size.y-5),r.end-Vector2(5,5)]:
  m._ui_rect(Rect2(p,Vector2(5,5)),Color("c69a60") if gold else Color("805536"))
  m._ui_rect(Rect2(p+Vector2(1,1),Vector2(3,2)),Color("f6d788") if gold else Color("d4ad74"))
static func button(m,r:Rect2,s:String,active:bool=true,tab:bool=false)->void:
 frame(m,r,TEAL if active else Color("fff0d1") if tab else Color("d0c1a5"),false,active)
 m._text(s,r.get_center()+Vector2(0,4),10,CREAM if active else Color("6e5c49"),true,r.size.x-10)
static func header(m,r:Rect2)->void:frame(m,r,Color("67422c"),true,true)
static func pond_icon(m,box:Rect2,pump:bool=false)->void:
 var o:Vector2=(box.get_center()-Vector2(24,24)).round()
 if pump:
  for item in [[6,3,9,17,"513b29"],[8,4,5,15,"b78444"],[8,4,5,2,"e0bd75"],[12,8,8,4,"63452c"],[13,9,6,2,"d1a25a"],[17,11,3,8,"53d4e1"],[18,12,1,6,"d3ffff"],[3,20,21,3,"65462d"],[8,19,16,3,"269aaf"],[10,19,12,1,"a2f3ef"]]:
   m._ui_rect(Rect2(o+Vector2(item[0],item[1])*2,Vector2(item[2],item[3])*2),Color(item[4]))
 else:
  for item in [[1,7,22,14,"513b29"],[3,9,18,9,"178b9f"],[4,10,16,2,"4bc5d6"],[3,18,18,3,"986736"],[3,21,18,2,"563725"],[1,5,3,17,"c39654"],[20,5,3,17,"c39654"],[2,5,1,14,"edca89"],[5,12,4,1,"c4f7ef"],[12,14,6,1,"77e3e8"],[7,16,2,1,"c4f7ef"]]:
   m._ui_rect(Rect2(o+Vector2(item[0],item[1])*2,Vector2(item[2],item[3])*2),Color(item[4]))
static func hall(v,m,r:Rect2,y:float)->void:
 var x:float=r.position.x+12;var w:float=r.size.x-24
 var status:=Rect2(x,y,w,62)
 frame(m,status,TEAL,false,true)
 m._ui_fish(0,Rect2(x+8,y+17,40,25))
 m._text("어장 현황",Vector2(x+55,y+20),11,CREAM,false,104)
 m._text("%d / %d마리"%[roundi(m.pond_stock),roundi(m.pond_max())],Vector2(x+55,y+37),11,CREAM,false,w-64)
 var bar:=Rect2(x+55,y+45,w-65,5);m._ui_rect(bar,Color("163d43"))
 m._ui_rect(Rect2(bar.position,Vector2(floorf(bar.size.x*clampf(m.pond_stock/m.pond_max(),0,1)),5)),Color("53c9bd"))
 if m.pond_overflow>0:m._text("잔여 %d마리"%roundi(m.pond_overflow),Vector2(x+w-42,y+18),8,CREAM,true,70)
 y+=73
 var ch:float=72 if r.size.y>=420 else 64
 for i in 2:
  var key:String="pondcap" if i==0 else "pondregen"
  var lv:int=m.pond_cap_lv if i==0 else m.pond_regen_lv
  var available:bool=v.FACILITIES.unlocked(m,key)
  var cost:int=(v.POND_CAP_COST[lv] if i==0 else v.POND_REGEN_COST[lv]) if available else 0
  var cell:=Rect2(x,y,w,ch);frame(m,cell,Color("fff0d1"),false,true)
  pond_icon(m,Rect2(x+4,y+(ch-48)/2,48,48),i==1)
  m._text(("어장 규모" if i==0 else "회복 시설")+" %d / 12"%lv,Vector2(x+58,y+20),10,INK,false,w-128)
  var desc:String=v.FACILITIES.lock_label(m,key)
  if available:
   desc="%d → %d마리"%[roundi(m.pond_max()),roundi(m.pond_base+v.FACILITIES.STOCK_ADD[lv+1])] if i==0 else "시간당 %d → %d마리"%[roundi(m.pond_recovery()),v.FACILITIES.RECOVERY[lv+1]]
  m._text(v._short(m,desc,10,w-128),Vector2(x+58,y+40),10,TEAL if available else Color("806b53"),false,w-128)
  var b:=Rect2(cell.end.x-65,y+(ch-32)/2,60,32)
  button(m,b,m.spots.price_text(cost) if available else ("완료" if lv>=12 else "잠김"),available and m.gold>=cost)
  if available:v.rects.rows.append([b,key])
  y+=ch+11
 var note:=Rect2(x,y,w,minf(65,r.end.y-y-12));frame(m,note,Color("f5e6c5"))
 m._text("낚시 1회마다 어장 1마리 감소",Vector2(x+9,y+19),9,INK,false,w-18)
 m._text("쉬는 동안 회복 · 어장이 줄면",Vector2(x+9,y+36),9,INK,false,w-18)
 m._text("높은 등급 물고기가 드물어져요",Vector2(x+9,y+52),9,INK,false,w-18)
