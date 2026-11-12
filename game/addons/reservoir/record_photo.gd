extends RefCounted
# Read-only specimen presentation. Never writes records, inventory or game saves.
const STAGE=preload("res://art/record_photo/measuring_scene.png")
const CATALOG=preload("res://addons/reservoir/regional_catalog.gd")
const INK:=Color("382619")
const MUTED:=Color("68533d")
const EXPORT_SIZE:=Vector2i(1080,1380)
const EXPORT_LOGICAL:=Vector2i(270,345)
var motion=preload("res://addons/reservoir/record_photo_motion.gd").new()
var opened_at:=0
var preview_time:=-1.0
var opened:=false
var species:=-1
var kind:=""
var specimen:Dictionary={}
var rects:Dictionary={}
var status:=""
var busy:=false
var generation:=0
var gallery=preload("res://addons/reservoir/record_gallery.gd").new()
var geometry_cache:Dictionary={}
func open(m, sp: int, record_kind: String) -> bool:
 var f:Dictionary=m.personal_dex.best(m,sp,record_kind)
 if f.is_empty():return false
 generation+=1
 opened_at=Time.get_ticks_msec()
 species=sp;kind=record_kind;specimen=f.duplicate(true);opened=true;status="";rects={}
 m.personal_dex.cancel_pointer();m.holding=false
 return true
func close() -> void:
 opened=false;rects={};status=""
func nice_range(value: float) -> float:
 if not is_finite(value) or value<=0:return 0.0
 var exponent:=pow(10.0,floor(log(value)/log(10.0)))
 for step in [1.0,1.2,1.5,2.0,2.5,3.0,4.0,5.0,6.0,8.0,10.0]:
  if step*exponent>=value-0.000001:return step*exponent
 return 10.0*exponent
func valid_length(f: Dictionary) -> bool:
 return f.has("len") and is_finite(float(f.len)) and float(f.len)>0
func fish_source(m, sp: int) -> Dictionary:
 if geometry_cache.has(sp):return geometry_cache[sp]
 var rift:bool=m.rift_art.has_species(sp)
 var texture:Texture2D=m.rift_art.texture(sp) if rift else m.fish_tex[sp]
 var source:Rect2=m.rift_art.source_rect(sp,0) if rift else Rect2(m.fish_used[sp])
 var image:=texture.get_image()
 # Snout-to-tail measurement in the central body band, excluding long fin rays.
 var low:=floori(source.position.y+source.size.y*.25)
 var high:=ceili(source.position.y+source.size.y*.75)
 var x0:=source.end.x;var x1:=source.position.x
 for x in range(int(source.position.x),int(source.end.x)):
  for y in range(low,high):
   if image.get_pixel(x,y).a>.65:x0=minf(x0,x);x1=maxf(x1,x+1);break
 if x1<=x0:x0=source.position.x;x1=source.end.x
 var left:bool=rift or (sp>=40 and sp<60)
 var start:=x0-source.position.x if left else source.end.x-x1
 var result:Dictionary={"texture":texture,"source":source,"left":left,"body_start":start,"body_width":x1-x0}
 var glints:Array=[]
 for fraction in [.32,.48,.63]:
  var xx:=clampi(int(source.position.x+source.size.x*fraction),0,image.get_width()-1)
  for yy in range(int(source.position.y+source.size.y*.32),int(source.position.y+source.size.y*.56)):
   if image.get_pixel(xx,yy).a>.9:
    glints.append(Vector2(fraction if left else 1-fraction,(yy-source.position.y)/source.size.y));break
 result["glints"]=glints
 geometry_cache[sp]=result
 return result
func measure_regular(m, sp: int, f: Dictionary, stage: Rect2) -> Dictionary:
 var source:Dictionary=fish_source(m,sp)
 var src:Rect2=source.source
 var zero:=stage.position+stage.size*Vector2(.185,.593)
 var ruler_width:=stage.size.x*.655
 var max_height:=stage.size.y*.208
 var length:=float(f.get("len",0.0)) if valid_length(f) else 0.0
 var limit:=nice_range(length*1.16)
 var width:=ruler_width*.67
 if length>0:
  for i in 12:
   width=ruler_width*length/limit
   if width*src.size.y/float(source.body_width)<=max_height:break
   limit=nice_range(limit*1.16)
 else:width=minf(width,max_height*float(source.body_width)/src.size.y)
 var scale:=width/float(source.body_width)
 var size:=src.size*scale
 var p:=Vector2(zero.x-float(source.body_start)*scale,stage.position.y+stage.size.y*.463-size.y*.5)
 var fish_rect:=Rect2(p,size)
 return {"zero":zero,"width":ruler_width,"range":limit,"body_px":width,"tail_x":zero.x+width,"fish_rect":fish_rect,"source":source}
