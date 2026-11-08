extends SceneTree
func _initialize():call_deferred('run')
func run():
 var m=load('res://main.gd').new();m.SET.sfx=0;m.SET.music=0;root.add_child(m);await process_frame;m.set_process(false);m.title_open=false;m.lesson_open=false
 var failures:Array=[];var count:=0
 for trial in 100:
  var cases:Array=load('res://tests/critical_transaction_cases.gd').new().run_with(m)
  for result in cases:
   count+=1
   if not result.memory_unchanged or not result.disk_unchanged:failures.append({'trial':trial,'case':result})
  if not failures.is_empty():break
 var out={'trials':count,'scenario_count':11,'repetitions':100,'actual_failed_file_writes':true,'failures':failures,'isolated_user_data':true}
 var f=FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE);f.store_string(JSON.stringify(out,'  '));f.close();print('TRANSACTION_STRESS ',JSON.stringify(out));m.audio_feedback.dispose();m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
