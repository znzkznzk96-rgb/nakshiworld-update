extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok:failures.append(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;m.title_open=false;m.development_preview=true;root.add_child(m);await process_frame;m.set_process(false)
	var e=m.environment
	check(e.layers.has("lamp_light") and e.layers.has("chimney_smoke"),"lamp and chimney are distinct layers")
	e.set_hour(22);check(e.actor_tint().get_luminance()>e.scenery_tint().get_luminance()*2,"lantern makes actor readable at night")
	e.set_hour(12);check(e.actor_tint().is_equal_approx(Color.WHITE),"daytime actor is unchanged")
	for t in [0.0,1.3,60.0,1200.0]:
		for c in 3:
			for i in 7:
				var p: Dictionary=e.layers.chimney_smoke.smoke_puff(c,i,t)
				check(p.p.y>=570 and p.p.y<=650 and p.radius<=9 and p.alpha>=0,"bounded chimney motion")
		for i in 18:
			var p: Vector2=e.layers.fireflies.firefly_position(i,t)
			check(p.y>=730 and p.y<=920 and p.x>150 and p.x<790,"fireflies above surface")
	seed(812);var expected: float=randf();seed(812)
	e.update(1);e.layers.fireflies.firefly_position(2,42);e.layers.chimney_smoke.smoke_puff(0,1,42)
	check(randf()==expected,"effects preserve fishing RNG")
	var enc=m.encounter
	for g in 6:
		var d: Dictionary=enc.descriptor(g,g==5)
		check(d.level==g and d.sparkle==g,"encounter tier ordering")
		if g>0:
			m.text_items=[];m.ui_commands=[];enc.title(m,d,.45,160)
			check(m.ui_commands.is_empty() and not m.text_items.is_empty(),"encounter uses glyphs without panel")
		var motion: Dictionary=enc.motion(0,0,g,1.8)
		check(is_zero_approx(motion.alpha),"encounter enters from transparent")
		motion=enc.motion(1.8,0,g,1.8);check(is_zero_approx(motion.alpha),"encounter leaves fully transparent")
	m.text_items=[];m.ui_commands=[];m.S={"phase":"pre","t":.6,"owner":true}
	m.owner_ui.warning(m,0,"청룡잉어",Color.WHITE)
	check(m.ui_commands.is_empty() and enc.debug.title=="경고 · 주인 등장","owner warning has no box")
	for i in 241:
		var age: float=i/100.0
		var geometry: Dictionary=m.angler_scene.landing_pose(age,2.4,Vector2(110,190),300)
		var tail: Vector2=geometry.mouth-Vector2.from_angle(geometry.angle)*40
		check(geometry.mouth.is_finite() and tail.y>geometry.mouth.y+38,"head stays above dangling tail")
		check(absf(geometry.angle+PI*.5)<=.30,"pendulum sway stays restrained")
	m.audio_feedback.dispose();print("ATMOSPHERE_ENCOUNTER_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