func giant_amount(f:Dictionary)->float:
 if not valid_length(f):return 0.0
 # Presentation-only continuous threshold; never changes catch size or balance.
 return smoothstep(60.0,240.0,float(f.len))
func measure(m,sp:int,f:Dictionary,stage:Rect2)->Dictionary:
 var g:=measure_regular(m,sp,f,stage)
 var amount:=giant_amount(f)
 g["giant"]=amount
 if amount<=0:return g
 var src:Rect2=g.source.source
 # Fit the complete source, including fins/tentacles, with room for the close intro.
 var safe:=stage.size*Vector2(.79,.55)
 var scale:=minf(safe.x/src.size.x,safe.y/src.size.y)
 var big_size:=src.size*scale
 var size:Vector2=g.fish_rect.size.lerp(big_size,amount)
 var center:Vector2=g.fish_rect.get_center().lerp(stage.position+stage.size*Vector2(.5,.52),amount)
 g.fish_rect=Rect2(center-size*.5,size)
 # Oversized specimens deliberately occlude the printed mat. No false end witness.
 g["tail_x"]=g.fish_rect.position.x+(float(g.source.body_start)+float(g.source.body_width))*size.x/src.size.x
 return g
func camera_zoom(f:Dictionary,t:float)->float:
 var amount:=giant_amount(f)
 var elapsed:=clampf(t,0,1) if t>=0 else 1.0
 return 1.0+.10*amount*(1.0-smoothstep(0.0,1.0,elapsed))
func camera_geometry(g:Dictionary,area:Rect2,zoom:float)->Dictionary:
 var out:=g.duplicate()
 var pivot:=area.position+area.size*Vector2(.5,.52)
 out.fish_rect=Rect2(pivot+(g.fish_rect.position-pivot)*zoom,g.fish_rect.size*zoom)
 out.zero=pivot+(g.zero-pivot)*zoom
 out.width=g.width*zoom;out.body_px=g.body_px*zoom
 out.tail_x=pivot.x+(g.tail_x-pivot.x)*zoom
 return out
func number(value: float) -> String:
 if is_equal_approx(value,roundf(value)):return str(int(roundf(value)))
 return ("%.2f"%value).rstrip("0").rstrip(".")
func ruler_numbers(m,g:Dictionary) -> Array:
 var font:Font=m.fonts[0]
 var px:=8
 var width:float=g.width
 var divisions:=6
 var longest:=0.0
 for i in 7:
  longest=maxf(longest,font.get_string_size(number(float(g.range)*i/6.0),HORIZONTAL_ALIGNMENT_LEFT,-1,px).x)
 if width/divisions<longest+8:divisions=3
 var result:Array=[]
 for i in divisions+1:
  var text:=number(float(g.range)*i/divisions)
  var center:Vector2=g.zero+Vector2(width*i/divisions,10)
  var size:=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,px)
  if i==0:center.x+=size.x*.5+1
  elif i==divisions:center.x-=size.x*.5+1
  var baseline:=center.round()
  var bounds:=Rect2(Vector2(baseline.x-size.x*.5,baseline.y-font.get_ascent(px)),Vector2(size.x,font.get_ascent(px)+font.get_descent(px)))
  result.append({"text":text,"baseline":baseline,"bounds":bounds,"font":font,"px":px,"divisions":divisions})
 return result
func ruler_text(m,label:Dictionary) -> void:
 # Exact numeric font size and baseline: bypass the common UI's 10px minimum.
 var width:float=maxf(24,label.bounds.size.x+2)
 m.text_items.append([label.font,label.baseline-Vector2(width*.5,0),label.text,HORIZONTAL_ALIGNMENT_CENTER,width,label.px,INK,1.0])
