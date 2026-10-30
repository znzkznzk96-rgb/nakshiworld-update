extends RefCounted
func label(m,s:String,p:Vector2,size:int=10,c:Color=Color("493421"),center:bool=false,w:float=220):
 m._text(s,p,size,c,center,w)
func line(m,x:float,y:float,w:float):
 m._ui_rect(Rect2(x,y,w,1),Color("c6b59b"))
 m._ui_rect(Rect2(x+w/2-2,y-1,4,3),Color("a88b64"))
func badge(m,r:Rect2,s:String):
 m._ui_rect(r,Color("e0e5d5"));m._ui_rect(Rect2(r.position.x,r.end.y-1,r.size.x,1),Color("91a38a"))
 label(m,s,r.get_center()+Vector2(0,3),7,Color("436951"),true,r.size.x-4)
func corners(m,r:Rect2):
 for p in [r.position,r.position+Vector2(r.size.x-6,0),r.position+Vector2(0,r.size.y-6),r.end-Vector2(6,6)]:
  m._ui_rect(Rect2(p,Vector2(6,1)),Color("64836a"))
  m._ui_rect(Rect2(p+Vector2(0 if p.x==r.position.x else 5,0),Vector2(1,6)),Color("64836a"))
func rod(v,m,i:int,box:Rect2):
 var t:Texture2D=v.rods[i]
 var sz:=t.get_size()*minf(box.size.x/t.get_width(),box.size.y/t.get_height())
 m._ui_texture_rect(t,Rect2((box.get_center()-sz/2).round(),sz.round()))
func button(m,r:Rect2,s:String):
 m._ui_style_box(m.sb_btn,r);label(m,s,r.get_center()+Vector2(0,4),10,Color("493421"),true,r.size.x-12)
func draw_rods(v,m,r:Rect2,y:float):
 var x:=r.position.x+14;var w:=226.0
 var selected:int=clampi(v.rod_page,0,5)
 label(m,"낚싯대 선택",Vector2(x,y+10),10)
 label(m,("보유 %d / 6" % m.equipment.rods.size()),Vector2(x+w-4,y+10)-Vector2(m._text_w(("보유 %d / 6" % m.equipment.rods.size()),8),0),8,Color("85735d"))
 y+=18
 for i in 6:
  var cr:=Rect2(x+(i%3)*76,y+floori(i/3.0)*62,72,58)
  m._ui_style_box(v.active_style.card,cr)
  if i==selected:
   m._ui_rect(cr.grow(-2),Color("e1e6d7"));corners(m,cr.grow(-2))
  m._ui_rect(Rect2(cr.position+Vector2(14,30),Vector2(44,1)),Color("c6b59b"))
  rod(v,m,i,Rect2(cr.position+Vector2(22,3),Vector2(28,28)))
  label(m,["대나무","카본","원투","선상","심해","은하"][i],cr.position+Vector2(36,40),9,Color("493421"),true,68)
  var current:bool=i==m.rod_lv and m.equipment.rod_equipped
  var owned:bool=i in m.equipment.rods
  var status:String="사용 중" if current else ("선택 중" if i==selected else ("보유" if owned else ("구매 가능" if i<=m.rod_owned+1 else "잠김")))
  if current or i==selected:badge(m,Rect2(cr.position+Vector2(8,44),Vector2(56,11)),status)
  else:label(m,status,cr.position+Vector2(36,52),7,Color("85735d"),true,68)
  v.rects.rows.append([cr,"rodselect:%d"%i])
 y+=129
 m._ui_rect(Rect2(x,y,3,17),Color("64836a"))
 label(m,v.ROD_NAME[selected],Vector2(x+9,y+13),12)
 badge(m,Rect2(x+172,y+1,54,14),"%+d%%p" % ((selected-m.rod_lv)*12))
 m._ui_rect(Rect2(x,y+21,w,21),Color("e4e7da"))
 label(m,"감기 성능",Vector2(x+4,y+33),10)
 label(m,"+%d%% → +%d%%" % [m.rod_lv*12,selected*12],Vector2(x+120,y+33),11,Color("39715c"),false,103)
 label(m,"물고기를 더 빠르게 끌어올려요",Vector2(x+4,y+49),9,Color("75614d"))
 line(m,x,y+58,w)
 m._ui_texture_rect(m.icons.scale,Rect2(x+2,y+65,14,17))
 var owned:bool=selected in m.equipment.rods
 var current:bool=selected==m.rod_lv and m.equipment.rod_equipped
 label(m,"보유 중" if owned else m.spots.price_text(v.ROD_COST[selected])+" 비늘",Vector2(x+20,y+77),10)
 var caption:String="사용 중" if current else ("장착하기" if owned else ("잠김" if selected>m.rod_owned+1 else ("구매하기" if m.gold>=v.ROD_COST[selected] else "비늘 부족")))
 var br:=Rect2(x+116,y+64,110,26)
 button(m,br,caption)
 if owned and not current:v.rects.rows.append([br,"equip:%d"%selected])
 elif not owned and selected<=m.rod_owned+1 and m.gold>=v.ROD_COST[selected]:v.rects.rows.append([br,"rod:%d"%selected])
