extends SceneTree
func _initialize():call_deferred("run")
func run():
 var m=load("res://main.gd").new();m.development_preview=true;m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false)
 m.title_open=false;m.title_screen.leaving=false;m.trans={};m.TUT.done=true;m.lesson_open=false;m.scene="fish";m.guide.opened=false
 m.pond_stock=0.0;m.S={"phase":"cast","t":0.0};
 for i in 30:m._process(.05)
 print("POND_PROBE ",JSON.stringify({"stock_at_wait":m.pond_stock,"phase":m.S.phase,"empty_branch":m.pond_stock<=0.0,"wait_seconds":m.S.biteAt-m.clock,"bare":m.S.bare}))
 m.audio_feedback.dispose();m.queue_free();await process_frame;quit()