func ruler(m, g: Dictionary, moving:bool=false) -> void:
 if float(g.range)<=0:
  m._text("길이 미기록",g.zero+Vector2(float(g.width)*.5,3),8,MUTED,true,float(g.width));return
 var origin:Vector2=g.zero
 var width:float=g.width
 var labels:=ruler_numbers(m,g)
 var step:=30/int(labels[0].divisions)
 # Separate printed rows: ticks above the rule, small numbers on a clear strip below.
 m._ui_rect(Rect2(origin+Vector2(0,1),Vector2(width,12)),Color(.96,.89,.73,.94))
 m._ui_line(origin,origin+Vector2(width,0),Color("9d8054"),1)
 for tick in 31:
  var x:=origin.x+width*tick/30.0
  var major:=tick%step==0
  var hh:=5.0 if major else (3.0 if tick%5==2 else 2.0)
  m._ui_rect(Rect2(Vector2(x,origin.y-hh).round(),Vector2(1,hh)),INK)
 for label in labels:ruler_text(m,label)
 var unit_font:Font=m.fonts[0]
 var unit_pos:Vector2=(origin+Vector2(width-7,-9)).round()
 m.text_items.append([unit_font,unit_pos,"cm",HORIZONTAL_ALIGNMENT_LEFT,20,8,MUTED,1.0])
 if float(g.get("giant",0))<=0:m._ui_rect(Rect2(Vector2(origin.x-1,g.fish_rect.position.y).round(),Vector2(1,g.fish_rect.size.y)),Color(.22,.36,.33,.38))
 if not moving and float(g.get("giant",0))<=0:m._ui_line(Vector2(g.tail_x,origin.y-9),Vector2(g.tail_x,origin.y-1),Color("b56c36"),1)
func quad(m, texture: Texture2D, src: Rect2, r: Rect2, left: bool, color: Color) -> void:
 var ts:=texture.get_size()
 var uv:=PackedVector2Array([src.position/ts,Vector2(src.end.x,src.position.y)/ts,src.end/ts,Vector2(src.position.x,src.end.y)/ts])
 if not left:uv=PackedVector2Array([uv[1],uv[0],uv[3],uv[2]])
 m._ui_polygon(PackedVector2Array([r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)]),PackedColorArray([color,color,color,color]),uv,texture)
func animation_time()->float:
 if busy:return -1.0
 return preview_time if preview_time>=0 else (Time.get_ticks_msec()-opened_at)/1000.0
func draw_scene(m, area: Rect2, animated:bool=false) -> Dictionary:
 var t:=animation_time() if animated else -1.0
 var zoom:=camera_zoom(specimen,t)
 # A bounded source crop provides a true camera pullback without invented outpaint.
 var src_size:=STAGE.get_size()/zoom
 var src_origin:=STAGE.get_size()*Vector2(.5,.52)-src_size*Vector2(.5,.52)
 m._ui_texture_rect_region(STAGE,area,Rect2(src_origin,src_size))
 var g:=camera_geometry(measure(m,species,specimen,area),area,zoom)
 # The mat and tackle share camera projection, retaining their comparison scale.
 motion.environment(m,area,t)
 var old_text_count:int=m.text_items.size()
 ruler(m,g,motion.strength(species,t)>.03)
 var ruler_texts:Array=m.text_items.slice(old_text_count)
 m.text_items.resize(old_text_count)
 if float(g.giant)>0:
  # text_layer paints text after geometry; convert printed glyphs to commands now
  # so the foreground fish can genuinely cover numbers as well as tick marks.
  for label in ruler_texts:
   m.ui_commands.append(["inline_text",label])
 else:m.text_items.append_array(ruler_texts)
 motion.moisture(m,species,g,t)
 motion.mesh(m,species,g,t,true)
 motion.mesh(m,species,g,t)
 motion.highlights(m,species,g,t)
 return g
func text_values(m) -> Dictionary:
 return {"name":m.FISH_NAME[species],"grade":m.GRADE_N[int(specimen.grade)] if specimen.has("grade") else "등급 미기록","length":"%.1fcm"%float(specimen.len) if valid_length(specimen) else "길이 미기록","weight":m._wtxt(float(specimen.w)) if specimen.has("w") and float(specimen.w)>0 else "무게 미기록","date":str(specimen.get("date","")) if not str(specimen.get("date","")).is_empty() else "날짜 미기록","region":m.personal_dex.REGIONS[CATALOG.region(species)]}
func caption(m, area: Rect2, exported: bool=false) -> void:
 var values:=text_values(m)
 m._ui_style_box(m.sb_chip,area)
 var cx:=area.get_center().x
 m._text(values.name,Vector2(cx,area.position.y+18),13,INK,true,area.size.x-16)
 var grade:int=int(specimen.get("grade",0))
 m._text(values.grade+"  ·  "+values.length+" · "+values.weight,Vector2(cx,area.position.y+35),10,m.GRADE_C[grade] if grade>0 else Color("246da4"),true,area.size.x-16)
 m._text(values.region+" · "+values.date,Vector2(cx,area.position.y+50),8,MUTED,true,area.size.x-16)
 if exported:m._text("낚시월드",Vector2(area.end.x-32,area.end.y-9),8,Color("08646b"),true,56)
