extends SceneTree
func _initialize():call_deferred("run")
func run():
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
	m.title_open=false;m.TUT.done=true;m.active_region=1;m.region_shop.unlocked=[0,1]
	m.gold=654321;m.souls=23;m.pearl=17
	m.bag=[{"sp":5,"star":0,"grade":2,"len":17.2,"w":0.08,"price":111}]
	m.DEX={m.fish_key(5):[2]};m.REC={m.fish_key(5):17.2};m.catch_counts={m.fish_key(5):[0,0,1,0,0]}
	m.personal_dex.observe(5,2,17.2,0.08,"2026-11-06")
	m.progression.restore({"certificates":[true,false],"main_completed":[true,false],"donations":{"1":[1,0,0,0,0,0]}})
	m._save_rec()
	assert(FileAccess.file_exists("user://rec.json"))
	assert(m._save_game())
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("LEGACY106_STAGE4_SAVE_CREATED");quit(0)
