extends SceneTree
var failures: Array=[]
func check(value: bool,label: String) -> void:
	if not value: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m=load("res://main.gd").new();root.add_child(m);await process_frame;m.set_process(false)
	m.audio_feedback.stop_all();m.title_open=false;m.SET.sfx=0;m.SET.music=0;m.SET.vib=false
	var store=load("res://addons/reservoir/save_store.gd")
	check(store.write("user://transaction_test.json",{"gold":50}),"first atomic save")
	check(store.write("user://transaction_test.json",{"gold":25}),"second atomic save")
	check(store.read("user://transaction_test.json").gold==25,"latest committed save wins")
	DirAccess.remove_absolute("user://transaction_test.json")
	check(store.read("user://transaction_test.json").gold==50,"missing primary recovers backup")
	check(not store.write("user://absent_directory/save.json",{}),"write failure detected")
	m.gold=10000;m.souls=10000;m.rod_lv=0;m.rod_enh[0]=0;m.equipment.rod_equipped=true
	check(m.V.enhancement.start(m,1.0),"forced failed enhancement starts")
	var paid: int=m.gold;var level: int=m.forge_lv
	m.gold=0;m.forge_pending={};m._load_game()
	check(m.gold==paid and m.forge_lv==level and not m.forge_pending.success,"failure/cost persisted before animation")
	var saved: Dictionary=store.read("user://save.json")
	saved.aqua=[{"price":300.0},null,null];saved.time=Time.get_unix_time_from_system()-3600
	store.write("user://save.json",saved);m._load_game();var settled: int=m.gold;m._load_game()
	check(m.gold==settled,"offline reward cannot repeat on reload")
	m.settings_open=true;m.set_view="main";m.reset_confirm=false;m._draw_settings()
	m._settings_press(m.set_rects.reset.get_center());check(m.reset_confirm,"reset requires confirmation")
	m._draw_settings();m._settings_press(m.set_rects.no.get_center());check(not m.reset_confirm and m.gold==settled,"no preserves progress")
	m.SET.sfx=1.0
	for key in m.audio_feedback.PATTERNS:
		m.audio_feedback.action(m,key);await create_timer(0.06).timeout;m.audio_feedback.stop_all();await process_frame
	check(m.audio_feedback.streams.size()==16,"all sound resources imported")
	check(m.audio_feedback.music.stream.loop and m.audio_feedback.rain.stream.loop,"title seamless loops enabled")
	m.audio_feedback.suspended=true;m.audio_feedback.sound(m,"thunder");check(m.audio_feedback.pool.all(func(p):return not p.playing),"background audio blocked")
	m.audio_feedback.suspended=false;m.SET.sfx=0
	# Test deletion allowlist in isolated XDG_DATA_HOME, never user's files.
	for name in ["settings.json","patch_ver.txt","reset.pending","rec.json","tut.json"]:
		var f=FileAccess.open("user://"+name,FileAccess.WRITE);f.store_string("sentinel");f.close()
	m._cleanup_reset()
	check(not FileAccess.file_exists("user://save.json") and not FileAccess.file_exists("user://save.json.bak"),"reset removes progress and backups")
	check(FileAccess.file_exists("user://settings.json") and FileAccess.file_exists("user://patch_ver.txt"),"reset preserves settings and updater")
	DirAccess.remove_absolute("user://settings.json")
	m.audio_feedback.dispose();await create_timer(0.15).timeout;m.S={"phase":"idle"};m.scene="village";m.queue_free();await process_frame
	print("AUDIO_SAVE_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
