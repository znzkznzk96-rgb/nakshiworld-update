extends RefCounted
# Selected B art is immutable. Every value inside the receiver display is live UI.
const ART="res://art/ui/update_receiver.png.b64.txt"
const SIZE=Vector2(841,1870)
var image: Texture2D
var canvas: CanvasLayer
var motion: Node2D
var observed_progress := -1.0
var spark_until := -1.0

func attach(m) -> void:
	load_art()
	canvas = CanvasLayer.new()
	canvas.name = "UpdateBackground"
	canvas.layer = -1
	m.add_child(canvas)
	motion = preload("res://addons/reservoir/update_motion.gd").new()
	canvas.add_child(motion)
	motion.setup(image)

func advance(dt: float) -> void:
	if is_instance_valid(motion):
		motion.advance(dt)

func dismiss() -> void:
	if is_instance_valid(canvas):
		canvas.queue_free()

func load_art() -> void:
	if image!=null:return
	var data:=Image.new()
	if data.load_png_from_buffer(Marshalls.base64_to_raw(FileAccess.get_file_as_string(ART)))==OK:image=ImageTexture.create_from_image(data)
func caption(m,value: String,y: float,size: int,color: Color) -> void:
	m.draw_string(m.font,Vector2(164,y),value,HORIZONTAL_ALIGNMENT_CENTER,522,size,color)
func draw(m) -> void:
	load_art()
	var view: Vector2=m.get_viewport_rect().size
	var scale: float=maxf(view.x/SIZE.x,view.y/SIZE.y)
	m.draw_set_transform((view-SIZE*scale)*.5,0,Vector2.ONE*scale)
	# Cover all painted progress/status values; panel frame and illustration remain intact.
	m.draw_rect(Rect2(164,906,522,338),Color("071823"))
	m.draw_rect(Rect2(173,914,504,320),Color("0a1d29"),false,2)
	var phase: String=m.update_phase
	var checking: bool=phase=="check"
	var known: bool=not checking and m.expected_size>0
	var p: float=clampf(m.progress,0,1) if known else -1
	var color:=Color("4be2d1")
	caption(m,"업데이트 확인 중" if checking else ("파일 확인 중" if phase=="verify" else ("업데이트 적용 중" if phase=="apply" else "업데이트 다운로드 중")),951,30,Color("f8e8c7"))
	caption(m,"연결 중" if checking else ("%d%%"%int(p*100) if p>=0 else "받는 중"),1038,60,Color("fff0ca"))
	var clock: float = 0.0
	if is_instance_valid(motion):
		clock = motion.time_override if motion.time_override >= 0.0 else motion.elapsed
	if p > observed_progress + 0.00001 and observed_progress >= 0.0:
		spark_until = clock + 0.32
	observed_progress = p
	var filled: int=int(floor(p*25)) if p>=0 else -1
	for i in 25:
		var on: bool=i<filled if p>=0 else i==int(fmod(Time.get_ticks_msec()/150.0,25))
		var r:=Rect2(191+i*18.5,1080,14,30)
		m.draw_rect(r,Color("193343"));m.draw_rect(r,Color("31586a"),false,1)
		var fraction: float = clampf(p*25.0-i,0.0,1.0) if p>=0 else (1.0 if on else 0.0)
		if fraction > 0:
			m.draw_rect(Rect2(r.position+Vector2.ONE,Vector2(12*fraction,28)),color)
			m.draw_rect(Rect2(r.position+Vector2.ONE,Vector2(12*fraction,3)),Color("c4fff1"))
	# Sparks follow real byte progress; disappear on stalls, checks and completion.
	if phase == "download" and p > 0.0 and p < 1.0 and clock < spark_until:
		var edge: float = 191 + floor(p*25.0)*18.5 + fmod(p*25.0,1.0)*14.0
		var fade: float = clampf((spark_until-clock)/0.16,0,1)
		for i in 12:
			var age: float = fposmod(clock*2.8+i*0.083,1.0)
			var v := Vector2(12.0+float(i%4)*8.0,-28.0-float(i%5)*8.0)
			var point := Vector2(edge,1092)+v*age+Vector2(0,32)*age*age
			var c := Color("e9fff1") if i%3==0 else Color("6ffff0")
			c.a=(1.0-age)*fade
			m.draw_rect(Rect2(point.round(),Vector2(3,3) if i%3==0 else Vector2(2,2)),c)
		m.draw_line(Vector2(edge,1077),Vector2(edge,1112),Color(0.85,1,0.93,fade),2)
	var bytes: String="서버 연결 확인 중" if checking else ("%.1f / %.1f MB"%[minf(m.downloaded_bytes,m.expected_size)/1000000.0,m.expected_size/1000000.0] if known else "다운로드 준비 중")
	m.draw_string(m.font,Vector2(191,1144),bytes,HORIZONTAL_ALIGNMENT_LEFT,340,24,Color("f8e8c7"))
	if m.update_version!="":m.draw_string(m.font,Vector2(507,1144),"새 버전 "+m.update_version,HORIZONTAL_ALIGNMENT_RIGHT,145,22,Color("f8e8c7"))
	m.draw_line(Vector2(191,1171),Vector2(653,1171),Color("365162"),2)
	var stage: int=0 if phase in ["check","download"] else (1 if phase=="verify" else 2)
	for i in 3:
		var c: Color=color if i<=stage and not checking else Color("60788a")
		m.draw_circle(Vector2(225+i*155,1206),6,c)
		m.draw_string(m.font,Vector2(242+i*155,1213),["다운로드","확인","적용"][i],HORIZONTAL_ALIGNMENT_LEFT,115,23,c)
	m.draw_set_transform(Vector2.ZERO)