func layout(h: float) -> Dictionary:
 var height:=minf(412,h-24)
 var panel:=Rect2(8,floorf((h-height)/2),254,height)
 var image_size:=240.0
 return {"panel":panel,"scene":Rect2(panel.position+Vector2(7,7),Vector2(image_size,image_size)),"caption":Rect2(panel.position+Vector2(8,253),Vector2(238,62)),"save":Rect2(panel.position+Vector2(12,326),Vector2(156,32)),"close":Rect2(panel.position+Vector2(175,326),Vector2(67,32))}
func draw(m,h: float) -> void:
 var boxes:=layout(h)
 m._ui_rect(Rect2(-m.ox,0,270+2*m.ox,h),Color(.025,.06,.08,.92))
 m._ui_style_box(m.sb_panel,boxes.panel)
 draw_scene(m,boxes.scene,true)
 preload("res://addons/reservoir/ui_theme.gd").title(m,boxes.panel,"나의 최고 기록")
 var close_box:=Rect2(boxes.panel.end.x-31,boxes.panel.position.y+9,22,23)
 preload("res://addons/reservoir/close_control.gd").draw(m,close_box)
 caption(m,boxes.caption)
 # Use the complete existing carved/raised pixel button; never overpaint its face.
 m._ui_style_box(m.sb_primary,boxes.save)
 var label:="저장 중…" if busy else "갤러리 저장"
 m._text(label,boxes.save.get_center()+Vector2(6,4),11,Color("fff0d1"),true,boxes.save.size.x-25,true)
 var camera:Vector2=boxes.save.position+Vector2(12,10)
 m._ui_rect(Rect2(camera,Vector2(14,10)),Color("fff0d1"),false,1)
 m._ui_rect(Rect2(camera+Vector2(3,-2),Vector2(5,2)),Color("fff0d1"))
 m._ui_circle(camera+Vector2(7,5),3,Color("fff0d1"),false,1)
 m._ui_style_box(m.sb_btn,boxes.close);m._text("닫기",boxes.close.get_center()+Vector2(0,4),11,INK,true,55)
 var note:=status if not status.is_empty() else ("대물 · 실측 길이는 아래 기록에 표시돼요" if giant_amount(specimen)>0 else ("움직이는 중 · 사진은 안정 자세로 저장" if motion.strength(species,animation_time())>.03 else "버튼 없이 기록 사진만 저장돼요"))
 m._text(note,Vector2(135,boxes.panel.position.y+380),8,MUTED,true,228)
 rects={"save":boxes.save,"close":boxes.close,"x":close_box}
func press(m,p: Vector2) -> void:
 if rects.get("close",Rect2()).has_point(p) or rects.get("x",Rect2()).has_point(p):close();return
 if rects.get("save",Rect2()).has_point(p) and not busy:save_photo(m)
func create_image(m) -> Image:
 var old_commands:Array=m.ui_commands
 var old_text:Array=m.text_items
 m.ui_commands=[];m.text_items=[]
 draw_scene(m,Rect2(0,0,270,270))
 caption(m,Rect2(0,270,270,75),true)
 var commands:Array=m.ui_commands;var texts:Array=m.text_items
 m.ui_commands=old_commands;m.text_items=old_text
 var viewport:=SubViewport.new();viewport.size=EXPORT_SIZE
 viewport.size_2d_override=EXPORT_LOGICAL;viewport.size_2d_override_stretch=true
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 viewport.canvas_item_default_texture_filter=Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
 var painter:Node2D=load("res://text_layer.gd").new()
 painter.items=texts;painter.commands=commands;viewport.add_child(painter)
 m.get_tree().root.add_child(viewport)
 await m.get_tree().process_frame
 await RenderingServer.frame_post_draw
 var image:=viewport.get_texture().get_image()
 viewport.queue_free()
 return image
func save_photo(m) -> void:
 if busy:return
 busy=true;status="사진을 만들고 있어요";m.queue_redraw()
 var started_generation:=generation
 var filename:="NakshiWorld_%s_%s_%s.png"%[CATALOG.key(species),kind,str(Time.get_unix_time_from_system()).replace(".","_")]
 var image:Image=await create_image(m)
 complete_image(m,image,filename,started_generation)
func complete_image(m,image:Image,filename:String,started_generation:int)->void:
 # Native JNI errors can abort a GDScript call. Clear waiting state before the
 # synchronous native boundary; no event can interleave while save() runs.
 busy=false
 if generation!=started_generation:return
 status="저장 결과를 확인하지 못했어요. 다시 시도해 주세요"
 m.queue_redraw()
 var result=gallery.save(image,filename)
 if generation==started_generation and result is Dictionary:
  status=str(result.get("message","저장 결과를 확인하지 못했어요"))
 m.queue_redraw()
