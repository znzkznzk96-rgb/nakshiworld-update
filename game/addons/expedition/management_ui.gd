extends RefCounted
var owner_ref:WeakRef
var v:
 get:return owner_ref.get_ref() if owner_ref else null
var uid:int=-1
var confirm:bool=false
var skill_textures:Dictionary={}
const SKILLS=['drain','bolt','thorns','shield','curse','flurry','regen','heal','mend','weaken','pierce','counter','ward','poison','reflect']
const NAMES=['흡수','전격 화살','독가시','보호막','등불의 격려','연속 베기','재생','긴급 회복','자가 회복','약화','방어 관통','반격','보호 약초','맹독','피해 반사']
func bind(owner):owner_ref=weakref(owner)
func text(m,s,p,size=9,center=false,w=220,c=Color('493421')):m._text(s,p,size,c,center,w)
func skill(m,key:String,r:Rect2):
 var i:int=SKILLS.find(key)
 if i<0:return
 if not skill_textures.has(key):
  skill_textures[key]=load('res://art/ui/soldier_skills/'+key+'.png')
 m._ui_texture_rect(skill_textures[key],r)
func select(m,r:Rect2,number:String=''):
 m._ui_rect(r.grow(-1),Color('68411d'),false,3)
 m._ui_rect(r.grow(-2),Color('f4bd4d'),false,2)
 for p in [r.position+Vector2(1,1),r.position+Vector2(r.size.x-6,1),r.end-Vector2(6,6),r.position+Vector2(1,r.size.y-6)]:m._ui_rect(Rect2(p,Vector2(5,5)),Color('ffe49b'))
 if number!='':
  var width:int=23 if number.length()>1 else 14
  var b:=Rect2(r.end.x-width,r.position.y,width,13)
  m._ui_rect(b,Color('68411d'));m._ui_rect(b.grow(-1),Color('f4bd4d'))
  text(m,number,b.position+Vector2(width/2.0,10),8,true,width-2)
func dim(m,cover:Rect2=Rect2()):
 var kept:Array=[]
 for item in m.text_items:
  if cover.has_area() and item[1].y>=cover.position.y-4 and item[1].y<=cover.end.y+12:continue
  var row:Array=item.duplicate();row[6].a*=.28;kept.append(row)
 m.text_items=kept
 m._ui_rect(Rect2(0,0,270,m.get_viewport_rect().size.y),Color(0,0,0,.67))
func modal(m,height:float)->float:
 var y:float=roundf((m.get_viewport_rect().size.y-height)/2)
 dim(m,Rect2(17,y,236,height));v.rects={}
 v.panel(m,Rect2(17,y,236,height));return y
