extends SceneTree
class Probe extends "res://root.gd":
 func _ready()->void:pass
 func _start()->void:started=true
var failures:Array=[]
func check(ok:bool,label:String)->void:
 if not ok:failures.append(label);push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var patch:String=OS.get_cmdline_user_args()[0];var helper=load("res://incremental_update.gd").new()
 var f:=FileAccess.open(patch,FileAccess.READ);var h:=f.get_buffer(100);f.seek(0);var base:int=h.decode_u64(24);var bytes:=f.get_buffer(base)
 var list:Array=helper.parse_index(bytes,f.get_length());check(list.size()>1000,"read actual exported PCK directory")
 check(helper.parse_index(bytes.slice(0,99),f.get_length()).is_empty(),"reject truncated")
 var invalid:=bytes.duplicate();invalid.encode_u64(24,999999999);check(helper.parse_index(invalid,f.get_length()).is_empty(),"reject invalid offsets")
 var m=Probe.new();m.preview_only=true;root.add_child(m);await process_frame;m.set_process(false)
 for i in 240:
  var pts:Array[Vector2]=m.chase_positions(i*.04,Vector2(135,300))
  check(pts[0].x-40>=40 and pts[0].x+40<=230,"cat frame stays central, both flips")
  check(pts[1].x-23>=40 and pts[1].x+23<=230,"fish stays central")
 var original:=PackedByteArray([71,68,80,67,1]);var p:=FileAccess.open(m.PATCH,FileAccess.WRITE);p.store_buffer(original);p=null
 p=FileAccess.open(m.PATCH+".new",FileAccess.WRITE);p.store_buffer(original);p=null;m.expected_size=original.size();m.expected_hash="0".repeat(64);m._on_patch(0,200,PackedStringArray(),PackedByteArray(),119,"1.19")
 check(FileAccess.get_file_as_bytes(m.PATCH)==original,"hash rejection preserves previous patch")
 m.queue_free();await process_frame
 print("INCREMENTAL_VERIFY failures=",failures," entries=",list.size());quit(0 if failures.is_empty() else 1)
