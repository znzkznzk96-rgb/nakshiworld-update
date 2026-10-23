extends SceneTree
var failures: Array = []
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label);push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var m=load("res://main.gd").new();m.SET.sfx=0;m.SET.music=0;root.add_child(m)
	await process_frame
	m.set_process(false);m.development_preview=true;m.title_open=false;m.TUT.done=true
	for record in [false,true]:
		m.bait=10;m.start_wait();m.S.sp=1;m.S.star=0;m.S.grade=1;m.S.len=25.0;m.S.lf=1.0
		m.REC[m.fish_key(1)]=0.0 if record else 30.0
		m.start_catch()
		var count_before: Array=m.fish_counts(1).duplicate()
		check(m.S.newRec==record,"record fixture")
		check(is_equal_approx(m.S.netEnd,2.68),"landing duration unchanged")
		check(is_equal_approx(m.S.catchEnd-m.S.netEnd,4.7 if record else 1.9),"result timing")
		m.S.t=m.S.netEnd+0.5;m.text_items=[];m.ui_commands=[];m._draw_catch(0)
		check(m.text_items.any(func(it):return str(it[2]).begins_with("12.5cm")),"half sweep at 0.5s")
		m.S.t=m.S.netEnd+1.0;m.text_items=[];m.ui_commands=[];m._draw_catch(0)
		check(m.text_items.any(func(it):return str(it[2]).begins_with("25.0cm")),"full sweep at 1s")
		if record:
			m.S.t=m.S.netEnd+1.11;m.update_catch(0)
			check(m.S.recFx,"new record sound after sweep")
			m.S.t=m.S.netEnd+2.51;m.update_catch(0)
			check(m.anim_name=="trophy","record celebration retained")
		m.S.t=m.S.catchEnd-.01;m.update_catch(0)
		check(m.S.phase=="catch","does not finish early")
		m.update_catch(.02)
		check(m.S.phase=="result" and m.S.ok,"finishes successfully")
		check(m.fish_counts(1)==count_before,"timing does not duplicate catch records")
	m.audio_feedback.dispose();m.queue_free();await process_frame
	print("MEASUREMENT_SPEED_VERIFY failures=",failures);quit(0 if failures.is_empty() else 1)
