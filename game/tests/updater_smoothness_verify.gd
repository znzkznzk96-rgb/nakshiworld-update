extends SceneTree
class Probe extends "res://root.gd":
 func _ready()->void:pass
 func _start()->void:started=true
var failures:Array=[]
func check(ok:bool,label:String):
 if not ok:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 var m=Probe.new();root.add_child(m)
 var p:="user://smooth-hash.bin";var data:=PackedByteArray();data.resize(64*1024*1024);data.fill(71)
 var f:=FileAccess.open(p,FileAccess.WRITE);f.store_buffer(data);f=null
 var before:float=m.animation_time;var frames:int=Engine.get_process_frames()
 var digest:String=await preload("res://incremental_update.gd").digest_file(m,p)
 check(digest==FileAccess.get_sha256(p),"chunked SHA equals canonical SHA")
 check(Engine.get_process_frames()-frames>=15,"64MiB hash spans at least15 completed frames with4MiB maximum batches")
 check(m.animation_time>before,"animation advances during verification")
 check(await preload("res://incremental_update.gd").digest_file(m,"user://absent.bin")=="","unreadable candidate rejected")
 for phase in ["ready","verifying","loading"]:
  m.update_phase=phase;m.progress=.98;m.received_bytes=980;m.total_bytes=1000
  check(not "%" in m.transfer_detail(),"no frozen percentage during "+phase)
 m.update_phase="download";m.expected_size=1000;m.progress=.98
 check("98%" in m.transfer_detail(),"download still shows real98percent")
 var helper=load("res://incremental_update.gd").new();helper.work_tick=Time.get_ticks_usec()-4000
 before=m.animation_time;await helper.cooperate(m)
 check(helper.yielded_frames==1 and m.animation_time>before,"reconstruction budget yields frame")
 print("UPDATER_SMOOTHNESS_VERIFY failures=",failures)
 m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
