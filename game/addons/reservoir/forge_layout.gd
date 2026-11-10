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
 var skin=preload("res://addons/reservoir/shop_restyle.gd")
 var x:float=r.position.x+14;var w:float=226
 var selected:int=clampi(v.rod_page,0,5)
 var owned:bool=selected in m.equipment.rods
 var current:bool=selected==m.rod_lv and m.equipment.rod_equipped
 var locked:bool=not owned and selected>m.rod_owned+1
 var available:float=r.end.y-12-y
 var cell_h:float=47 if available<340 else 58
 var grid_h:float=14+cell_h*2+4
 var comparison_h:float=42 if available<340 else 50
 var hero_h:float=maxf(52,available-grid_h-comparison_h-57)
 var hero:=Rect2(x,y,w,hero_h+comparison_h+5)
 skin.frame(m,hero,Color("07515b"),false,true)
 for i in 9:
  var yy:float=y+7+i*maxf(4,(hero_h-12)/9)
  m._ui_rect(Rect2(x+5+fmod(i*13,35.0),yy,w-20-i%3*12,2),Color("0a5961"))
 label(m,"사용 중인 장비" if current else "보유 장비" if owned else "잠긴 장비" if locked else "다음 장비",Vector2(x+9,y+16),9,Color("efd18b"),false,119)
 label(m,v.ROD_NAME[selected],Vector2(x+9,y+36),12,Color("fff0d1"),false,124)
 var stand:=Rect2(x+86,y+hero_h-10,80,6)
 m._ui_rect(stand,Color("26313a"));m._ui_rect(Rect2(stand.position,Vector2(80,2)),Color("a4a8a1"))
 var rod_box:=Rect2(x+88,y+5,136,hero_h-17)
 var tex:Texture2D=v.rods[selected]
 var used:Rect2=Rect2(tex.get_image().get_used_rect())
 var scale:float=maxf(1,floorf(minf(rod_box.size.x/used.size.x,rod_box.size.y/used.size.y)))
 var size:Vector2=used.size*scale
 m._ui_texture_rect_region(tex,Rect2(Vector2(roundf(rod_box.get_center().x-size.x/2),y+hero_h-12-size.y),size),used,Color(1.45,1.45,1.45))
 var current_power:float=m.FISHING_DIFFICULTY.base_reel_power(m.rod_lv,m.active_region)
 var selected_power:float=m.FISHING_DIFFICULTY.base_reel_power(selected,m.active_region)
 var cy:float=y+hero_h
 for i in 2:
  var b:=Rect2(x+7+i*113,cy,99,comparison_h-5)
  skin.frame(m,b,Color("fff0d1"),false,i==1)
  label(m,("현재 "+["대나무","카본","원투","선상","심해","은하"][m.rod_lv]) if i==0 else "선택 장비",Vector2(b.get_center().x,b.position.y+13),9,Color("493421"),true,91)
  label(m,"+%d%%"%roundi(((current_power if i==0 else selected_power)-1)*100),Vector2(b.get_center().x,b.end.y-8),12,Color("08646b"),true,90)
 label(m,"→",Vector2(x+113,cy+comparison_h/2+3),10,Color("fff0d1"),true,12)
 y=hero.end.y+5
 label(m,"감기 성능 · "+("지역 보정 적용" if m.active_region in [1,2] else "저수지 기준"),Vector2(x,y+10),8,Color("68533d"),false,225)
 y+=18
 label(m,"장비 선택",Vector2(x,y+10),9)
 label(m,"보유 %d / 6"%m.equipment.rods.size(),Vector2(x+w-42,y+10),9,Color("68533d"),true,80)
 y+=15
 for i in 6:
  var cr:=Rect2(x+(i%3)*76,y+floori(i/3.0)*cell_h,72,cell_h-3)
  var is_locked:bool=i not in m.equipment.rods and i>m.rod_owned+1
  skin.frame(m,cr,Color("dfd1b7") if is_locked else Color("fff0d1"),false,i==selected)
  if i==selected:
   m._ui_rect(Rect2(cr.position+Vector2(3,3),Vector2(cr.size.x-6,1)),Color("e7b950"))
  rod(v,m,i,Rect2(cr.position+Vector2(17,3),Vector2(38,cell_h-28)))
  label(m,["대나무","카본","원투","선상","심해","은하"][i],cr.position+Vector2(36,cell_h-18),9,Color("493421"),true,64)
  var status:String="사용 중" if i==m.rod_lv and m.equipment.rod_equipped else "보유" if i in m.equipment.rods else "잠김" if is_locked else "선택" if i==selected else "구매 가능"
  label(m,status,cr.position+Vector2(36,cell_h-6),8,Color("08646b") if not is_locked else Color("8a7962"),true,64)
  v.rects.rows.append([cr,"rodselect:%d"%i])
 y+=cell_h*2+5
 m._ui_texture_rect(m.icons.scale,Rect2(x,y+1,13,15))
 label(m,"보유 중" if owned else m.spots.price_text(v.ROD_COST[selected])+" 비늘",Vector2(x+17,y+13),10,Color("493421"),false,107)
 label(m,"보유 "+m.spots.price_text(m.gold),Vector2(x+17,y+27),8,Color("68533d"),false,104)
 var caption:String="사용 중" if current else "장착하기" if owned else "잠김" if locked else "구매하기" if m.gold>=v.ROD_COST[selected] else "비늘 부족"
 var br:=Rect2(x+126,y,100,32)
 skin.button(m,br,caption,(owned and not current) or (not owned and not locked and m.gold>=v.ROD_COST[selected]))
 if owned and not current:v.rects.rows.append([br,"equip:%d"%selected])
 elif not owned and not locked and m.gold>=v.ROD_COST[selected]:v.rects.rows.append([br,"rod:%d"%selected])
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
  label(m,m.FISHING_DIFFICULTY.upgrade_labels(lv,m.active_region)[i],Vector2(x+128,yy),11,Color("75614d"),true)
  label(m,"→",Vector2(x+160,yy),9,Color("9b8468"),true)
  label(m,m.FISHING_DIFFICULTY.upgrade_labels(nxt,m.active_region)[i],Vector2(x+198,yy),11,Color("39715c"),true)
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