func grid(m,y:float,bottom:float):
 if v.tab==1:
  merge_list(m,y,bottom);return
 var d=v.data
 if v.tab==1:
  text(m,'같은 별 · +3 병사 2마리',Vector2(135,y+8),9,true)
  for i in 2:
   var r:=Rect2(48+i*83,y+15,49,47);m._ui_style_box(m.sb_chip,r)
   if i<v.selected.size():
    var u:Dictionary=d.unit(v.selected[i]);v.sprite(m,u.id,r.grow(-6),0,1.0,int(u.star));select(m,r,str(i+1))
   else:text(m,'재료 선택',r.get_center()+Vector2(0,3),7,true,46)
  text(m,'+',Vector2(114,y+43),14,true,20)
  text(m,'→ ★'+str(int(d.unit(v.selected[0]).star)+1) if not v.selected.is_empty() else '→ ?',Vector2(233,y+43),9,true,38)
  y+=70
 else:
  for i in 4:
   var r:=Rect2(18+i*59,y,57,22);v.button(m,'manage_filter:'+['all','attack','defense','support'][i],r,['전체','공격','방어','지원'][i])
   if v.role_filter==['all','attack','defense','support'][i]:select(m,r)
  y+=29
 var units:Array=d.soldiers.filter(func(u):return v.tab==1 or v.role_filter=='all' or d.catalog.soldiers[int(u.id)].role==v.role_filter)
 var rows:int=maxi(1,int((bottom-y-53)/68))
 v.roster_viewport=Rect2(18,y,234,rows*68)
 v.roster_max_scroll=maxf(0,ceilf(units.size()/3.0)*68-rows*68)
 v.roster_scroll=clampf(v.roster_scroll,0,v.roster_max_scroll)
 var first:int=floori(v.roster_scroll/68)*3
 for i in rows*3:
  if first+i>=units.size():break
  var u:Dictionary=units[first+i];var spec:Dictionary=d.catalog.soldiers[int(u.id)]
  var r:=Rect2(18+(i%3)*79,y+floori(i/3.0)*68,76,64)
  m._ui_style_box(m.sb_chip,r)
  v.sprite(m,int(u.id),Rect2(r.position+Vector2(22,3),Vector2(32,28)),0,1.0,int(u.star))
  text(m,m._ui_wrap(spec.name,7,68,1),r.position+Vector2(38,42),7,true,69)
  text(m,'★'.repeat(int(u.star))+' +%d'%u.level,r.position+Vector2(38,55),8,true,69)
  if v.tab==1 and int(u.uid) in v.selected:select(m,r,str(v.selected.find(int(u.uid))+1))
  if int(u.uid) in d.team:text(m,'출전',r.position+Vector2(5,12),6,false,24,Color('39715c'))
  if v.tab==1 and int(u.level)<3:text(m,'+3 필요',r.position+Vector2(38,29),6,true,65,Color('8f6951'))
  if bool(u.locked):v.lock_icon(m,'lock_status:%d'%u.uid,Rect2(r.end.x-20,r.position.y+1,18,21),true)
  v.rects['select:%d'%u.uid]=r
 if units.is_empty():text(m,'어혼을 연성해 병사를 만들어 주세요',Vector2(135,y+35),9,true)
 var foot:float=v.roster_viewport.end.y
 text(m,('선택 %d / 2 · '%v.selected.size() if v.tab==1 else '')+'%d마리 · 위아래로 밀기'%units.size(),Vector2(135,foot+12),8,true)
 if v.tab==1:
  var q:Dictionary=d.merge_cost(v.selected[0],v.selected[1]) if v.selected.size()==2 else {}
  v.button(m,'merge_review',Rect2(18,foot+20,234,27),'합성 결과·소모 재료 확인',not q.is_empty() and not d.active())
 else:text(m,'병사를 눌러 설명 · 잠금 · 분해',Vector2(135,foot+34),9,true)
func rewards(m,element:int,y:float):
 m._ui_texture_rect(v.textures[v.EFILES[element]],Rect2(37,y,25,25))
 text(m,v.data.ELEMENTS[element]+' 어혼 1개',Vector2(73,y+17),9,false,95)
 m._ui_texture_rect(m.icons['coin_s'],Rect2(165,y+2,18,20))
 text(m,'250 비늘',Vector2(188,y+17),9,false,56)
