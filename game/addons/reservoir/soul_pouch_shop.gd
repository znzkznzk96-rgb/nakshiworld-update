extends RefCounted
static func open(v,m,count: int) -> bool:
 var d=m.expedition.data
 var number: int=d.pouches if count==0 else count
 if number<=0 or number>d.pouches:return false
 var old: Dictionary=d.serialize().duplicate(true);var result: Array=d.open_pouches(number)
 if result.is_empty():return false
 if not m._save_game():
  d.restore(old);v.pouch_error="저장 실패: 주머니는 그대로예요.";return false
 v.pouch_last_open=result.duplicate();v.pouch_error="";v.commerce.notice="";m.toast_t=0.0
 return true

static func draw(v,m,r: Rect2,y: float) -> void:
 var d=m.expedition.data
 m._ui_texture_rect(v.tool_icons.soul,Rect2(115,y+2,40,40),false)
 m._text("어혼 주머니",Vector2(135,y+57),13,v.active_style.ink,true,220)
 m._text("주머니 1개 → 랜덤 어혼 1개",Vector2(135,y+76),10,v.active_style.ink,true,225)
 m._text("물 · 전기 · 독 · 빛 · 어둠  각 20%",Vector2(135,y+94),9,Color("675c4b"),true,225)
 m._text("1개 %d비늘"%d.POUCH_PRICE,Vector2(135,y+115),11,Color("82502a"),true,225)
 for i in 3:
  var count: int=[1,5,10][i];var rect:=Rect2(21+i*78,y+125,73,27)
  m._ui_style_box(m.sb_btn,rect);m._text("%d개 구매"%count,rect.get_center()+Vector2(0,4),9,v.active_style.ink,true,69)
  v.rects.rows.append([rect,"soul_pouch:%d"%count])
 m._text("보유 주머니 %d개"%d.pouches,Vector2(135,y+173),11,v.active_style.ink,true,225)
 for i in 2:
  var rect:=Rect2(21+i*119,y+184,113,29)
  m._ui_style_box(m.sb_btn,rect);m._text(["1개 열기","모두 열기"][i],rect.get_center()+Vector2(0,4),10,v.active_style.ink if d.pouches>0 else Color("9a8a78"),true,104)
  if d.pouches>0:v.rects.rows.append([rect,"pouch_open:%d"%[1,0][i]])
 if v.pouch_error!="":m._text(v.pouch_error,Vector2(135,y+235),9,Color("9b4329"),true,232)
 elif v.pouch_last_open.size()==5:
  m._text("최근 개봉: 물 +%d · 전기 +%d · 독 +%d"%v.pouch_last_open.slice(0,3),Vector2(135,y+231),9,Color("145f61"),true,232)
  m._text("빛 +%d · 어둠 +%d"%v.pouch_last_open.slice(3,5),Vector2(135,y+245),9,Color("145f61"),true,232)
