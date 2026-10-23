extends SceneTree
var failures: Array=[]
func check(ok: bool,label: String) -> void:
	if not ok: failures.append(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;m.title_open=false;root.add_child(m)
	await process_frame;m.set_process(false)
	var af=m.audio_feedback
	m.scene="fishing";af.update_village(m,0)
	m.scene="village";m.title_open=false;m.title_screen.leaving=false;m.lesson_open=false;m.SET.sfx=1
	af.update_village(m,0)
	check(af.horn_timer==4 and af.gull_timer==7,"entry deadlines")
	af.update_village(m,3.9);check(not af.village_horn.playing and not af.village_fx.playing,"not early")
	af.update_village(m,0.11);check(af.village_horn.playing,"horn at four seconds")
	check(not af.village_fx.playing,"gull waits")
	af.update_village(m,3.0);check(af.village_fx.playing and af.village_horn.playing,"gull at seven seconds while horn active")
	check(af.horn_timer>=36 and af.gull_timer>=12,"repeat intervals retained")
	m.scene="fishing";af.update_village(m,0);check(not af.village_fx.playing and not af.village_horn.playing,"exit stops both")
	m.scene="village";af.update_village(m,0);check(af.horn_timer==4 and af.gull_timer==7,"reentry resets deadlines")
	m.SET.sfx=0;af.update_village(m,8);check(not af.village_fx.playing and not af.village_horn.playing,"mute respected")
	# Release players before waiting for the audio thread to retire playback resources.
	m.SET.sfx=0;m.SET.music=0;af.dispose();m.free();m=null;af=null
	await process_frame;await process_frame;await create_timer(0.35).timeout
	print("VILLAGE_ENTRY_AUDIO_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
