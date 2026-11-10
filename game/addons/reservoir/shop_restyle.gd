extends RefCounted
const INK=Color("382619")
const CREAM=Color("fff0d1")
const TEAL=Color("08646b")
static var textures:Dictionary={}
static func draw_art(m,name:String,r:Rect2)->void:
 if not textures.has(name):textures[name]=load("res://art/shop_repair/"+name+".png")
 var tex:Texture2D=textures[name]
 var src:Vector2=tex.get_size()
 var edge:float=24
 var border:float=9 if name=="panel" else 8
 var xs:Array=[0.0,edge,src.x-edge,src.x]
 var ys:Array=[0.0,edge,src.y-edge,src.y]
 var dx:Array=[r.position.x,r.position.x+border,r.end.x-border,r.end.x]
 var dy:Array=[r.position.y,r.position.y+border,r.end.y-border,r.end.y]
 for iy in 3:
  for ix in 3:
   m._ui_texture_rect_region(tex,Rect2(dx[ix],dy[iy],dx[ix+1]-dx[ix],dy[iy+1]-dy[iy]),Rect2(xs[ix],ys[iy],xs[ix+1]-xs[ix],ys[iy+1]-ys[iy]))
static func panel(m,r:Rect2)->void:draw_art(m,"panel",r)
static func frame(m,r:Rect2,fill:Color,wood:bool=false,gold:bool=false)->void:
 var name:String="header" if wood else "teal" if fill.b>fill.r and fill.g>fill.r else "equipment" if r.size.x<85 and r.size.y>35 else "card"
 draw_art(m,name,r)
static func button(m,r:Rect2,s:String,active:bool=true,tab:bool=false)->void:
 draw_art(m,"button" if active else "card",r)
 m._text(s,r.get_center()+Vector2(0,4),10,CREAM if active else Color("6e5c49"),true,r.size.x-10)
static func header(m,r:Rect2)->void:frame(m,r,Color("67422c"),true,true)
static func pond_icon(m,box:Rect2,pump:bool=false)->void:
 var tex:Texture2D=load("res://art/shop_repair/"+("pump" if pump else "pond")+".png")
 var size:Vector2=tex.get_size()*minf(box.size.x/tex.get_width(),box.size.y/tex.get_height())
 m._ui_texture_rect(tex,Rect2((box.get_center()-size/2).round(),size.round()))
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