func detail(m):
 var d=v.data;var u:Dictionary=d.unit(uid)
 if u.is_empty():v.opened='alchemy';return
 var spec:Dictionary=d.catalog.soldiers[int(u.id)];var st:Dictionary=d.stats(u)
 var y:float=modal(m,326 if not confirm else 244)
 text(m,'병사 상세' if not confirm else '병사를 분해할까요?',Vector2(135,y+23),13,true)
 v.sprite(m,int(u.id),Rect2(34,y+34,66,55),0,1.0,int(u.star))
 text(m,spec.name,Vector2(111,y+51),10,false,130)
 text(m,'★'.repeat(int(u.star))+' +%d'%u.level,Vector2(111,y+69),9)
 text(m,d.ELEMENTS[d.native_element(uid)]+' 속성 · '+v.ROLES[spec.role],Vector2(111,y+85),9)
 if confirm:
  text(m,'돌려받는 보상',Vector2(135,y+114),11,true)
  rewards(m,d.native_element(uid),y+124)
  text(m,'분해한 병사는 사라져요',Vector2(135,y+177),9,true,210,Color('a44e3c'))
  v.button(m,'salvage_cancel',Rect2(28,y+200,103,28),'취소')
  v.button(m,'salvage_confirm',Rect2(139,y+200,103,28),'분해 확정',d.can_salvage(uid));return
 for box in [Rect2(27,y+94,216,35),Rect2(27,y+133,216,48),Rect2(27,y+184,216,32),Rect2(27,y+220,216,51)]:
  m._ui_rect(box,Color('b99460'),false,1)
 for i in 3:
  var x:float=30+i*73
  v.symbol(m,['hp','attack','defense'][i],Rect2(x,y+99,16,16))
  text(m,['체력','공격','방어'][i],Vector2(x+20,y+108),8,false,45)
  text(m,str(st[['hp','atk','def'][i]]),Vector2(x+35,y+124),11,true,65)
 skill(m,spec.skill,Rect2(30,y+137,32,32))
 text(m,NAMES[SKILLS.find(spec.skill)],Vector2(69,y+149),10,false,170)
 var lines:String=m._ui_wrap(spec.description,8,165,2)
 var index:int=0
 for line in lines.split('\n'):
  text(m,line,Vector2(69,y+162+index*12),8,false,168);index+=1
 v.lock_icon(m,'manage_lock',Rect2(30,y+189,24,24),u.locked)
 text(m,'잠금 중' if u.locked else '잠금 해제',Vector2(61,y+205),9)
 v.button(m,'manage_lock',Rect2(169,y+187,70,25),'잠금 해제' if u.locked else '잠그기')
 text(m,'분해 시 반환',Vector2(30,y+232),8)
 rewards(m,d.native_element(uid),y+236)
 v.button(m,'manage_back',Rect2(27,y+282,65,28),'목록')
 v.button(m,'upgrade:%d'%uid,Rect2(99,y+282,65,28),'강화')
 v.button(m,'salvage_open',Rect2(171,y+282,72,28),'분해하기',d.can_salvage(uid))
func result(m,u:Dictionary):
 var spec:Dictionary=v.data.catalog.soldiers[int(u.id)]
 var y:float=modal(m,350)
 text(m,'연성 완료!',Vector2(135,y+24),15,true)
 text(m,'새로운 병사를 획득했어요',Vector2(135,y+41),9,true)
 m._ui_style_box(m.sb_chip,Rect2(42,y+49,186,128))
 v.sprite(m,u.id,Rect2(96,y+56,78,69),0,1.0,int(u.star))
 text(m,'★'.repeat(int(u.star)),Vector2(135,y+141),11,true,210,Color('a57425'))
 text(m,spec.name,Vector2(135,y+163),12,true,174)
 for i in 3:
  var x:float=28+i*73
  m._ui_style_box(m.sb_chip,Rect2(x,y+184,69,38))
  v.symbol(m,['hp','attack','defense'][i],Rect2(x+5,y+191,16,16))
  text(m,['체력','공격','방어'][i],Vector2(x+24,y+197),8,false,42)
  text(m,'+%d%%'%int(u.iv[i]),Vector2(x+43,y+214),10,true,45)
 m._ui_style_box(m.sb_chip,Rect2(28,y+229,214,49))
 skill(m,spec.skill,Rect2(33,y+235,32,32))
 text(m,NAMES[SKILLS.find(spec.skill)],Vector2(72,y+243),10,false,160)
 var n:int=0
 for line in m._ui_wrap(spec.description,8,160,2).split('\n'):
  text(m,line,Vector2(72,y+257+n*11),8,false,160);n+=1
 v.primary(m,'pending_again',Rect2(29,y+285,212,25),'어혼 연성으로 돌아가기')
 v.button(m,'pending_done',Rect2(29,y+316,212,24),'병사 보관함으로')

