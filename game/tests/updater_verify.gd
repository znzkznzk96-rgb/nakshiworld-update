extends SceneTree
class Probe extends "res://root.gd":
 func _ready()->void:pass
 func _start()->void:started=true
var failures:Array=[]
func check(ok:bool,label:String)->void:
 if not ok:failures.append(label);push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var m=Probe.new();root.add_child(m);m.set_process(false)
 for size in [1000000,59319104,80000000]:
  var d:Dictionary=m.transfer_snapshot(size/2,size,7)
  check(is_equal_approx(d.progress,.5) and d.total==size,"manifest size controls progress not response metadata")
  m.update_phase="download";m.expected_size=size;m.received_bytes=size/2;m.progress=d.progress
  check(m.transfer_detail().contains("%.1f MB"%(size/1000000.0)),"actual decimal MB for each file size")
 check(m.transfer_snapshot(500,-1,-1).progress<0,"unknown total never fabricates percent")
 check(m.transfer_snapshot(200,100).progress==1,"progress caps at100")
 m.update_phase="checking";m.progress=1;check(not m.transfer_detail().contains("%"),"manifest request cannot show download completion")
 var points:Array[Vector2]=m.chase_positions(0,Vector2.ZERO);var later:Array[Vector2]=m.chase_positions(1,Vector2.ZERO);var cycle:Array[Vector2]=m.chase_positions(TAU/1.55,Vector2.ZERO)
 check(points!=later and points[0].distance_to(cycle[0])<.001,"cat follows closed orbit")
 check(points[0].distance_to(points[1])>20,"fish leads cat without overlap")
 var original:=PackedByteArray([71,68,80,67,1]);var f:=FileAccess.open(m.PATCH,FileAccess.WRITE);f.store_buffer(original);f=null
 var bad:=PackedByteArray([0,1,2,3,4]);f=FileAccess.open(m.PATCH+".new",FileAccess.WRITE);f.store_buffer(bad);f=null;m.expected_size=bad.size();m.expected_hash=FileAccess.get_sha256(m.PATCH+".new");m._on_patch(0,200,PackedStringArray(),PackedByteArray(),116,"1.16")
 check(FileAccess.get_file_as_bytes(m.PATCH)==original and not FileAccess.file_exists(m.PATCH+".new"),"invalid header preserves installed patch")
 f=FileAccess.open(m.PATCH+".new",FileAccess.WRITE);f.store_buffer(original);f=null;m.expected_size=original.size();m.expected_hash="0".repeat(64);m._on_patch(0,200,PackedStringArray(),PackedByteArray(),116,"1.16")
 check(FileAccess.get_file_as_bytes(m.PATCH)==original,"hash failure preserves installed patch")
 f=FileAccess.open(m.PATCH+".new",FileAccess.WRITE);f.store_buffer(original);f=null;m.expected_hash=FileAccess.get_sha256(m.PATCH+".new");m._on_patch(0,200,PackedStringArray(),PackedByteArray(),116,"1.16")
 check(FileAccess.get_file_as_string(m.PATCH_VER)=="116|1.16","valid patch records actual installed version")
 print("UPDATER_VERIFY failures=",failures);m.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
