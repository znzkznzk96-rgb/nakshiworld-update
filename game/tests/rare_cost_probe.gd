extends SceneTree
class Probe:
	extends "res://main.gd"
	var skip_halo := false
	func _ready() -> void: pass
	func _draw_action_wake(_c: Vector2, _length: float, _hw: float, _face: float, _beh: String, _t: float) -> void: pass
	func _draw_pixel_halo(quads: Array, tex: Texture2D, grade: int, t: float) -> void:
		if not skip_halo: super._draw_pixel_halo(quads,tex,grade,t)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m:=Probe.new()
	var image:=Image.create(64,32,false,Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var tex:=ImageTexture.create_from_image(image)
	m.fish_tex=[tex];m.fish_sil=[tex];m.fish_used=[Rect2i(0,0,64,32)]
	m.S={"phase":"fight","judge":"GREAT"};m.visibility_flash=0.0;m.ui_demo=false
	var rows:=[]
	for grade in 5:
		for skip in [false,true]:
			m.skip_halo=skip
			var times:=[]
			var count:=0
			for i in 110:
				m.ui_commands.clear()
				var start:=Time.get_ticks_usec()
				m._shadow_fish(Vector2(135,300),2,grade,1000.0+i*16.666,"swim",false,1.0,{},1.2,0,1.0,1.0)
				var elapsed:=Time.get_ticks_usec()-start
				if i>=10: times.append(elapsed)
				count=m.ui_commands.size()
			times.sort()
			rows.append({"grade":grade,"halo_omitted_for_diagnosis":skip,"median_us":times[50],"p95_us":times[95],"ui_commands":count})
	var font: FontFile = load("res://font/neodgm.ttf")
	font.antialiasing=TextServer.FONT_ANTIALIASING_NONE
	font.hinting=TextServer.HINTING_NONE
	font.subpixel_positioning=TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.oversampling=1.0
	font.fallbacks=[load("res://font/galmuri11.fnt")]
	m.fonts=[font,font,font,font]
	var encounter=load("res://addons/reservoir/encounter_text.gd").new()
	var text_rows:=[]
	for grade in range(1,5):
		var times:=[]
		var first:=0
		var descriptor: Dictionary=encounter.descriptor(grade)
		for i in 101:
			m.text_items.clear()
			var start:=Time.get_ticks_usec()
			encounter.title(m,descriptor,0.5,200.0)
			var elapsed:=Time.get_ticks_usec()-start
			if i==0: first=elapsed
			else: times.append(elapsed)
		times.sort()
		text_rows.append({"grade":grade,"first_us":first,"median_us":times[50],"text_items":m.text_items.size()})
	var file:=FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE)
	file.store_string(JSON.stringify({"scope":"CPU command construction only; synthetic texture, not Android FPS; production code unchanged","samples_per_case":100,"results":rows,"encounter_title":text_rows},"  "))
	m.free()
	print("RARE_COST_PROBE_PASS")
	quit()