func merge_list(m,y:float,bottom:float):
 var d=v.data
 text(m,'합성할 병사 2마리를 선택하세요',Vector2(135,y+8),10,true)
 text(m,'같은 별 · +3 병사 2마리',Vector2(135,y+23),8,true)
 for i in 2:
  var r:=Rect2(47+i*101,y+29,75,53)
  m._ui_style_box(m.sb_chip,r)
  if i<v.selected.size():
   var u:Dictionary=d.unit(v.selected[i]);v.sprite(m,u.id,Rect2(r.position+Vector2(20,1),Vector2(34,28)),0,1.0,int(u.star))
   text(m,'★'.repeat(int(u.star))+' +%d'%u.level,r.position+Vector2(37,38),8,true,68)
   select(m,r,str(i+1))
  else:text(m,'+ 선택',r.position+Vector2(37,31),12,true,68)
  text(m,'재료 %d'%(i+1),r.position+Vector2(37,49),7,true,68)
 text(m,'+',Vector2(135,y+63),16,true,20)
 text(m,'선택 %d / 2'%v.selected.size(),Vector2(135,y+96),9,true)
 y+=105
 text(m,'보유 병사',Vector2(22,y+9),10)
 y+=16
 var pitch:float=58
 var rows:int=maxi(1,int((bottom-y-59)/pitch))
 v.roster_viewport=Rect2(18,y,234,rows*pitch)
 v.roster_max_scroll=maxf(0,d.soldiers.size()*pitch-rows*pitch)
 v.roster_scroll=clampf(v.roster_scroll,0,v.roster_max_scroll)
 var first:int=floori(v.roster_scroll/pitch)
 for i in rows:
  if first+i>=d.soldiers.size():break
  var u:Dictionary=d.soldiers[first+i];var spec:Dictionary=d.catalog.soldiers[int(u.id)];var st:Dictionary=d.stats(u)
  var r:=Rect2(18,y+i*pitch,234,55)
  m._ui_style_box(m.sb_chip,r)
  v.sprite(m,u.id,Rect2(r.position+Vector2(6,13),Vector2(40,37)),0,1.0,int(u.star))
  text(m,spec.name,r.position+Vector2(52,15),10,false,172)
  text(m,'★'.repeat(int(u.star))+'  +%d'%u.level,r.position+Vector2(52,29),8,false,110)
  text(m,'체%d  공%d  방%d'%[st.hp,st.atk,st.def],r.position+Vector2(52,39),8,false,172)
  text(m,m._ui_wrap(spec.description,7,172,1),r.position+Vector2(52,49),7,false,172)
  if bool(u.locked):
   v.lock_icon(m,'lock_status:%d'%u.uid,Rect2(r.end.x-25,r.position.y+18,20,22),true)
  elif int(u.uid) in d.team:text(m,'출전',r.position+Vector2(199,28),7,true,40,Color('39715c'))
  elif int(u.level)<3:text(m,'+3 필요',r.position+Vector2(199,28),7,true,40,Color('946a48'))
  if int(u.uid) in v.selected:select(m,r,str(v.selected.find(int(u.uid))+1))
  v.rects['select:%d'%u.uid]=r
 if v.roster_max_scroll>0:
  var vh:float=v.roster_viewport.size.y
  m._ui_rect(Rect2(254,y,2,vh),Color('d3c39e'))
  var th:float=maxf(12,vh*vh/(d.soldiers.size()*pitch))
  m._ui_rect(Rect2(254,y+v.roster_scroll/v.roster_max_scroll*(vh-th),2,th),Color('9d7c4c'))
 var foot:float=v.roster_viewport.end.y
 text(m,'%d마리 · 위아래로 밀기'%d.soldiers.size(),Vector2(135,foot+11),8,true)
 var q:Dictionary=d.merge_cost(v.selected[0],v.selected[1]) if v.selected.size()==2 else {}
 var caption:String='합성 결과 · 소모 재료 확인' if v.selected.size()==2 else '병사 %d마리를 더 선택하세요'%(2-v.selected.size())
 v.button(m,'merge_review',Rect2(18,foot+18,234,26),caption,not q.is_empty() and not d.active())
 text(m,'잠금 병사는 보호됩니다',Vector2(135,foot+55),8,true)