func draw_upgrade(v,m,r:Rect2,y:float):
 var e=v.enhancement
 var ri:int=m.rod_lv;var lv:int=m.forge_lv;var nxt:int=mini(lv+1,e.LIMIT[ri])
 var x:=r.position.x+14;var w:=226.0
 m._ui_style_box(v.active_style.card,Rect2(x,y,38,38))
 rod(v,m,ri,Rect2(x+3,y+3,32,32))
 label(m,v.ROD_NAME[ri],Vector2(x+45,y+13),12)
 badge(m,Rect2(x+45,y+20,67,17),"+%d → +%d" % [lv,nxt])
 label(m,"최대 +%d" % e.LIMIT[ri],Vector2(x+180,y+30),8,Color("75614d"))
 y+=43;line(m,x,y,w)
 m._ui_rect(Rect2(x+176,y+3,47,83),Color("e1e7d8"))
 label(m,"현재",Vector2(x+128,y+16),8,Color("75614d"),true)
 label(m,"강화 후",Vector2(x+198,y+16),8,Color("39715c"),true)
 for i in 3:
  var yy:=y+36+i*23
  var ico:Texture2D=v.tool_icons[["reel","line","scale"][i]]
  m._ui_texture_rect(ico,Rect2(x+3,yy-12,14,14))
  label(m,["감기 성능","장력 증가","판매가"][i],Vector2(x+23,yy),10)
  label(m,["+%d%%"%(lv*3),"-%d%%"%(lv*2),"+%d%%"%(lv*5)][i],Vector2(x+128,yy),11,Color("75614d"),true)
  label(m,"→",Vector2(x+160,yy),9,Color("9b8468"),true)
  label(m,["+%d%%"%(nxt*3),"-%d%%"%(nxt*2),"+%d%%"%(nxt*5)][i],Vector2(x+198,yy),11,Color("39715c"),true)
 y+=92;line(m,x,y,w)
 if lv>=e.LIMIT[ri]:
  label(m,"최고 강화 단계입니다",Vector2(135,y+30),11,Color("39715c"),true);return
 m._ui_rect(Rect2(x,y+4,w,22),Color("e4e7da"))
 label(m,"성공률",Vector2(x+5,y+18),10)
 label(m,"%d%%"%roundi(e.chance(ri,lv)*100),Vector2(x+68,y+19),14,Color("39715c"))
 var risk:bool=e.risky(ri,lv)
 label(m,"실패 시 1단계 하락" if risk else "실패해도 단계 유지",Vector2(x+123,y+18),9,Color("a34a40") if risk else Color("75614d"),false,104)
 y+=32;line(m,x,y,w)
 m._ui_texture_rect(v.tool_icons.soul,Rect2(x+5,y+9,19,19))
 label(m,"혼 %s"%m.spots.price_text(e.soul_cost(ri,lv)),Vector2(x+29,y+18),10)
 label(m,"보유 %s"%m.spots.price_text(m.souls),Vector2(x+29,y+32),8,Color("75614d"))
 m._ui_texture_rect(m.icons.scale,Rect2(x+120,y+9,16,18))
 label(m,"비늘 %s"%m.spots.price_text(e.cost(lv,ri)),Vector2(x+142,y+18),10)
 label(m,"보유 %s"%m.spots.price_text(m.gold),Vector2(x+142,y+32),8,Color("75614d"))
 y+=43
 if risk:
  e._button(v,m,Rect2(x,y,w,21),"보호권 %s · 보유 %d장"%["사용" if e.use_protection else "미사용",m.protection_tickets],"forge_protect",m.protection_tickets>0)
  e._button(v,m,Rect2(x,y+25,108,26),"보호권 1진주","forge_ticket",m.pearl>=1)
 else:label(m,"현재 단계는 하락 보호권이 필요 없어요",Vector2(135,y+9),8,Color("75614d"),true,226)
 var can:bool=m.equipment.rod_equipped and m.gold>=e.cost(lv,ri) and m.souls>=e.soul_cost(ri,lv)
 var caption:String="강화하기" if can else ("낚싯대 미장착" if not m.equipment.rod_equipped else "재료 부족")
 e._button(v,m,Rect2(x+116 if risk else x,y+25 if risk else y+18,110 if risk else w,26),caption,"forge",can)
